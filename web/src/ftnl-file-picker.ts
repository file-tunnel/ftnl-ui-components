import QRCode from "qrcode";

export * from "./picker-machine.js";

export interface FileProgress {
  id: string;
  name: string;
  bytesTransferred: number;
  sizeBytes: number;
  status: "declared" | "uploading" | "available" | "downloaded" | "rejected";
}

const styles = `
  :host { color: #152033; font: 14px/1.4 ui-sans-serif, system-ui, sans-serif; }
  * { box-sizing: border-box; }
  .wrap { display: grid; gap: 12px; max-width: 440px; padding: 20px; border: 1px solid #dbe3ee; border-radius: 18px; }
  h2 { margin: 0 0 4px; font-size: 24px; }
  button { display: flex; justify-content: space-between; padding: 14px 16px; border: 1px solid #bcc9da; border-radius: 12px; background: white; color: inherit; font: inherit; font-weight: 700; cursor: pointer; }
  button:hover, button:focus-visible { border-color: #2458d3; outline: none; }
  canvas { width: 224px; height: 224px; justify-self: center; }
  .muted, .state { color: #5c6b80; }
  .file { display: grid; grid-template-columns: 1fr auto; gap: 5px 12px; }
  progress { grid-column: 1 / -1; width: 100%; accent-color: #2458d3; }
`;

export class FileTunnelPickerElement extends HTMLElement {
  static observedAttributes = ["pairing-uri", "state"];
  #root: ShadowRoot;
  #files: FileProgress[] = [];

  constructor() {
    super();
    this.#root = this.attachShadow({ mode: "open" });
  }

  connectedCallback(): void {
    void this.#render();
  }

  attributeChangedCallback(): void {
    if (this.isConnected) void this.#render();
  }

  setFiles(files: readonly FileProgress[]): void {
    this.#files = [...files];
    if (this.isConnected) void this.#render();
  }

  async #render(): Promise<void> {
    const state = this.getAttribute("state") ?? "idle";
    const pairingUri = this.getAttribute("pairing-uri");
    this.#root.replaceChildren();
    const style = document.createElement("style");
    style.textContent = styles;
    const wrap = document.createElement("section");
    wrap.className = "wrap";
    wrap.setAttribute("aria-label", "Add files");
    const title = document.createElement("h2");
    title.textContent = "Add files";
    wrap.append(title);

    if (state === "idle") {
      wrap.append(
        this.#button("Files on this device", "Browse this device", "ftnl-local-request"),
        this.#button("Files on another device", "Scan with your phone", "ftnl-tunnel-request"),
      );
    } else if ((state === "pairing" || state === "transferring") && pairingUri) {
      const heading = document.createElement("strong");
      heading.textContent = "Scan with your phone";
      const detail = document.createElement("span");
      detail.className = "muted";
      detail.textContent = "Choose files on the secure page that opens.";
      const canvas = document.createElement("canvas");
      canvas.setAttribute("role", "img");
      canvas.setAttribute("aria-label", "Pairing QR code");
      wrap.append(heading, detail, canvas);
      await QRCode.toCanvas(canvas, pairingUri, { width: 224, margin: 1, errorCorrectionLevel: "M" });
      for (const file of this.#files) wrap.append(this.#file(file));
      wrap.append(this.#button("Cancel", "", "ftnl-cancel"));
    } else {
      const message = document.createElement("p");
      message.className = "state";
      message.textContent =
        state === "creating"
          ? "Opening a secure tunnel…"
          : state === "complete"
            ? "Files received"
            : "The tunnel is unavailable.";
      wrap.append(message);
    }
    this.#root.append(style, wrap);
  }

  #button(label: string, detail: string, eventName: string): HTMLButtonElement {
    const button = document.createElement("button");
    const labelNode = document.createElement("span");
    labelNode.textContent = label;
    const detailNode = document.createElement("span");
    detailNode.className = "muted";
    detailNode.textContent = detail;
    button.append(labelNode, detailNode);
    button.addEventListener("click", () => this.dispatchEvent(new CustomEvent(eventName, { bubbles: true, composed: true })));
    return button;
  }

  #file(file: FileProgress): HTMLElement {
    const row = document.createElement("div");
    row.className = "file";
    const name = document.createElement("span");
    name.textContent = file.name;
    const percent = file.sizeBytes === 0 ? 100 : Math.round((file.bytesTransferred / file.sizeBytes) * 100);
    const state = document.createElement("span");
    state.textContent = file.status === "available" ? "Received" : `${Math.max(0, Math.min(100, percent))}%`;
    const progress = document.createElement("progress");
    progress.max = Math.max(1, file.sizeBytes);
    progress.value = Math.min(progress.max, file.bytesTransferred);
    row.append(name, state, progress);
    return row;
  }
}

if (globalThis.customElements && !customElements.get("ftnl-file-picker")) {
  customElements.define("ftnl-file-picker", FileTunnelPickerElement);
}
