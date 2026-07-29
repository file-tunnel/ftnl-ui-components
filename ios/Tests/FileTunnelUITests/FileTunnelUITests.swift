import Foundation
import Testing
@testable import FileTunnelUI

@Test func progressIsClamped() {
    let high = TunnelFileProgress(id: "a", name: "a.jpg", fractionCompleted: 2)
    let low = TunnelFileProgress(id: "b", name: "b.jpg", fractionCompleted: -1)
    #expect(high.fractionCompleted == 1)
    #expect(low.fractionCompleted == 0)
}
