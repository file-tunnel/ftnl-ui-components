import CoreImage.CIFilterBuiltins
import SwiftUI

public struct TunnelFileProgress: Identifiable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let fractionCompleted: Double
    public let isComplete: Bool

    public init(
        id: String,
        name: String,
        fractionCompleted: Double,
        isComplete: Bool = false
    ) {
        self.id = id
        self.name = name
        self.fractionCompleted = min(max(fractionCompleted, 0), 1)
        self.isComplete = isComplete
    }
}

public enum FileTunnelPickerState: Sendable, Equatable {
    case idle
    case creating
    case pairing(uri: URL, expiresAt: Date)
    case transferring(uri: URL, expiresAt: Date, files: [TunnelFileProgress])
    case complete
    case failed(message: String)
}

public struct FileTunnelPicker: View {
    private let state: FileTunnelPickerState
    private let chooseLocal: @MainActor () -> Void
    private let chooseRemote: @MainActor () -> Void
    private let cancel: @MainActor () -> Void

    public init(
        state: FileTunnelPickerState,
        chooseLocal: @escaping @MainActor () -> Void,
        chooseRemote: @escaping @MainActor () -> Void,
        cancel: @escaping @MainActor () -> Void
    ) {
        self.state = state
        self.chooseLocal = chooseLocal
        self.chooseRemote = chooseRemote
        self.cancel = cancel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Add files")
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)

            switch state {
            case .idle:
                sourceChoices
            case .creating:
                ProgressView("Opening a secure tunnel…")
            case let .pairing(uri, expiresAt):
                pairing(uri: uri, expiresAt: expiresAt, files: [])
            case let .transferring(uri, expiresAt, files):
                pairing(uri: uri, expiresAt: expiresAt, files: files)
            case .complete:
                Label("Files received", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case let .failed(message):
                Text(message)
                    .foregroundStyle(.red)
                    .accessibilityLabel("File Tunnel error: \(message)")
                Button("Try again", action: chooseRemote)
            }
        }
        .padding()
    }

    private var sourceChoices: some View {
        VStack(spacing: 12) {
            Button(action: chooseLocal) {
                choiceLabel(
                    title: "Files on this device",
                    detail: "Browse this computer or device",
                    icon: "folder"
                )
            }
            Button(action: chooseRemote) {
                choiceLabel(
                    title: "Files on another device",
                    detail: "Scan a QR code with your phone",
                    icon: "qrcode"
                )
            }
        }
        .buttonStyle(.plain)
    }

    private func choiceLabel(title: String, detail: String, icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.secondary)
        }
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
        .contentShape(Rectangle())
    }

    private func pairing(
        uri: URL,
        expiresAt: Date,
        files: [TunnelFileProgress]
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Scan with your phone")
                .font(.title2.bold())
            Text("Choose files on the page that opens. This code expires \(expiresAt, style: .relative).")
                .foregroundStyle(.secondary)

            QRCodeView(value: uri.absoluteString)
                .frame(width: 224, height: 224)
                .accessibilityLabel("Pairing QR code")
                .accessibilityHint("Scan with the camera on the device that has your files")

            ForEach(files) { file in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(file.name).lineLimit(1)
                        Spacer()
                        Text(file.isComplete ? "Received" : "\(Int(file.fractionCompleted * 100))%")
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: file.fractionCompleted)
                }
            }

            Button("Cancel", role: .cancel, action: cancel)
        }
    }
}

private struct QRCodeView: View {
    let value: String

    var body: some View {
        if let image = makeImage(value) {
            image
                .resizable()
                .interpolation(.none)
                .antialiased(false)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.qrcode")
                    .font(.largeTitle)
                Text("QR code unavailable")
            }
        }
    }

    private func makeImage(_ value: String) -> Image? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(value.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let context = CIContext()
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return Image(decorative: cgImage, scale: 1)
    }
}
