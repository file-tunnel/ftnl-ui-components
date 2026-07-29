import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ftnl_ui/ftnl_ui.dart';

void main() {
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
