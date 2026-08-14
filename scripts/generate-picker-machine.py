#!/usr/bin/env python3
"""Generate every picker state-machine implementation from one reviewed model."""

from __future__ import annotations

import argparse
import json
import pathlib
import sys
from collections import deque
from typing import Any


ROOT = pathlib.Path(__file__).resolve().parents[1]
MODEL_PATH = ROOT / "formal/picker-machine.json"
HEADER = "Generated from formal/picker-machine.json; do not edit by hand."


def pascal(name: str) -> str:
    return "".join(part.capitalize() for part in name.split("_"))


def camel(name: str) -> str:
    value = pascal(name)
    return value[:1].lower() + value[1:]


def load_model() -> dict[str, Any]:
    model = json.loads(MODEL_PATH.read_text(encoding="utf-8"))
    if model.get("schema") != "ftnl.picker.machine.v1":
        raise ValueError("unsupported picker machine schema")

    states = model.get("states")
    events = model.get("events")
    transitions = model.get("transitions")
    if not isinstance(states, list) or not states:
        raise ValueError("states must be a non-empty list")
    if not isinstance(events, list) or not events:
        raise ValueError("events must be a non-empty list")
    if not isinstance(transitions, list) or not transitions:
        raise ValueError("transitions must be a non-empty list")

    state_names = [state.get("name") for state in states]
    if any(not isinstance(name, str) or not name for name in state_names):
        raise ValueError("every state requires a non-empty name")
    if len(state_names) != len(set(state_names)):
        raise ValueError("state names must be unique")
    if any(not isinstance(event, str) or not event for event in events):
        raise ValueError("every event requires a non-empty name")
    if len(events) != len(set(events)):
        raise ValueError("event names must be unique")
    if model.get("initialState") not in state_names:
        raise ValueError("initialState must name a declared state")

    for state in states:
        if not isinstance(state.get("requiresSession"), bool):
            raise ValueError(f"state {state['name']} requires boolean requiresSession")
        if not isinstance(state.get("inFlight"), bool):
            raise ValueError(f"state {state['name']} requires boolean inFlight")

    pairs: set[tuple[str, str]] = set()
    adjacency: dict[str, set[str]] = {name: set() for name in state_names}
    for transition in transitions:
        source = transition.get("from")
        event = transition.get("event")
        target = transition.get("to")
        if source not in state_names or target not in state_names or event not in events:
            raise ValueError(f"unknown transition member: {transition!r}")
        pair = (source, event)
        if pair in pairs:
            raise ValueError(f"non-deterministic transition: {pair!r}")
        pairs.add(pair)
        adjacency[source].add(target)

    reachable = {model["initialState"]}
    queue = deque(reachable)
    while queue:
        for target in adjacency[queue.popleft()]:
            if target not in reachable:
                reachable.add(target)
                queue.append(target)
    unreachable = set(state_names) - reachable
    if unreachable:
        raise ValueError(f"unreachable states: {sorted(unreachable)}")

    expected_recovery = {
        ("failed_without_session", "retry", "creating"),
        ("failed_with_session", "retry", "refreshing"),
    }
    actual = {(item["from"], item["event"], item["to"]) for item in transitions}
    if not expected_recovery <= actual:
        raise ValueError("failure recovery semantics must remain deterministic")
    return model


