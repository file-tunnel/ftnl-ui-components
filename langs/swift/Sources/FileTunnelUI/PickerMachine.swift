// Generated from formal/picker-machine.json; do not edit by hand.
import Foundation

public enum PickerMachineState: String, CaseIterable, Sendable {
    case idle
    case creating
    case pairing
    case refreshing
    case transferring
    case downloading
    case cancelling
    case complete
    case failedWithoutSession
    case failedWithSession

    public var metadata: PickerStateMetadata {
        switch self {
        case .idle: PickerStateMetadata(requiresSession: false, inFlight: false)
        case .creating: PickerStateMetadata(requiresSession: false, inFlight: true)
        case .pairing: PickerStateMetadata(requiresSession: true, inFlight: false)
        case .refreshing: PickerStateMetadata(requiresSession: true, inFlight: true)
        case .transferring: PickerStateMetadata(requiresSession: true, inFlight: false)
        case .downloading: PickerStateMetadata(requiresSession: true, inFlight: true)
        case .cancelling: PickerStateMetadata(requiresSession: false, inFlight: true)
        case .complete: PickerStateMetadata(requiresSession: false, inFlight: false)
        case .failedWithoutSession: PickerStateMetadata(requiresSession: false, inFlight: false)
        case .failedWithSession: PickerStateMetadata(requiresSession: true, inFlight: false)
        }
    }

    public func transitioned(by event: PickerMachineEvent) throws -> PickerMachineState {
        switch (self, event) {
        case (.idle, .start): .creating
        case (.creating, .created): .pairing
        case (.creating, .fail): .failedWithoutSession
        case (.pairing, .refresh): .refreshing
        case (.pairing, .cancel): .cancelling
        case (.pairing, .fail): .failedWithSession
        case (.refreshing, .snapshotEmpty): .pairing
        case (.refreshing, .snapshotFiles): .transferring
        case (.refreshing, .allFilesReceived): .complete
        case (.refreshing, .fail): .failedWithSession
        case (.transferring, .refresh): .refreshing
        case (.transferring, .download): .downloading
        case (.transferring, .cancel): .cancelling
        case (.transferring, .fail): .failedWithSession
        case (.downloading, .downloaded): .transferring
        case (.downloading, .fail): .failedWithSession
        case (.cancelling, .cancelled): .idle
        case (.cancelling, .fail): .failedWithoutSession
        case (.complete, .reset): .idle
        case (.complete, .start): .creating
        case (.failedWithoutSession, .retry): .creating
        case (.failedWithoutSession, .reset): .idle
        case (.failedWithSession, .retry): .refreshing
        case (.failedWithSession, .cancel): .cancelling
        case (.failedWithSession, .reset): .idle
        default: throw InvalidPickerTransition(state: self, event: event)
        }
    }
}

public enum PickerMachineEvent: String, CaseIterable, Sendable {
    case start
    case created
    case refresh
    case snapshotEmpty
    case snapshotFiles
    case allFilesReceived
    case download
    case downloaded
    case cancel
    case cancelled
    case fail
    case retry
    case reset
}

public struct PickerStateMetadata: Sendable, Equatable {
    public let requiresSession: Bool
    public let inFlight: Bool
}

public struct InvalidPickerTransition: Error, Sendable, Equatable {
    public let state: PickerMachineState
    public let event: PickerMachineEvent
}

public struct PickerMachineTransition: Sendable, Equatable {
    public let from: PickerMachineState
    public let event: PickerMachineEvent
    public let to: PickerMachineState
}

public let pickerMachineTransitions: [PickerMachineTransition] = [
    PickerMachineTransition(from: .idle, event: .start, to: .creating),
    PickerMachineTransition(from: .creating, event: .created, to: .pairing),
    PickerMachineTransition(from: .creating, event: .fail, to: .failedWithoutSession),
    PickerMachineTransition(from: .pairing, event: .refresh, to: .refreshing),
    PickerMachineTransition(from: .pairing, event: .cancel, to: .cancelling),
    PickerMachineTransition(from: .pairing, event: .fail, to: .failedWithSession),
    PickerMachineTransition(from: .refreshing, event: .snapshotEmpty, to: .pairing),
    PickerMachineTransition(from: .refreshing, event: .snapshotFiles, to: .transferring),
    PickerMachineTransition(from: .refreshing, event: .allFilesReceived, to: .complete),
    PickerMachineTransition(from: .refreshing, event: .fail, to: .failedWithSession),
    PickerMachineTransition(from: .transferring, event: .refresh, to: .refreshing),
    PickerMachineTransition(from: .transferring, event: .download, to: .downloading),
    PickerMachineTransition(from: .transferring, event: .cancel, to: .cancelling),
    PickerMachineTransition(from: .transferring, event: .fail, to: .failedWithSession),
    PickerMachineTransition(from: .downloading, event: .downloaded, to: .transferring),
    PickerMachineTransition(from: .downloading, event: .fail, to: .failedWithSession),
    PickerMachineTransition(from: .cancelling, event: .cancelled, to: .idle),
    PickerMachineTransition(from: .cancelling, event: .fail, to: .failedWithoutSession),
    PickerMachineTransition(from: .complete, event: .reset, to: .idle),
    PickerMachineTransition(from: .complete, event: .start, to: .creating),
    PickerMachineTransition(from: .failedWithoutSession, event: .retry, to: .creating),
    PickerMachineTransition(from: .failedWithoutSession, event: .reset, to: .idle),
    PickerMachineTransition(from: .failedWithSession, event: .retry, to: .refreshing),
    PickerMachineTransition(from: .failedWithSession, event: .cancel, to: .cancelling),
    PickerMachineTransition(from: .failedWithSession, event: .reset, to: .idle),
]
