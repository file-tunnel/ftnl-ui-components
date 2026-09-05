// Generated from formal/picker-machine.json; do not edit by hand.
// dart format off

enum PickerMachineState { idle, creating, pairing, refreshing, transferring, downloading, cancelling, complete, failedWithoutSession, failedWithSession }

enum PickerMachineEvent { start, created, refresh, snapshotEmpty, snapshotFiles, allFilesReceived, download, downloaded, cancel, cancelled, fail, retry, reset }

final class PickerStateMetadata {
  const PickerStateMetadata({required this.requiresSession, required this.inFlight});

  final bool requiresSession;
  final bool inFlight;
}

final class InvalidPickerTransition implements Exception {
  const InvalidPickerTransition(this.state, this.event);

  final PickerMachineState state;
  final PickerMachineEvent event;

  @override
  String toString() => 'Picker event is not allowed in the current state';
}

extension PickerMachineStateContract on PickerMachineState {
  PickerStateMetadata get metadata => switch (this) {
      PickerMachineState.idle => const PickerStateMetadata(requiresSession: false, inFlight: false),
      PickerMachineState.creating => const PickerStateMetadata(requiresSession: false, inFlight: true),
      PickerMachineState.pairing => const PickerStateMetadata(requiresSession: true, inFlight: false),
      PickerMachineState.refreshing => const PickerStateMetadata(requiresSession: true, inFlight: true),
      PickerMachineState.transferring => const PickerStateMetadata(requiresSession: true, inFlight: false),
      PickerMachineState.downloading => const PickerStateMetadata(requiresSession: true, inFlight: true),
      PickerMachineState.cancelling => const PickerStateMetadata(requiresSession: false, inFlight: true),
      PickerMachineState.complete => const PickerStateMetadata(requiresSession: false, inFlight: false),
      PickerMachineState.failedWithoutSession => const PickerStateMetadata(requiresSession: false, inFlight: false),
      PickerMachineState.failedWithSession => const PickerStateMetadata(requiresSession: true, inFlight: false),
  };

  PickerMachineState transition(PickerMachineEvent event) => switch ((this, event)) {
      (PickerMachineState.idle, PickerMachineEvent.start) => PickerMachineState.creating,
      (PickerMachineState.creating, PickerMachineEvent.created) => PickerMachineState.pairing,
      (PickerMachineState.creating, PickerMachineEvent.fail) => PickerMachineState.failedWithoutSession,
      (PickerMachineState.pairing, PickerMachineEvent.refresh) => PickerMachineState.refreshing,
      (PickerMachineState.pairing, PickerMachineEvent.cancel) => PickerMachineState.cancelling,
      (PickerMachineState.pairing, PickerMachineEvent.fail) => PickerMachineState.failedWithSession,
      (PickerMachineState.refreshing, PickerMachineEvent.snapshotEmpty) => PickerMachineState.pairing,
      (PickerMachineState.refreshing, PickerMachineEvent.snapshotFiles) => PickerMachineState.transferring,
      (PickerMachineState.refreshing, PickerMachineEvent.allFilesReceived) => PickerMachineState.complete,
      (PickerMachineState.refreshing, PickerMachineEvent.fail) => PickerMachineState.failedWithSession,
      (PickerMachineState.transferring, PickerMachineEvent.refresh) => PickerMachineState.refreshing,
      (PickerMachineState.transferring, PickerMachineEvent.download) => PickerMachineState.downloading,
      (PickerMachineState.transferring, PickerMachineEvent.cancel) => PickerMachineState.cancelling,
      (PickerMachineState.transferring, PickerMachineEvent.fail) => PickerMachineState.failedWithSession,
      (PickerMachineState.downloading, PickerMachineEvent.downloaded) => PickerMachineState.transferring,
      (PickerMachineState.downloading, PickerMachineEvent.fail) => PickerMachineState.failedWithSession,
      (PickerMachineState.cancelling, PickerMachineEvent.cancelled) => PickerMachineState.idle,
      (PickerMachineState.cancelling, PickerMachineEvent.fail) => PickerMachineState.failedWithoutSession,
      (PickerMachineState.complete, PickerMachineEvent.reset) => PickerMachineState.idle,
      (PickerMachineState.complete, PickerMachineEvent.start) => PickerMachineState.creating,
      (PickerMachineState.failedWithoutSession, PickerMachineEvent.retry) => PickerMachineState.creating,
      (PickerMachineState.failedWithoutSession, PickerMachineEvent.reset) => PickerMachineState.idle,
      (PickerMachineState.failedWithSession, PickerMachineEvent.retry) => PickerMachineState.refreshing,
      (PickerMachineState.failedWithSession, PickerMachineEvent.cancel) => PickerMachineState.cancelling,
      (PickerMachineState.failedWithSession, PickerMachineEvent.reset) => PickerMachineState.idle,
    _ => throw InvalidPickerTransition(this, event),
  };
}

