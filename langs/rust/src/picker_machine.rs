// Generated from formal/picker-machine.json; do not edit by hand.

#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub enum PickerMachineState {
    Idle,
    Creating,
    Pairing,
    Refreshing,
    Transferring,
    Downloading,
    Cancelling,
    Complete,
    FailedWithoutSession,
    FailedWithSession,
}

#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub enum PickerMachineEvent {
    Start,
    Created,
    Refresh,
    SnapshotEmpty,
    SnapshotFiles,
    AllFilesReceived,
    Download,
    Downloaded,
    Cancel,
    Cancelled,
    Fail,
    Retry,
    Reset,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct StateMetadata {
    pub requires_session: bool,
    pub in_flight: bool,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct InvalidPickerTransition {
    pub state: PickerMachineState,
    pub event: PickerMachineEvent,
}

impl std::fmt::Display for InvalidPickerTransition {
    fn fmt(&self, formatter: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        formatter.write_str("picker event is not allowed in the current state")
    }
}

impl std::error::Error for InvalidPickerTransition {}

#[rustfmt::skip]
impl PickerMachineState {
    pub const fn metadata(self) -> StateMetadata {
        match self {
            Self::Idle => StateMetadata { requires_session: false, in_flight: false },
            Self::Creating => StateMetadata { requires_session: false, in_flight: true },
            Self::Pairing => StateMetadata { requires_session: true, in_flight: false },
            Self::Refreshing => StateMetadata { requires_session: true, in_flight: true },
            Self::Transferring => StateMetadata { requires_session: true, in_flight: false },
            Self::Downloading => StateMetadata { requires_session: true, in_flight: true },
            Self::Cancelling => StateMetadata { requires_session: false, in_flight: true },
            Self::Complete => StateMetadata { requires_session: false, in_flight: false },
            Self::FailedWithoutSession => StateMetadata { requires_session: false, in_flight: false },
            Self::FailedWithSession => StateMetadata { requires_session: true, in_flight: false },
        }
    }

    pub fn transition(self, event: PickerMachineEvent) -> Result<Self, InvalidPickerTransition> {
        match (self, event) {
            (Self::Idle, PickerMachineEvent::Start) => Ok(Self::Creating),
            (Self::Creating, PickerMachineEvent::Created) => Ok(Self::Pairing),
            (Self::Creating, PickerMachineEvent::Fail) => Ok(Self::FailedWithoutSession),
            (Self::Pairing, PickerMachineEvent::Refresh) => Ok(Self::Refreshing),
            (Self::Pairing, PickerMachineEvent::Cancel) => Ok(Self::Cancelling),
            (Self::Pairing, PickerMachineEvent::Fail) => Ok(Self::FailedWithSession),
            (Self::Refreshing, PickerMachineEvent::SnapshotEmpty) => Ok(Self::Pairing),
            (Self::Refreshing, PickerMachineEvent::SnapshotFiles) => Ok(Self::Transferring),
            (Self::Refreshing, PickerMachineEvent::AllFilesReceived) => Ok(Self::Complete),
            (Self::Refreshing, PickerMachineEvent::Fail) => Ok(Self::FailedWithSession),
            (Self::Transferring, PickerMachineEvent::Refresh) => Ok(Self::Refreshing),
            (Self::Transferring, PickerMachineEvent::Download) => Ok(Self::Downloading),
            (Self::Transferring, PickerMachineEvent::Cancel) => Ok(Self::Cancelling),
            (Self::Transferring, PickerMachineEvent::Fail) => Ok(Self::FailedWithSession),
            (Self::Downloading, PickerMachineEvent::Downloaded) => Ok(Self::Transferring),
            (Self::Downloading, PickerMachineEvent::Fail) => Ok(Self::FailedWithSession),
            (Self::Cancelling, PickerMachineEvent::Cancelled) => Ok(Self::Idle),
            (Self::Cancelling, PickerMachineEvent::Fail) => Ok(Self::FailedWithoutSession),
            (Self::Complete, PickerMachineEvent::Reset) => Ok(Self::Idle),
            (Self::Complete, PickerMachineEvent::Start) => Ok(Self::Creating),
            (Self::FailedWithoutSession, PickerMachineEvent::Retry) => Ok(Self::Creating),
            (Self::FailedWithoutSession, PickerMachineEvent::Reset) => Ok(Self::Idle),
            (Self::FailedWithSession, PickerMachineEvent::Retry) => Ok(Self::Refreshing),
            (Self::FailedWithSession, PickerMachineEvent::Cancel) => Ok(Self::Cancelling),
            (Self::FailedWithSession, PickerMachineEvent::Reset) => Ok(Self::Idle),
            (state, event) => Err(InvalidPickerTransition { state, event }),
        }
    }
}

pub const PICKER_MACHINE_STATES: &[PickerMachineState] = &[
    PickerMachineState::Idle,
    PickerMachineState::Creating,
    PickerMachineState::Pairing,
    PickerMachineState::Refreshing,
    PickerMachineState::Transferring,
    PickerMachineState::Downloading,
    PickerMachineState::Cancelling,
    PickerMachineState::Complete,
    PickerMachineState::FailedWithoutSession,
    PickerMachineState::FailedWithSession,
];

pub const PICKER_MACHINE_EVENTS: &[PickerMachineEvent] = &[
    PickerMachineEvent::Start,
    PickerMachineEvent::Created,
    PickerMachineEvent::Refresh,
    PickerMachineEvent::SnapshotEmpty,
    PickerMachineEvent::SnapshotFiles,
    PickerMachineEvent::AllFilesReceived,
    PickerMachineEvent::Download,
    PickerMachineEvent::Downloaded,
    PickerMachineEvent::Cancel,
    PickerMachineEvent::Cancelled,
    PickerMachineEvent::Fail,
    PickerMachineEvent::Retry,
    PickerMachineEvent::Reset,
];

#[rustfmt::skip]
pub const PICKER_MACHINE_TRANSITIONS: &[(PickerMachineState, PickerMachineEvent, PickerMachineState)] = &[
    (PickerMachineState::Idle, PickerMachineEvent::Start, PickerMachineState::Creating),
    (PickerMachineState::Creating, PickerMachineEvent::Created, PickerMachineState::Pairing),
    (PickerMachineState::Creating, PickerMachineEvent::Fail, PickerMachineState::FailedWithoutSession),
    (PickerMachineState::Pairing, PickerMachineEvent::Refresh, PickerMachineState::Refreshing),
    (PickerMachineState::Pairing, PickerMachineEvent::Cancel, PickerMachineState::Cancelling),
    (PickerMachineState::Pairing, PickerMachineEvent::Fail, PickerMachineState::FailedWithSession),
    (PickerMachineState::Refreshing, PickerMachineEvent::SnapshotEmpty, PickerMachineState::Pairing),
    (PickerMachineState::Refreshing, PickerMachineEvent::SnapshotFiles, PickerMachineState::Transferring),
    (PickerMachineState::Refreshing, PickerMachineEvent::AllFilesReceived, PickerMachineState::Complete),
    (PickerMachineState::Refreshing, PickerMachineEvent::Fail, PickerMachineState::FailedWithSession),
    (PickerMachineState::Transferring, PickerMachineEvent::Refresh, PickerMachineState::Refreshing),
    (PickerMachineState::Transferring, PickerMachineEvent::Download, PickerMachineState::Downloading),
    (PickerMachineState::Transferring, PickerMachineEvent::Cancel, PickerMachineState::Cancelling),
    (PickerMachineState::Transferring, PickerMachineEvent::Fail, PickerMachineState::FailedWithSession),
    (PickerMachineState::Downloading, PickerMachineEvent::Downloaded, PickerMachineState::Transferring),
    (PickerMachineState::Downloading, PickerMachineEvent::Fail, PickerMachineState::FailedWithSession),
    (PickerMachineState::Cancelling, PickerMachineEvent::Cancelled, PickerMachineState::Idle),
    (PickerMachineState::Cancelling, PickerMachineEvent::Fail, PickerMachineState::FailedWithoutSession),
    (PickerMachineState::Complete, PickerMachineEvent::Reset, PickerMachineState::Idle),
    (PickerMachineState::Complete, PickerMachineEvent::Start, PickerMachineState::Creating),
    (PickerMachineState::FailedWithoutSession, PickerMachineEvent::Retry, PickerMachineState::Creating),
    (PickerMachineState::FailedWithoutSession, PickerMachineEvent::Reset, PickerMachineState::Idle),
    (PickerMachineState::FailedWithSession, PickerMachineEvent::Retry, PickerMachineState::Refreshing),
    (PickerMachineState::FailedWithSession, PickerMachineEvent::Cancel, PickerMachineState::Cancelling),
    (PickerMachineState::FailedWithSession, PickerMachineEvent::Reset, PickerMachineState::Idle),
];
