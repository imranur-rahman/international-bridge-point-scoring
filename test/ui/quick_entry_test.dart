import 'package:bridge_scorekeeper/core/core.dart';
import 'package:bridge_scorekeeper/scoring/scoring.dart';
import 'package:bridge_scorekeeper/session/session.dart';
import 'package:bridge_scorekeeper/storage/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../session/helpers.dart';
import 'harness.dart';

SessionSettings quickSettings({bool honors = true}) => SessionSettings(
  players: players,
  firstDealer: Seat.north,
  endRule: const DealCountRule(16),
  biddingStep: false,
  components: ScoringComponents(honors: honors),
  preset: ScoringPreset.standard,
  values: ScoringValues.standard(),
  quickEntry: true,
);

Future<void> toGameRules(Harness h) async {
  for (var i = 0; i < 4; i++) {
    await h.enter(
      'name-${Seat.values[i].name}',
      ['Alice', 'Bob', 'Carol', 'Dave'][i],
    );
  }
  await h.tapKey('next');
}

void main() {
  group('Quick entry option', () {
    testWidgets('turn on quick entry', (tester) async {
      final h = await pumpApp(tester, location: '/setup');
      await toGameRules(h);
      await h.tapKey('quick-entry');
      await h.tapKey('next');
      await h.tapKey('start');
      expect(h.session!.settings.quickEntry, isTrue);
      expect(h.session!.draft!.stage, DealStage.entry);
      expect(find.text('Entry'), findsOneWidget);
      expect(find.text('Play'), findsNothing);
    });

    testWidgets('the bidding step turns quick entry off', (tester) async {
      final h = await pumpApp(tester, location: '/setup');
      await toGameRules(h);
      await h.tapKey('quick-entry');
      await h.tapKey('bidding');
      final quick = tester.widget<SwitchListTile>(
        find.byKey(const Key('quick-entry')),
      );
      expect(quick.value, isFalse);
      expect(quick.onChanged, isNull);
      expect(find.text('Only without the bidding step'), findsOneWidget);
    });

    testWidgets('read-only session settings show quick entry', (tester) async {
      final h = await pumpApp(
        tester,
        active: newSession(quickSettings()),
        location: '/deal',
      );
      await h.tapKey('deal-menu');
      await h.tap(find.text('Session settings'));
      expect(find.text('Quick entry: On'), findsOneWidget);
    });
  });

  group('Quick-entry screen', () {
    testWidgets('score a deal in one screen', (tester) async {
      final h = await pumpApp(
        tester,
        active: newSession(quickSettings()),
        location: '/deal',
      );
      expect(find.text('Dealer: Alice (North)'), findsOneWidget);
      await h.tapKey('quick-level-4');
      await h.tapKey('quick-strain-spades');
      await h.tapKey('quick-doubling-none');
      await h.tapKey('quick-declarer-south');
      // Roles show once the declarer is selected.
      expect(
        tester.widget<Text>(find.byKey(const Key('quick-dummy'))).data,
        'Alice (North)',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('quick-lead'))).data,
        'Dave (West)',
      );
      await h.tapKey('result-Made');
      var score = tester.widget<FilledButton>(
        find.byKey(const Key('quick-score')),
      );
      expect(score.onPressed, isNull); // Honors are still missing.
      await h.tapKey('honors-side-northSouth');
      await h.tapKey('holding-threeHonors');
      score = tester.widget<FilledButton>(find.byKey(const Key('quick-score')));
      expect(score.onPressed, isNotNull);
      await h.tapKey('quick-score');
      final record = h.session!.records.single;
      expect(
        describeResult(record.result, players.nameOf),
        '4♠ by Carol · Made',
      );
      expect(h.session!.draft!.stage, DealStage.scored);
      expect(find.byKey(const Key('breakdown')), findsOneWidget);
      await h.tapKey('next-deal');
      expect(h.session!.draft!.stage, DealStage.entry);
    });

    testWidgets('incomplete entry and level change', (tester) async {
      final h = await pumpApp(
        tester,
        active: newSession(quickSettings(honors: false)),
        location: '/deal',
      );
      await h.tapKey('quick-level-2');
      await h.tapKey('quick-strain-spades');
      await h.tapKey('quick-declarer-south');
      var score = tester.widget<FilledButton>(
        find.byKey(const Key('quick-score')),
      );
      expect(score.onPressed, isNull);
      await h.tapKey('result-+1');
      expect(find.text('Contract fulfilled with 1 overtrick'), findsOneWidget);
      score = tester.widget<FilledButton>(find.byKey(const Key('quick-score')));
      expect(score.onPressed, isNotNull);
      // A change of the level clears the result.
      await h.tapKey('quick-level-4');
      expect(find.text('Select the result'), findsOneWidget);
      score = tester.widget<FilledButton>(find.byKey(const Key('quick-score')));
      expect(score.onPressed, isNull);
    });

    testWidgets('a suit to no trump change clears the honors', (tester) async {
      final h = await pumpApp(
        tester,
        active: newSession(quickSettings()),
        location: '/deal',
      );
      await h.tapKey('quick-level-3');
      await h.tapKey('quick-strain-hearts');
      await h.tapKey('quick-declarer-south');
      await h.tapKey('result-Made');
      await h.tapKey('honors-side-northSouth');
      await h.tapKey('holding-threeHonors');
      await h.tapKey('quick-strain-noTrump');
      expect(find.byKey(const Key('holding-threeAces')), findsOneWidget);
      final score = tester.widget<FilledButton>(
        find.byKey(const Key('quick-score')),
      );
      expect(score.onPressed, isNull);
    });

    testWidgets('passed out', (tester) async {
      final h = await pumpApp(
        tester,
        active: newSession(quickSettings()),
        location: '/deal',
      );
      await h.tapKey('quick-pass-out');
      await h.tap(find.text('Passed out').last);
      expect(h.session!.records.single.isPassedOut, isTrue);
      expect(find.text('Dealer: Bob (East)'), findsOneWidget);
    });
  });

  for (final size in TextSizeSetting.values) {
    testWidgets('quick entry at 360 px with ${size.label} text', (
      tester,
    ) async {
      final h = await pumpApp(
        tester,
        size: const Size(360, 780),
        display: DisplayPreferences(textSize: size),
        active: newSession(quickSettings()),
        location: '/deal',
      );
      await h.tapKey('quick-level-4');
      await h.tapKey('quick-strain-spades');
      await h.tapKey('quick-declarer-west');
      await h.tapKey('result-−1');
      await h.tapKey('honors-side-eastWest');
      expect(find.byKey(const Key('quick-score')), findsOneWidget);
    });
  }
}
