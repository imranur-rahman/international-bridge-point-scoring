import 'package:bridge_scorekeeper/scoring/scoring.dart';
import 'package:bridge_scorekeeper/storage/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Opens the help overlay of [field] on the current screen.
Future<void> openHelp(Harness h, ScoringField field) async {
  final tile = find.byKey(Key('group-${field.group.name}'));
  await h.tester.ensureVisible(tile);
  await h.tester.pumpAndSettle();
  if (find.byKey(Key('field-${field.name}')).evaluate().isEmpty) {
    await h.tap(tile);
  }
  await h.tap(
    find.descendant(
      of: find.byKey(Key('help-${field.name}')),
      matching: find.byIcon(Icons.info_outline),
    ),
  );
}

void main() {
  testWidgets('open a demo and step through it', (tester) async {
    final h = await pumpApp(
      tester,
      location: '/setup/house-rules?preset=standard',
    );
    await openHelp(h, ScoringField.rubberTwoOne);
    await h.tapKey('show-demo');
    expect(find.byKey(const Key('help-overlay')), findsNothing);
    expect(find.byKey(const Key('demo')), findsOneWidget);
    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(find.byKey(const Key('demo-done')), findsNothing);
    await h.tapKey('demo-next');
    await h.tapKey('demo-next');
    expect(find.text('Step 3 of 3'), findsOneWidget);
    expect(find.text('Alice & Carol win the rubber.'), findsOneWidget);
    final highlight = find.byKey(const Key('demo-highlight-rubberBonus'));
    expect(highlight, findsOneWidget);
    expect(
      find.descendant(of: highlight, matching: find.text('Rubber bonus: 500')),
      findsOneWidget,
    );
    await h.tapKey('demo-back');
    expect(find.text('Step 2 of 3'), findsOneWidget);
    await h.tapKey('demo-next');
    await h.tapKey('demo-done');
    expect(find.byKey(const Key('demo')), findsNothing);
  });

  testWidgets('the demo uses the values on the screen', (tester) async {
    final h = await pumpApp(
      tester,
      location: '/setup/house-rules?preset=houseRules',
    );
    await h.tap(find.byKey(const Key('group-rubber')));
    // The Rubber group starts expanded with House rules defaults; make sure
    // the field shows.
    if (find.byKey(const Key('field-rubberTwoOne')).evaluate().isEmpty) {
      await h.tap(find.byKey(const Key('group-rubber')));
    }
    await h.enter('field-rubberTwoOne', '400');
    await openHelp(h, ScoringField.rubberTwoOne);
    await h.tapKey('show-demo');
    await h.tapKey('demo-next');
    await h.tapKey('demo-next');
    expect(
      find.descendant(
        of: find.byKey(const Key('demo-highlight-rubberBonus')),
        matching: find.text('Rubber bonus: 400'),
      ),
      findsOneWidget,
    );
    // The demo did not save the value.
    expect((await h.presets.loadHouseRules())[ScoringField.rubberTwoOne], 250);
  });

  testWidgets('a changed game threshold changes the demo outcome', (
    tester,
  ) async {
    final h = await pumpApp(
      tester,
      location: '/setup/house-rules?preset=houseRules',
    );
    await h.tap(find.byKey(const Key('group-game')));
    await h.enter('field-gameThreshold', '150');
    await openHelp(h, ScoringField.gameThreshold);
    await h.tapKey('show-demo');
    await h.tapKey('demo-next');
    expect(find.text('Step 2 of 2'), findsOneWidget);
    expect(find.text('Alice & Carol win a game.'), findsNothing);
    expect(find.text('Nobody vulnerable'), findsOneWidget);
  });

  testWidgets('unfinished rubber demo shows the session end', (tester) async {
    final h = await pumpApp(
      tester,
      location: '/setup/house-rules?preset=standard',
    );
    await openHelp(h, ScoringField.unfinishedOneGame);
    await h.tapKey('show-demo');
    expect(find.byKey(const Key('demo-session-end')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('demo-highlight-unfinishedRubber')),
        matching: find.text('Unfinished rubber bonus: 300'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a value of 0 says that it adds no points', (tester) async {
    final h = await pumpApp(
      tester,
      location: '/setup/house-rules?preset=standard',
    );
    await openHelp(h, ScoringField.gameBonusNotVulnerable);
    await h.tapKey('show-demo');
    expect(find.byKey(const Key('demo-zero')), findsOneWidget);
  });

  testWidgets('a value that is not valid disables the demo', (tester) async {
    final h = await pumpApp(
      tester,
      location: '/setup/house-rules?preset=houseRules',
    );
    await h.tap(find.byKey(const Key('group-trickValues')));
    await h.enter('field-majorTrick', 'abc');
    await openHelp(h, ScoringField.majorTrick);
    final button = tester.widget<ButtonStyleButton>(
      find.byKey(const Key('show-demo')),
    );
    expect(button.onPressed, isNull);
    expect(
      find.text('Correct the values on this screen first.'),
      findsOneWidget,
    );
  });

  for (final size in TextSizeSetting.values) {
    testWidgets('demo at 360 px with ${size.label} text', (tester) async {
      final h = await pumpApp(
        tester,
        size: const Size(360, 780),
        display: DisplayPreferences(textSize: size),
        location: '/setup/house-rules?preset=standard',
      );
      await openHelp(h, ScoringField.undertrickDoubledVulnerableFourthOn);
      await h.tapKey('show-demo');
      await h.tapKey('demo-next');
      expect(find.byKey(const Key('demo-done')), findsOneWidget);
    });
  }
}
