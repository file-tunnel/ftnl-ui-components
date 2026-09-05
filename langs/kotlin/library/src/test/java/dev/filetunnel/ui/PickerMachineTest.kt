package dev.filetunnel.ui

import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

class PickerMachineTest {
    @Test
    fun generatedMachineAcceptsExactlyTheFormallyDeclaredPairs() {
        for (state in PickerMachineState.entries) {
            for (event in PickerMachineEvent.entries) {
                val expected = pickerMachineTransitions.singleOrNull {
                    it.from == state && it.event == event
                }
                if (expected != null) {
                    assertEquals(expected.to, state.transition(event))
                } else {
                    assertThrows(InvalidPickerTransition::class.java) {
                        state.transition(event)
                    }
                }
            }
        }
    }
}
