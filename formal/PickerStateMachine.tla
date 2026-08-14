---- MODULE PickerStateMachine ----
EXTENDS TLC

States == {"idle", "creating", "pairing", "refreshing", "transferring", "downloading", "cancelling", "complete", "failed_without_session", "failed_with_session"}
Events == {"start", "created", "refresh", "snapshot_empty", "snapshot_files", "all_files_received", "download", "downloaded", "cancel", "cancelled", "fail", "retry", "reset"}
SessionStates == {"pairing", "refreshing", "transferring", "downloading", "failed_with_session"}
InFlightStates == {"creating", "refreshing", "downloading", "cancelling"}
LegalPairs == {<<"idle", "start">>, <<"creating", "created">>, <<"creating", "fail">>, <<"pairing", "refresh">>, <<"pairing", "cancel">>, <<"pairing", "fail">>, <<"refreshing", "snapshot_empty">>, <<"refreshing", "snapshot_files">>, <<"refreshing", "all_files_received">>, <<"refreshing", "fail">>, <<"transferring", "refresh">>, <<"transferring", "download">>, <<"transferring", "cancel">>, <<"transferring", "fail">>, <<"downloading", "downloaded">>, <<"downloading", "fail">>, <<"cancelling", "cancelled">>, <<"cancelling", "fail">>, <<"complete", "reset">>, <<"complete", "start">>, <<"failed_without_session", "retry">>, <<"failed_without_session", "reset">>, <<"failed_with_session", "retry">>, <<"failed_with_session", "cancel">>, <<"failed_with_session", "reset">>}

VARIABLES state, hasSession, inFlight, lastEvent, rejected
vars == <<state, hasSession, inFlight, lastEvent, rejected>>

Init ==
    /\ state = "idle"
    /\ hasSession = FALSE
    /\ inFlight = FALSE
    /\ lastEvent = "none"
    /\ rejected = FALSE