def rust(model: dict[str, Any]) -> str:
    states = model["states"]
    events = model["events"]
    transitions = model["transitions"]
    state_variants = "\n".join(f"    {pascal(item['name'])}," for item in states)
    event_variants = "\n".join(f"    {pascal(item)}," for item in events)
    metadata = "\n".join(
        f"            Self::{pascal(item['name'])} => StateMetadata {{ requires_session: {str(item['requiresSession']).lower()}, in_flight: {str(item['inFlight']).lower()} }},"
        for item in states
    )
    arms = "\n".join(
        f"            (Self::{pascal(item['from'])}, PickerMachineEvent::{pascal(item['event'])}) => Ok(Self::{pascal(item['to'])}),"
        for item in transitions
    )
    rows = "\n".join(
        f"    (PickerMachineState::{pascal(item['from'])}, PickerMachineEvent::{pascal(item['event'])}, PickerMachineState::{pascal(item['to'])}),"
        for item in transitions
    )
    return f'''// {HEADER}

#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub enum PickerMachineState {{
{state_variants}
}}

#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub enum PickerMachineEvent {{
{event_variants}
}}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct StateMetadata {{
    pub requires_session: bool,
    pub in_flight: bool,
}}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct InvalidPickerTransition {{
    pub state: PickerMachineState,
    pub event: PickerMachineEvent,
}}

impl std::fmt::Display for InvalidPickerTransition {{
    fn fmt(&self, formatter: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {{
        formatter.write_str("picker event is not allowed in the current state")
    }}
}}

impl std::error::Error for InvalidPickerTransition {{}}

#[rustfmt::skip]
impl PickerMachineState {{
    pub const fn metadata(self) -> StateMetadata {{
        match self {{
{metadata}
        }}
    }}

    pub fn transition(self, event: PickerMachineEvent) -> Result<Self, InvalidPickerTransition> {{
        match (self, event) {{
{arms}
            (state, event) => Err(InvalidPickerTransition {{ state, event }}),
        }}
    }}
}}

pub const PICKER_MACHINE_STATES: &[PickerMachineState] = &[
{chr(10).join(f'    PickerMachineState::{pascal(item["name"])},' for item in states)}
];

pub const PICKER_MACHINE_EVENTS: &[PickerMachineEvent] = &[
{chr(10).join(f'    PickerMachineEvent::{pascal(item)},' for item in events)}
];

#[rustfmt::skip]
pub const PICKER_MACHINE_TRANSITIONS: &[(PickerMachineState, PickerMachineEvent, PickerMachineState)] = &[
{rows}
];
'''


def dart(model: dict[str, Any]) -> str:
    states = model["states"]
    events = model["events"]
    transitions = model["transitions"]
    metadata = "\n".join(
        f"      PickerMachineState.{camel(item['name'])} => const PickerStateMetadata(requiresSession: {str(item['requiresSession']).lower()}, inFlight: {str(item['inFlight']).lower()}),"
        for item in states
    )
    arms = "\n".join(
        f"      (PickerMachineState.{camel(item['from'])}, PickerMachineEvent.{camel(item['event'])}) => PickerMachineState.{camel(item['to'])},"
        for item in transitions
    )
    rows = "\n".join(
        f"  (from: PickerMachineState.{camel(item['from'])}, event: PickerMachineEvent.{camel(item['event'])}, to: PickerMachineState.{camel(item['to'])}),"
        for item in transitions
    )
    return f'''// {HEADER}
// dart format off

enum PickerMachineState {{ {", ".join(camel(item["name"]) for item in states)} }}

enum PickerMachineEvent {{ {", ".join(camel(item) for item in events)} }}

final class PickerStateMetadata {{
  const PickerStateMetadata({{required this.requiresSession, required this.inFlight}});

  final bool requiresSession;
  final bool inFlight;
}}

final class InvalidPickerTransition implements Exception {{
  const InvalidPickerTransition(this.state, this.event);

  final PickerMachineState state;
  final PickerMachineEvent event;

  @override
  String toString() => 'Picker event is not allowed in the current state';
}}

extension PickerMachineStateContract on PickerMachineState {{
  PickerStateMetadata get metadata => switch (this) {{
{metadata}
  }};

  PickerMachineState transition(PickerMachineEvent event) => switch ((this, event)) {{
{arms}
    _ => throw InvalidPickerTransition(this, event),
  }};
}}

typedef PickerMachineTransition = ({{
  PickerMachineState from,
  PickerMachineEvent event,
  PickerMachineState to,
}});

const pickerMachineTransitions = <PickerMachineTransition>[
{rows}
];
// dart format on
'''


def typescript(model: dict[str, Any]) -> str:
    states = model["states"]
    events = model["events"]
    transitions = model["transitions"]
    rows = "\n".join(
        f'  {{ from: "{item["from"]}", event: "{item["event"]}", to: "{item["to"]}" }},'
        for item in transitions
    )
    metadata = "\n".join(
        f'  {item["name"]}: {{ requiresSession: {str(item["requiresSession"]).lower()}, inFlight: {str(item["inFlight"]).lower()} }},'
        for item in states
    )
    return f'''// {HEADER}

export const pickerMachineStates = {json.dumps([item["name"] for item in states])} as const;
export type PickerMachineState = (typeof pickerMachineStates)[number];

export const pickerMachineEvents = {json.dumps(events)} as const;
export type PickerMachineEvent = (typeof pickerMachineEvents)[number];

export interface PickerStateMetadata {{
  readonly requiresSession: boolean;
  readonly inFlight: boolean;
}}

export const pickerStateMetadata: Readonly<Record<PickerMachineState, PickerStateMetadata>> = {{
{metadata}
}};

export interface PickerMachineTransition {{
  readonly from: PickerMachineState;
  readonly event: PickerMachineEvent;
  readonly to: PickerMachineState;
}}

export const pickerMachineTransitions: readonly PickerMachineTransition[] = [
{rows}
];

export class InvalidPickerTransitionError extends Error {{
  constructor(readonly state: PickerMachineState, readonly event: PickerMachineEvent) {{
    super("Picker event is not allowed in the current state");
    this.name = "InvalidPickerTransitionError";
  }}
}}

export function transitionPickerState(state: PickerMachineState, event: PickerMachineEvent): PickerMachineState {{
  const transition = pickerMachineTransitions.find((item) => item.from === state && item.event === event);
  if (!transition) throw new InvalidPickerTransitionError(state, event);
  return transition.to;
}}
'''


