// Generated from formal/picker-machine.json; do not edit by hand.
package dev.filetunnel.ui

enum class PickerMachineState { Idle, Creating, Pairing, Refreshing, Transferring, Downloading, Cancelling, Complete, FailedWithoutSession, FailedWithSession;
    val metadata: PickerStateMetadata
        get() = when (this) {
        Idle -> PickerStateMetadata(requiresSession = false, inFlight = false)
        Creating -> PickerStateMetadata(requiresSession = false, inFlight = true)
        Pairing -> PickerStateMetadata(requiresSession = true, inFlight = false)
        Refreshing -> PickerStateMetadata(requiresSession = true, inFlight = true)
        Transferring -> PickerStateMetadata(requiresSession = true, inFlight = false)
        Downloading -> PickerStateMetadata(requiresSession = true, inFlight = true)
        Cancelling -> PickerStateMetadata(requiresSession = false, inFlight = true)
        Complete -> PickerStateMetadata(requiresSession = false, inFlight = false)
        FailedWithoutSession -> PickerStateMetadata(requiresSession = false, inFlight = false)
        FailedWithSession -> PickerStateMetadata(requiresSession = true, inFlight = false)
        }

    fun transition(event: PickerMachineEvent): PickerMachineState = when (this to event) {
        Idle to PickerMachineEvent.Start -> Creating
        Creating to PickerMachineEvent.Created -> Pairing
        Creating to PickerMachineEvent.Fail -> FailedWithoutSession
        Pairing to PickerMachineEvent.Refresh -> Refreshing
        Pairing to PickerMachineEvent.Cancel -> Cancelling
        Pairing to PickerMachineEvent.Fail -> FailedWithSession
        Refreshing to PickerMachineEvent.SnapshotEmpty -> Pairing
        Refreshing to PickerMachineEvent.SnapshotFiles -> Transferring
        Refreshing to PickerMachineEvent.AllFilesReceived -> Complete
        Refreshing to PickerMachineEvent.Fail -> FailedWithSession
        Transferring to PickerMachineEvent.Refresh -> Refreshing
        Transferring to PickerMachineEvent.Download -> Downloading
        Transferring to PickerMachineEvent.Cancel -> Cancelling
        Transferring to PickerMachineEvent.Fail -> FailedWithSession
        Downloading to PickerMachineEvent.Downloaded -> Transferring
        Downloading to PickerMachineEvent.Fail -> FailedWithSession
        Cancelling to PickerMachineEvent.Cancelled -> Idle
        Cancelling to PickerMachineEvent.Fail -> FailedWithoutSession
        Complete to PickerMachineEvent.Reset -> Idle
        Complete to PickerMachineEvent.Start -> Creating
        FailedWithoutSession to PickerMachineEvent.Retry -> Creating
        FailedWithoutSession to PickerMachineEvent.Reset -> Idle
        FailedWithSession to PickerMachineEvent.Retry -> Refreshing
        FailedWithSession to PickerMachineEvent.Cancel -> Cancelling
        FailedWithSession to PickerMachineEvent.Reset -> Idle
        else -> throw InvalidPickerTransition(this, event)
    }
}

enum class PickerMachineEvent { Start, Created, Refresh, SnapshotEmpty, SnapshotFiles, AllFilesReceived, Download, Downloaded, Cancel, Cancelled, Fail, Retry, Reset }

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
    PickerMachineTransition(PickerMachineState.Idle, PickerMachineEvent.Start, PickerMachineState.Creating),
    PickerMachineTransition(PickerMachineState.Creating, PickerMachineEvent.Created, PickerMachineState.Pairing),
    PickerMachineTransition(PickerMachineState.Creating, PickerMachineEvent.Fail, PickerMachineState.FailedWithoutSession),
    PickerMachineTransition(PickerMachineState.Pairing, PickerMachineEvent.Refresh, PickerMachineState.Refreshing),
    PickerMachineTransition(PickerMachineState.Pairing, PickerMachineEvent.Cancel, PickerMachineState.Cancelling),
    PickerMachineTransition(PickerMachineState.Pairing, PickerMachineEvent.Fail, PickerMachineState.FailedWithSession),
    PickerMachineTransition(PickerMachineState.Refreshing, PickerMachineEvent.SnapshotEmpty, PickerMachineState.Pairing),
    PickerMachineTransition(PickerMachineState.Refreshing, PickerMachineEvent.SnapshotFiles, PickerMachineState.Transferring),
    PickerMachineTransition(PickerMachineState.Refreshing, PickerMachineEvent.AllFilesReceived, PickerMachineState.Complete),
    PickerMachineTransition(PickerMachineState.Refreshing, PickerMachineEvent.Fail, PickerMachineState.FailedWithSession),
    PickerMachineTransition(PickerMachineState.Transferring, PickerMachineEvent.Refresh, PickerMachineState.Refreshing),
    PickerMachineTransition(PickerMachineState.Transferring, PickerMachineEvent.Download, PickerMachineState.Downloading),
    PickerMachineTransition(PickerMachineState.Transferring, PickerMachineEvent.Cancel, PickerMachineState.Cancelling),
    PickerMachineTransition(PickerMachineState.Transferring, PickerMachineEvent.Fail, PickerMachineState.FailedWithSession),
    PickerMachineTransition(PickerMachineState.Downloading, PickerMachineEvent.Downloaded, PickerMachineState.Transferring),
    PickerMachineTransition(PickerMachineState.Downloading, PickerMachineEvent.Fail, PickerMachineState.FailedWithSession),
    PickerMachineTransition(PickerMachineState.Cancelling, PickerMachineEvent.Cancelled, PickerMachineState.Idle),
    PickerMachineTransition(PickerMachineState.Cancelling, PickerMachineEvent.Fail, PickerMachineState.FailedWithoutSession),
    PickerMachineTransition(PickerMachineState.Complete, PickerMachineEvent.Reset, PickerMachineState.Idle),
    PickerMachineTransition(PickerMachineState.Complete, PickerMachineEvent.Start, PickerMachineState.Creating),
    PickerMachineTransition(PickerMachineState.FailedWithoutSession, PickerMachineEvent.Retry, PickerMachineState.Creating),
    PickerMachineTransition(PickerMachineState.FailedWithoutSession, PickerMachineEvent.Reset, PickerMachineState.Idle),
    PickerMachineTransition(PickerMachineState.FailedWithSession, PickerMachineEvent.Retry, PickerMachineState.Refreshing),
    PickerMachineTransition(PickerMachineState.FailedWithSession, PickerMachineEvent.Cancel, PickerMachineState.Cancelling),
    PickerMachineTransition(PickerMachineState.FailedWithSession, PickerMachineEvent.Reset, PickerMachineState.Idle),
)
