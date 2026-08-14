import Foundation
import Testing
@testable import FileTunnelUI

@Test func progressIsClamped() {
    let high = TunnelFileProgress(id: "a", name: "a.jpg", fractionCompleted: 2)
    let low = TunnelFileProgress(id: "b", name: "b.jpg", fractionCompleted: -1)
    #expect(high.fractionCompleted == 1)
    #expect(low.fractionCompleted == 0)
}

@Test func generatedMachineAcceptsExactlyTheFormallyDeclaredPairs() throws {
    for state in PickerMachineState.allCases {
        for event in PickerMachineEvent.allCases {
            let expected = pickerMachineTransitions.first {
                $0.from == state && $0.event == event
            }
            if let expected {
                #expect(try state.transitioned(by: event) == expected.to)
            } else {
                #expect(throws: InvalidPickerTransition.self) {
                    try state.transitioned(by: event)
                }
            }
        }
    }
}