def kotlin(model: dict[str, Any]) -> str:
    states = model["states"]
    events = model["events"]
    transitions = model["transitions"]
    metadata = "\n".join(
        f"        {pascal(item['name'])} -> PickerStateMetadata(requiresSession = {str(item['requiresSession']).lower()}, inFlight = {str(item['inFlight']).lower()})"
        for item in states
    )
    arms = "\n".join(
        f"        {pascal(item['from'])} to PickerMachineEvent.{pascal(item['event'])} -> {pascal(item['to'])}"
        for item in transitions
    )
    rows = "\n".join(
        f"    PickerMachineTransition(PickerMachineState.{pascal(item['from'])}, PickerMachineEvent.{pascal(item['event'])}, PickerMachineState.{pascal(item['to'])}),"
        for item in transitions
    )
    return f'''// {HEADER}
package dev.filetunnel.ui

enum class PickerMachineState {{ {", ".join(pascal(item["name"]) for item in states)};
    val metadata: PickerStateMetadata
        get() = when (this) {{
{metadata}
        }}

    fun transition(event: PickerMachineEvent): PickerMachineState = when (this to event) {{
{arms}
        else -> throw InvalidPickerTransition(this, event)
    }}
}}

enum class PickerMachineEvent {{ {", ".join(pascal(item) for item in events)} }}

data class PickerStateMetadata(val requiresSession: Boolean, val inFlight: Boolean)

class InvalidPickerTransition(
    val state: PickerMachineState,
    val event: PickerMachineEvent,
) : IllegalStateException("Picker event is not allowed in the current state")

data class PickerMachineTransition(
    val from: PickerMachineState,
    val event: PickerMachineEvent,
    val to: PickerMachineState,
)

val pickerMachineTransitions = listOf(
{rows}
)
'''


def swift(model: dict[str, Any]) -> str:
    states = model["states"]
    events = model["events"]
    transitions = model["transitions"]
    metadata = "\n".join(
        f"        case .{camel(item['name'])}: PickerStateMetadata(requiresSession: {str(item['requiresSession']).lower()}, inFlight: {str(item['inFlight']).lower()})"
        for item in states
    )
    arms = "\n".join(
        f"        case (.{camel(item['from'])}, .{camel(item['event'])}): .{camel(item['to'])}"
        for item in transitions
    )
    rows = "\n".join(
        f"    PickerMachineTransition(from: .{camel(item['from'])}, event: .{camel(item['event'])}, to: .{camel(item['to'])}),"
        for item in transitions
    )
    return f'''// {HEADER}
import Foundation

public enum PickerMachineState: String, CaseIterable, Sendable {{
{chr(10).join(f'    case {camel(item["name"])}' for item in states)}

    public var metadata: PickerStateMetadata {{
        switch self {{
{metadata}
        }}
    }}

    public func transitioned(by event: PickerMachineEvent) throws -> PickerMachineState {{
        switch (self, event) {{
{arms}
        default: throw InvalidPickerTransition(state: self, event: event)
        }}
    }}
}}

public enum PickerMachineEvent: String, CaseIterable, Sendable {{
{chr(10).join(f'    case {camel(item)}' for item in events)}
}}

public struct PickerStateMetadata: Sendable, Equatable {{
    public let requiresSession: Bool
    public let inFlight: Bool
}}

public struct InvalidPickerTransition: Error, Sendable, Equatable {{
    public let state: PickerMachineState
    public let event: PickerMachineEvent
}}

public struct PickerMachineTransition: Sendable, Equatable {{
    public let from: PickerMachineState
    public let event: PickerMachineEvent
    public let to: PickerMachineState
}}

public let pickerMachineTransitions: [PickerMachineTransition] = [
{rows}
]
'''


