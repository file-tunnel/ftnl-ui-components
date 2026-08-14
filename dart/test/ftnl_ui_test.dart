import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ftnl_ui/ftnl_ui.dart';

void main() {
  test('generated machine accepts exactly the formally declared pairs', () {
    for (final state in PickerMachineState.values) {
      for (final event in PickerMachineEvent.values) {
        PickerMachineTransition? expected;
        for (final transition in pickerMachineTransitions) {
          if (transition.from == state && transition.event == event) {
            expected = transition;
            break;
          }
        }
        if (expected case final transition?) {
          expect(state.transition(event), transition.to);
        } else {
          expect(
            () => state.transition(event),
            throwsA(isA<InvalidPickerTransition>()),
          );
        }
      }
    }
  });

  testWidgets('idle picker exposes both source choices', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FileTunnelPicker(
          state: const Idle(),
          chooseLocal: () {},
          chooseRemote: () {},
          cancel: () {},
        ),
      ),
    );
    expect(find.text('Files on this device'), findsOneWidget);
    expect(find.text('Files on another device'), findsOneWidget);
  });
}
