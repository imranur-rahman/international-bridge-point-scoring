import 'package:bridge_scorekeeper/core/core.dart';
import 'package:bridge_scorekeeper/scoring/scoring.dart';
import 'package:bridge_scorekeeper/session/session.dart';
import 'package:bridge_scorekeeper/storage/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../session/helpers.dart';
import 'harness.dart';

String stripText(WidgetTester tester, String side, String part) => tester
    .widget<Text>(
      find.descendant(
        of: find.byKey(Key('strip-$side')),
        matching: find.byKey(Key('strip-$part')),
      ),
    )
    .data!;

void main() {
  testWidgets('strip after a part-score', (tester) async {
    final s = playDeal(newSession(), '2S', Seat.south);
    await pumpApp(tester, active: s, location: '/deal');
    expect(stripText(tester, 'northSouth', 'total'), '60');
    expect(stripText(tester, 'northSouth', 'games'), 'G 0');
    expect(stripText(tester, 'northSouth', 'below'), '60 below');
    expect(stripText(tester, 'northSouth', 'needs'), 'needs 40 for game');
    expect(stripText(tester, 'eastWest', 'total'), '0');
    expect(stripText(tester, 'eastWest', 'needs'), 'needs 100 for game');
  });

  testWidgets('strip after a game', (tester) async {
    final s = playDeal(newSession(), '4S', Seat.south);
    await pumpApp(tester, active: s, location: '/deal');
    expect(stripText(tester, 'northSouth', 'games'), 'G 1');
    expect(stripText(tester, 'northSouth', 'needs'), 'needs 100 for game');
    expect(stripText(tester, 'eastWest', 'needs'), 'needs 100 for game');
  });

  testWidgets('strip updates after an undo', (tester) async {
    final s = playDeal(newSession(), '2S', Seat.south);
    final h = await pumpApp(tester, active: s, location: '/deal');
    await h.send(const UndoLastDeal());
    expect(stripText(tester, 'northSouth', 'total'), '0');
  });

  testWidgets('a tap on the strip opens the score sheet', (tester) async {
    final h = await pumpApp(tester, active: newSession(), location: '/deal');
    await h.tapKey('score-strip');
    expect(find.byKey(const Key('paper-sheet')), findsOneWidget);
  });

  testWidgets('no strip in a wide window', (tester) async {
    await pumpApp(
      tester,
      active: newSession(),
      location: '/deal',
      size: const Size(1200, 900),
    );
    expect(find.byKey(const Key('score-strip')), findsNothing);
    expect(find.byKey(const Key('side-sheet')), findsOneWidget);
  });

  SessionSettings quick() => SessionSettings(
    players: Players({
      Seat.north: 'Alexandra',
      Seat.east: 'Bartholomew',
      Seat.south: 'Christopher',
      Seat.west: 'Dorothea',
    }),
    firstDealer: Seat.north,
    endRule: const DealCountRule(16),
    biddingStep: false,
    components: const ScoringComponents(),
    preset: ScoringPreset.standard,
    values: ScoringValues.standard(),
    quickEntry: true,
  );

  for (final size in TextSizeSetting.values) {
    final display = DisplayPreferences(textSize: size);
    const phone = Size(360, 780);

    testWidgets('strip fits 360 px on quick entry, ${size.label} text', (
      tester,
    ) async {
      // Long names make the strip as wide as it can get.
      final s = run(newSession(quick()), [
        RecordQuickDeal(
          DealResult(
            contract: contract('2S', Seat.south).toContract()!,
            tricksTaken: 8,
            honors: const Honors(HonorsHolding.threeHonors, Side.eastWest),
          ),
        ),
        const NextDeal(),
      ]);
      await pumpApp(
        tester,
        active: s,
        location: '/deal',
        size: phone,
        display: display,
      );
      expect(find.byKey(const Key('score-strip')), findsOneWidget);
    });

    testWidgets('strip fits 360 px on the start, ${size.label} text', (
      tester,
    ) async {
      await pumpApp(
        tester,
        active: playDeal(newSession(), '2S', Seat.south),
        location: '/deal',
        size: phone,
        display: display,
      );
      expect(find.byKey(const Key('score-strip')), findsOneWidget);
    });

    testWidgets('strip fits 360 px on the result, ${size.label} text', (
      tester,
    ) async {
      final t = run(newSession(), [
        const AdvanceFromStart(),
        SetContract(contract('4S', Seat.south)),
        const ConfirmContract(),
        const FinishPlay(),
      ]);
      await pumpApp(
        tester,
        active: t,
        location: '/deal',
        size: phone,
        display: display,
      );
      expect(find.byKey(const Key('score-strip')), findsOneWidget);
    });
  }
}
