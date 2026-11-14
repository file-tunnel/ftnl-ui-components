import assert from "node:assert/strict";
import { test } from "node:test";
import { JSDOM } from "jsdom";
import {
  InvalidPickerTransitionError,
  pickerMachineEvents,
  pickerMachineStates,
  pickerMachineTransitions,
  transitionPickerState,
} from "../dist/picker-machine.js";

test("generated machine accepts exactly the formally declared pairs", () => {
  for (const state of pickerMachineStates) {
    for (const event of pickerMachineEvents) {
      const expected = pickerMachineTransitions.find(
        (transition) => transition.from === state && transition.event === event,
      );
      if (expected) {
        assert.equal(transitionPickerState(state, event), expected.to);
      } else {
        assert.throws(
          () => transitionPickerState(state, event),
          InvalidPickerTransitionError,
        );
      }
    }
  }
});

test("custom element offers both source choices", async () => {
  const dom = new JSDOM("<!doctype html>", { url: "https://host.test/" });
  Object.assign(globalThis, {
    window: dom.window,
    document: dom.window.document,
    HTMLElement: dom.window.HTMLElement,
    CustomEvent: dom.window.CustomEvent,
    customElements: dom.window.customElements,
  });
  await import("../dist/ftnl-file-picker.js");
  const picker = document.createElement("ftnl-file-picker");
  document.body.append(picker);
  await new Promise((resolve) => setTimeout(resolve, 0));
  assert.match(picker.shadowRoot.textContent, /Files on this device/);
  assert.match(picker.shadowRoot.textContent, /Files on another device/);
});

test("QR rendering errors do not reveal the capability or remove cancel", async () => {
  const picker = document.createElement("ftnl-file-picker");
  const secret = "a".repeat(64);
  picker.setAttribute("pairing-uri", `https://portal.test/t/id#c=${secret}`);
  picker.setAttribute("state", "pairing");
  document.body.append(picker);
  await new Promise((resolve) => setTimeout(resolve, 0));
  assert.match(picker.shadowRoot.textContent, /Pairing QR code unavailable/);
  assert.match(picker.shadowRoot.textContent, /Cancel/);
  assert.doesNotMatch(picker.shadowRoot.textContent, new RegExp(secret));
  picker.remove();
});

test("late QR rendering cannot replace a completed transfer view", async () => {
  const picker = document.createElement("ftnl-file-picker");
  picker.setAttribute("pairing-uri", `https://portal.test/t/id#c=${"a".repeat(64)}`);
  picker.setAttribute("state", "pairing");
  document.body.append(picker);
  picker.setAttribute("state", "complete");
  await new Promise((resolve) => setTimeout(resolve, 0));
  assert.match(picker.shadowRoot.textContent, /Files received/);
  assert.doesNotMatch(picker.shadowRoot.textContent, /Pairing QR code/);
  picker.remove();
});
