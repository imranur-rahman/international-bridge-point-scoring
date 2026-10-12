import 'package:bridge_scorekeeper/core/core.dart';
import 'package:bridge_scorekeeper/scoring/scoring.dart';
import 'package:bridge_scorekeeper/session/session.dart';
import 'package:bridge_scorekeeper/storage/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../session/helpers.dart';
import 'harness.dart';

const Size phone = Size(360, 780);

SessionState atStage(DealStage stage, {bool bidding = true}) {
  var s = newSession(
    settings(
      bidding: bidding,
      components: const ScoringComponents(),
      preset: ScoringPreset.houseRules,
      values: ScoringValues.houseDefaults(),
    ),
  );
  const honors = Honors(HonorsHolding.fourPlusOne, Side.northSouth);
  if (bidding) {
    // North deals and bids 4♠; three passes follow.
    s = run(s, [
      const AdvanceFromStart(),
      for (final c in ['4S', 'P', 'P', 'P']) RecordCall(Call.fromJson(c)),
      const ConfirmContract(),
      const FinishPlay(),
      const SetTricks(10),
      const SetHonors(honors),
      const ScoreDeal(),
      const NextDeal(),
    ]);
  } else {
    s = playDeal(s, '4S', Seat.north, honors: honors);
  }
  if (stage == DealStage.start) return s;
  s = run(s, [const AdvanceFromStart()]);
  if (bidding) {
    for (final c in ['P', '1H', 'X', 'XX', '2S', 'P', '4S', 'X']) {
      s = run(s, [RecordCall(Call.fromJson(c))]);
    }
    if (stage == DealStage.auction) return s;
    s = run(s, [for (var i = 0; i < 3; i++) const RecordCall(Call.pass)]);
  } else {
    s = run(s, [SetContract(contract('4SX', Seat.west))]);
  }
  if (stage == DealStage.contract) return s;
  s = run(s, [const ConfirmContract()]);
  if (stage == DealStage.play) return s;
  s = run(s, [const FinishPlay(), const SetTricks(8)]);
  if (stage == DealStage.result) return s;
  return run(s, [
    const SetHonors(Honors(HonorsHolding.fiveInOneHand, Side.eastWest)),
    const ScoreDeal(),
  ]);
}

Future<void> expandAll(WidgetTester tester) async {
  for (final g in ScoringGroup.values) {
    final f = find.byKey(Key('group-${g.name}'));
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    final tile = tester.widget<ExpansionTile>(f);
    if (!tile.initiallyExpanded) {
      await tester.tap(f);
      await tester.pumpAndSettle();
    }
  }
}

void main() {
  for (final size in TextSizeSetting.values) {
    final display = DisplayPreferences(textSize: size);
    group('360 px, ${size.label} text', () {
      testWidgets('home and settings', (tester) async {
        final h = await pumpApp(
          tester,
          size: phone,
          display: display,
          active: atStage(DealStage.start),
        );
        await h.push('/settings');
        await h.push('/past');
      });

      testWidgets('setup steps', (tester) async {
        final h = await pumpApp(
          tester,
          size: phone,
          display: display,
          location: '/setup',
        );
        for (var i = 0; i < 4; i++) {
          await h.enter('name-${Seat.values[i].name}', 'Player number $i');
        }
        await h.tapKey('next');
        await h.tapKey('next');
        expect(find.text('Step 3 of 3 · Scoring'), findsOneWidget);
      });

      testWidgets('House rules with all groups and the calculator', (
        tester,
      ) async {
        final h = await pumpApp(
          tester,
          size: phone,
          display: display,
          location: '/setup/house-rules?preset=houseRules',
        );
        await expandAll(tester);
        await h.tapKey('calculator');
        await h.tap(find.byKey(const Key('calc-honors')));
        await h.tap(find.text('5 honors, 4 + 1').last);
      });

      for (final stage in DealStage.values) {
        testWidgets('deal at ${stage.label}', (tester) async {
          await pumpApp(
            tester,
            size: phone,
            display: display,
            active: atStage(stage, bidding: stage != DealStage.contract),
            location: '/deal',
          );
          expect(find.byKey(const Key('current-stage')), findsOneWidget);
        });
      }

      testWidgets('direct contract entry', (tester) async {
        await pumpApp(
          tester,
          size: phone,
          display: display,
          active: atStage(DealStage.contract, bidding: false),
          location: '/deal',
        );
        expect(find.byKey(const Key('declarer-west')), findsOneWidget);
      });

      testWidgets('score sheet, cards, history, and edit', (tester) async {
        final h = await pumpApp(
          tester,
          size: phone,
          display: display,
          active: atStage(DealStage.scored),
          location: '/sheet',
        );
        await h.tapKey('view-cards');
        await h.tapKey('tab-history');
        await h.tapKey('history-2');
        expect(find.text('Edit deal 2'), findsOneWidget);
      });

      testWidgets('final summary', (tester) async {
        final s = run(atStage(DealStage.scored), [const EndSession()]);
        await pumpApp(
          tester,
          size: phone,
          display: display,
          active: s,
          location: '/summary',
        );
        expect(find.byKey(const Key('winner')), findsOneWidget);
      });
    });
  }
}
