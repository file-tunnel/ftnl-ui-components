// Generated from formal/picker-machine.json; do not edit by hand.

export const pickerMachineStates = ["idle", "creating", "pairing", "refreshing", "transferring", "downloading", "cancelling", "complete", "failed_without_session", "failed_with_session"] as const;
export type PickerMachineState = (typeof pickerMachineStates)[number];

export const pickerMachineEvents = ["start", "created", "refresh", "snapshot_empty", "snapshot_files", "all_files_received", "download", "downloaded", "cancel", "cancelled", "fail", "retry", "reset"] as const;
export type PickerMachineEvent = (typeof pickerMachineEvents)[number];

export interface PickerStateMetadata {
  readonly requiresSession: boolean;
  readonly inFlight: boolean;
}

export const pickerStateMetadata: Readonly<Record<PickerMachineState, PickerStateMetadata>> = {
  idle: { requiresSession: false, inFlight: false },
  creating: { requiresSession: false, inFlight: true },
  pairing: { requiresSession: true, inFlight: false },
  refreshing: { requiresSession: true, inFlight: true },
  transferring: { requiresSession: true, inFlight: false },
  downloading: { requiresSession: true, inFlight: true },
  cancelling: { requiresSession: false, inFlight: true },
  complete: { requiresSession: false, inFlight: false },
  failed_without_session: { requiresSession: false, inFlight: false },
  failed_with_session: { requiresSession: true, inFlight: false },
};

export interface PickerMachineTransition {
  readonly from: PickerMachineState;
  readonly event: PickerMachineEvent;
  readonly to: PickerMachineState;
}

export const pickerMachineTransitions: readonly PickerMachineTransition[] = [
  { from: "idle", event: "start", to: "creating" },
  { from: "creating", event: "created", to: "pairing" },
  { from: "creating", event: "fail", to: "failed_without_session" },
  { from: "pairing", event: "refresh", to: "refreshing" },
  { from: "pairing", event: "cancel", to: "cancelling" },
  { from: "pairing", event: "fail", to: "failed_with_session" },
  { from: "refreshing", event: "snapshot_empty", to: "pairing" },
  { from: "refreshing", event: "snapshot_files", to: "transferring" },
  { from: "refreshing", event: "all_files_received", to: "complete" },
  { from: "refreshing", event: "fail", to: "failed_with_session" },
  { from: "transferring", event: "refresh", to: "refreshing" },
  { from: "transferring", event: "download", to: "downloading" },
  { from: "transferring", event: "cancel", to: "cancelling" },
  { from: "transferring", event: "fail", to: "failed_with_session" },
  { from: "downloading", event: "downloaded", to: "transferring" },
  { from: "downloading", event: "fail", to: "failed_with_session" },
  { from: "cancelling", event: "cancelled", to: "idle" },
  { from: "cancelling", event: "fail", to: "failed_without_session" },
  { from: "complete", event: "reset", to: "idle" },
  { from: "complete", event: "start", to: "creating" },
  { from: "failed_without_session", event: "retry", to: "creating" },
  { from: "failed_without_session", event: "reset", to: "idle" },
  { from: "failed_with_session", event: "retry", to: "refreshing" },
  { from: "failed_with_session", event: "cancel", to: "cancelling" },
  { from: "failed_with_session", event: "reset", to: "idle" },
];

export class InvalidPickerTransitionError extends Error {
  constructor(readonly state: PickerMachineState, readonly event: PickerMachineEvent) {
    super("Picker event is not allowed in the current state");
    this.name = "InvalidPickerTransitionError";
  }
}

export function transitionPickerState(state: PickerMachineState, event: PickerMachineEvent): PickerMachineState {
  const transition = pickerMachineTransitions.find((item) => item.from === state && item.event === event);
  if (!transition) throw new InvalidPickerTransitionError(state, event);
  return transition.to;
}