LegalTransition ==
    \E event \in Events:
    \/ /\ state = "idle"
       /\ event = "start"
       /\ state' = "creating"
       /\ hasSession' = FALSE
       /\ inFlight' = TRUE
       /\ lastEvent' = event
       /\ rejected' = FALSE
    \/ /\ state = "creating"
       /\ event = "created"
       /\ state' = "pairing"
       /\ hasSession' = TRUE
       /\ inFlight' = FALSE
       /\ lastEvent' = event
       /\ rejected' = FALSE
    \/ /\ state = "creating"
       /\ event = "fail"
       /\ state' = "failed_without_session"
       /\ hasSession' = FALSE
       /\ inFlight' = FALSE
       /\ lastEvent' = event
       /\ rejected' = FALSE
    \/ /\ state = "pairing"
       /\ event = "refresh"
       /\ state' = "refreshing"
       /\ hasSession' = TRUE
       /\ inFlight' = TRUE
       /\ lastEvent' = event
       /\ rejected' = FALSE
    \/ /\ state = "pairing"
       /\ event = "cancel"
       /\ state' = "cancelling"
       /\ hasSession' = FALSE
       /\ inFlight' = TRUE
       /\ lastEvent' = event
       /\ rejected' = FALSE
    \/ /\ state = "pairing"
       /\ event = "fail"
       /\ state' = "failed_with_session"
       /\ hasSession' = TRUE
       /\ inFlight' = FALSE
       /\ lastEvent' = event
       /\ rejected' = FALSE
    \/ /\ state = "refreshing"
       /\ event = "snapshot_empty"
       /\ state' = "pairing"
       /\ hasSession' = TRUE
       /\ inFlight' = FALSE
       /\ lastEvent' = event
       /\ rejected' = FALSE
    \/ /\ state = "refreshing"
       /\ event = "snapshot_files"
       /\ state' = "transferring"
       /\ hasSession' = TRUE
       /\ inFlight' = FALSE
       /\ lastEvent' = event
       /\ rejected' = FALSE
    \/ /\ state = "refreshing"
       /\ event = "all_files_received"
       /\ state' = "complete"
       /\ hasSession' = FALSE
       /\ inFlight' = FALSE
       /\ lastEvent' = event
       /\ rejected' = FALSE
    \/ /\ state = "refreshing"
       /\ event = "fail"
       /\ state' = "failed_with_session"
       /\ hasSession' = TRUE
       /\ inFlight' = FALSE
       /\ lastEvent' = event
       /\ rejected' = FALSE
    \/ /\ state = "transferring"
       /\ event = "refresh"
       /\ state' = "refreshing"
       /\ hasSession' = TRUE
       /\ inFlight' = TRUE
       /\ lastEvent' = event
       /\ rejected' = FALSE
    \/ /\ state = "transferring"
       /\ event = "download"
       /\ state' = "downloading"
       /\ hasSession' = TRUE
       /\ inFlight' = TRUE
       /\ lastEvent' = event
       /\ rejected' = FALSE
    \/ /\ state = "transferring"
       /\ event = "cancel"
       /\ state' = "cancelling"
       /\ hasSession' = FALSE
       /\ inFlight' = TRUE
       /\ lastEvent' = event
       /\ rejected' = FALSE
    \/ /\ state = "transferring"
       /\ event = "fail"
       /\ state' = "failed_with_session"
       /\ hasSession' = TRUE
       /\ inFlight' = FALSE
       /\ lastEvent' = event
       /\ rejected' = FALSE
    \/ /\ state = "downloading"
       /\ event = "downloaded"
       /\ state' = "transferring"
       /\ hasSession' = TRUE
       /\ inFlight' = FALSE
       /\ lastEvent' = event
       /\ rejected' = FALSE
    \/ /\ state = "downloading"
       /\ event = "fail"
       /\ state' = "failed_with_session"
       /\ hasSession' = TRUE
       /\ inFlight' = FALSE
       /\ lastEvent' = event
       /\ rejected' = FALSE
    \/ /\ state = "cancelling"
       /\ event = "cancelled"
       /\ state' = "idle"
       /\ hasSession' = FALSE
       /\ inFlight' = FALSE
       /\ lastEvent' = event
       /\ rejected' = FALSE
    \/ /\ state = "cancelling"
       /\ event = "fail"
       /\ state' = "failed_without_session"
       /\ hasSession' = FALSE
       /\ inFlight' = FALSE
       /\ lastEvent' = event
       /\ rejected' = FALSE
    \/ /\ state = "complete"
       /\ event = "reset"
       /\ state' = "idle"
       /\ hasSession' = FALSE
       /\ inFlight' = FALSE
       /\ lastEvent' = event
       /\ rejected' = FALSE
    \/ /\ state = "complete"
       /\ event = "start"
       /\ state' = "creating"
       /\ hasSession' = FALSE
       /\ inFlight' = TRUE
       /\ lastEvent' = event
       /\ rejected' = FALSE
    \/ /\ state = "failed_without_session"
       /\ event = "retry"
       /\ state' = "creating"
       /\ hasSession' = FALSE
       /\ inFlight' = TRUE
       /\ lastEvent' = event
       /\ rejected' = FALSE
    \/ /\ state = "failed_without_session"
       /\ event = "reset"
       /\ state' = "idle"
       /\ hasSession' = FALSE
       /\ inFlight' = FALSE
       /\ lastEvent' = event
       /\ rejected' = FALSE
    \/ /\ state = "failed_with_session"
       /\ event = "retry"
       /\ state' = "refreshing"
       /\ hasSession' = TRUE
       /\ inFlight' = TRUE
       /\ lastEvent' = event
       /\ rejected' = FALSE
    \/ /\ state = "failed_with_session"
       /\ event = "cancel"
       /\ state' = "cancelling"
       /\ hasSession' = FALSE
       /\ inFlight' = TRUE
       /\ lastEvent' = event
       /\ rejected' = FALSE
    \/ /\ state = "failed_with_session"
       /\ event = "reset"
       /\ state' = "idle"
       /\ hasSession' = FALSE
       /\ inFlight' = FALSE
       /\ lastEvent' = event
       /\ rejected' = FALSE


RejectedTransition ==
    \E event \in Events:
       /\ <<state, event>> \notin LegalPairs
       /\ UNCHANGED <<state, hasSession, inFlight>>
       /\ lastEvent' = event
       /\ rejected' = TRUE

Next == LegalTransition \/ RejectedTransition
Spec == Init /\ [][Next]_vars

TypeInvariant ==
    /\ state \in States
    /\ hasSession \in BOOLEAN
    /\ inFlight \in BOOLEAN
    /\ lastEvent \in Events \cup {"none"}
    /\ rejected \in BOOLEAN

SessionAuthorityInvariant == hasSession = (state \in SessionStates)
SingleInFlightInvariant == inFlight = (state \in InFlightStates)
TerminalInvariant == state = "complete" => ~hasSession /\ ~inFlight
RejectedEventsStutter == rejected => <<state, lastEvent>> \notin LegalPairs

====
