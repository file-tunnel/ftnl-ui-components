import assert from "node:assert/strict";
import { test } from "node:test";
import { JSDOM } from "jsdom";

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