def tla(model: dict[str, Any]) -> str:
    states = model["states"]
    events = model["events"]
    transitions = model["transitions"]
    state_set = "{" + ", ".join(json.dumps(item["name"]) for item in states) + "}"
    event_set = "{" + ", ".join(json.dumps(item) for item in events) + "}"
    session_states = "{" + ", ".join(json.dumps(item["name"]) for item in states if item["requiresSession"]) + "}"
    inflight_states = "{" + ", ".join(json.dumps(item["name"]) for item in states if item["inFlight"]) + "}"
    pairs = "{" + ", ".join(f'<<"{item["from"]}", "{item["event"]}">>' for item in transitions) + "}"
    clauses = []
    by_name = {item["name"]: item for item in states}
    for item in transitions:
        target = by_name[item["to"]]
        clauses.append(
            "    \\/ /\\ state = \"{source}\"\n"
            "       /\\ event = \"{event}\"\n"
            "       /\\ state' = \"{target}\"\n"
            "       /\\ hasSession' = {session}\n"
            "       /\\ inFlight' = {inflight}\n"
            "       /\\ lastEvent' = event\n"
            "       /\\ rejected' = FALSE\n".format(
                source=item["from"],
                event=item["event"],
                target=item["to"],
                session=str(target["requiresSession"]).upper(),
                inflight=str(target["inFlight"]).upper(),
            )
        )
    return f'''---- MODULE PickerStateMachine ----
EXTENDS TLC

States == {state_set}
Events == {event_set}
SessionStates == {session_states}
InFlightStates == {inflight_states}
LegalPairs == {pairs}

VARIABLES state, hasSession, inFlight, lastEvent, rejected
vars == <<state, hasSession, inFlight, lastEvent, rejected>>

Init ==
    /\\ state = "{model['initialState']}"
    /\\ hasSession = FALSE
    /\\ inFlight = FALSE
    /\\ lastEvent = "none"
    /\\ rejected = FALSE

LegalTransition ==
    \\E event \\in Events:
{''.join(clauses)}

RejectedTransition ==
    \\E event \\in Events:
       /\\ <<state, event>> \\notin LegalPairs
       /\\ UNCHANGED <<state, hasSession, inFlight>>
       /\\ lastEvent' = event
       /\\ rejected' = TRUE

Next == LegalTransition \\/ RejectedTransition
Spec == Init /\\ [][Next]_vars

TypeInvariant ==
    /\\ state \\in States
    /\\ hasSession \\in BOOLEAN
    /\\ inFlight \\in BOOLEAN
    /\\ lastEvent \\in Events \\cup {{"none"}}
    /\\ rejected \\in BOOLEAN

SessionAuthorityInvariant == hasSession = (state \\in SessionStates)
SingleInFlightInvariant == inFlight = (state \\in InFlightStates)
TerminalInvariant == state = "complete" => ~hasSession /\\ ~inFlight
RejectedEventsStutter == rejected => <<state, lastEvent>> \\notin LegalPairs

====
'''


def outputs(model: dict[str, Any]) -> dict[pathlib.Path, str]:
    return {
        ROOT / "rust/src/picker_machine.rs": rust(model),
        ROOT / "dart/lib/src/picker_machine.g.dart": dart(model),
        ROOT / "web/src/picker-machine.ts": typescript(model),
        ROOT / "android/library/src/main/java/dev/filetunnel/ui/PickerMachine.kt": kotlin(model),
        ROOT / "ios/Sources/FileTunnelUI/PickerMachine.swift": swift(model),
        ROOT / "formal/PickerStateMachine.tla": tla(model),
        ROOT / "formal/PickerStateMachine.cfg": "SPECIFICATION Spec\nINVARIANT TypeInvariant\nINVARIANT SessionAuthorityInvariant\nINVARIANT SingleInFlightInvariant\nINVARIANT TerminalInvariant\nINVARIANT RejectedEventsStutter\n",
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    try:
        generated = outputs(load_model())
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"picker-machine: {error}", file=sys.stderr)
        return 1

    stale: list[str] = []
    for path, content in generated.items():
        if args.check:
            if not path.exists() or path.read_text(encoding="utf-8") != content:
                stale.append(str(path.relative_to(ROOT)))
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8")

    if stale:
        print("picker-machine: generated files are stale: " + ", ".join(stale), file=sys.stderr)
        return 1
    print(f"picker-machine: {'verified' if args.check else 'generated'} {len(generated)} files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