typedef PickerMachineTransition = ({
  PickerMachineState from,
  PickerMachineEvent event,
  PickerMachineState to,
});

const pickerMachineTransitions = <PickerMachineTransition>[
  (from: PickerMachineState.idle, event: PickerMachineEvent.start, to: PickerMachineState.creating),
  (from: PickerMachineState.creating, event: PickerMachineEvent.created, to: PickerMachineState.pairing),
  (from: PickerMachineState.creating, event: PickerMachineEvent.fail, to: PickerMachineState.failedWithoutSession),
  (from: PickerMachineState.pairing, event: PickerMachineEvent.refresh, to: PickerMachineState.refreshing),
  (from: PickerMachineState.pairing, event: PickerMachineEvent.cancel, to: PickerMachineState.cancelling),
  (from: PickerMachineState.pairing, event: PickerMachineEvent.fail, to: PickerMachineState.failedWithSession),
  (from: PickerMachineState.refreshing, event: PickerMachineEvent.snapshotEmpty, to: PickerMachineState.pairing),
  (from: PickerMachineState.refreshing, event: PickerMachineEvent.snapshotFiles, to: PickerMachineState.transferring),
  (from: PickerMachineState.refreshing, event: PickerMachineEvent.allFilesReceived, to: PickerMachineState.complete),
  (from: PickerMachineState.refreshing, event: PickerMachineEvent.fail, to: PickerMachineState.failedWithSession),
  (from: PickerMachineState.transferring, event: PickerMachineEvent.refresh, to: PickerMachineState.refreshing),
  (from: PickerMachineState.transferring, event: PickerMachineEvent.download, to: PickerMachineState.downloading),
  (from: PickerMachineState.transferring, event: PickerMachineEvent.cancel, to: PickerMachineState.cancelling),
  (from: PickerMachineState.transferring, event: PickerMachineEvent.fail, to: PickerMachineState.failedWithSession),
  (from: PickerMachineState.downloading, event: PickerMachineEvent.downloaded, to: PickerMachineState.transferring),
  (from: PickerMachineState.downloading, event: PickerMachineEvent.fail, to: PickerMachineState.failedWithSession),
  (from: PickerMachineState.cancelling, event: PickerMachineEvent.cancelled, to: PickerMachineState.idle),
  (from: PickerMachineState.cancelling, event: PickerMachineEvent.fail, to: PickerMachineState.failedWithoutSession),
  (from: PickerMachineState.complete, event: PickerMachineEvent.reset, to: PickerMachineState.idle),
  (from: PickerMachineState.complete, event: PickerMachineEvent.start, to: PickerMachineState.creating),
  (from: PickerMachineState.failedWithoutSession, event: PickerMachineEvent.retry, to: PickerMachineState.creating),
  (from: PickerMachineState.failedWithoutSession, event: PickerMachineEvent.reset, to: PickerMachineState.idle),
  (from: PickerMachineState.failedWithSession, event: PickerMachineEvent.retry, to: PickerMachineState.refreshing),
  (from: PickerMachineState.failedWithSession, event: PickerMachineEvent.cancel, to: PickerMachineState.cancelling),
  (from: PickerMachineState.failedWithSession, event: PickerMachineEvent.reset, to: PickerMachineState.idle),
];
// dart format on
