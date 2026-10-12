import 'package:bridge_scorekeeper/core/core.dart';
import 'package:bridge_scorekeeper/session/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../session/helpers.dart';
import 'harness.dart';

/// Plays one deal through the UI with the bidding step on.
Future<void> playByTaps(
  Harness h,
  List<String> calls,
  String result, {
  bool next = true,
}) async {
  await h.tapKey('advance');
  for (final c in calls) {
    await h.tapKey(
      c.startsWith('P') || c.startsWith('X') ? 'call-$c' : 'bid-$c',
    );
  }
  await h.tapKey('confirm-contract');
  await h.tapKey('finish-play');
  await h.tapKey('result-$result');
  await h.tapKey('score-deal');
  if (next) await h.tapKey('next-deal');
}

void main() {
  testWidgets('a full session of 4 deals with an edit and an undo', (
    tester,
  ) async {
    final h = await pumpApp(tester);

    // Setup through the wizard.
    await h.tapKey('new-session');
    for (final (seat, name) in [
      (Seat.north, 'Alice'),
      (Seat.east, 'Bob'),
      (Seat.south, 'Carol'),
      (Seat.west, 'Dave'),
    ]) {
      await h.enter('name-${seat.name}', name);
    }
    await h.tapKey('next');
    await h.enter('rule-value', '4');
    await h.tapKey('bidding');
    await h.tapKey('honors');
    await h.tapKey('next');
    await h.tapKey('start');
    expect(find.text('Deal 1 of 4'), findsOneWidget);

    // Deal 1, dealer Alice: 4♠ by Alice, made. N-S win a game.
    await playByTaps(h, ['1S', 'P', '4S', 'P', 'P', 'P'], 'Made');
    // Deal 2, dealer Bob: 4♥ by Bob, down 1. N-S +50.
    await playByTaps(h, ['1H', 'P', '4H', 'P', 'P', 'P'], 'Down 1');
    // Deal 3, dealer Carol: 3NT by Carol, +1. N-S win the rubber 2–0.
    await playByTaps(h, ['3N', 'P', 'P', 'P'], '+1');
    expect(h.session!.ledger.rubbers.first.winner, Side.northSouth);
    // Deal 4, dealer Dave: 2♣ by Dave, made. The session ends.
    await playByTaps(h, ['2C', 'P', 'P', 'P'], 'Made', next: false);
    expect(h.session!.isEnded, isTrue);
    expect(find.byKey(const Key('final-summary')), findsOneWidget);

    // Edit deal 2 to "Made": E-W win a game, so the rubber is 2–1.
    await h.tapKey('open-sheet');
    await h.tapKey('tab-history');
    await h.tapKey('history-2');
    await h.tapKey('result-Made');
    await h.tapKey('preview-edit');
    await h.tapKey('save-edit');
    expect(h.session!.records[1].result!.tricksTaken, 10);
    expect(h.session!.records[1].auction, isNotNull);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Undo deal 4: the session reopens at deal 4.
    await h.tapKey('deal-menu');
    await h.tap(find.text('Undo last deal'));
    await h.tap(find.text('Undo deal'));
    expect(h.session!.isEnded, isFalse);
    expect(find.text('Deal 4 of 4'), findsOneWidget);
    expect(find.text('Dealer: Dave (West)'), findsOneWidget);

    // Deal 4 again: 1NT by Dave, made.
    await playByTaps(h, ['1N', 'P', 'P', 'P'], 'Made', next: false);
    expect(h.session!.isEnded, isTrue);
    await h.tapKey('final-summary');

    // Totals by hand:
    // N-S: 120 (deal 1) + 100 + 30 (deal 3) + 500 (rubber 2–1) = 750.
    // E-W: 120 (deal 2) + 40 (deal 4) + 100 (unfinished part-score) = 260.
    final ledger = h.session!.ledger;
    expect(ledger.finalTotalFor(Side.northSouth), 750);
    expect(ledger.finalTotalFor(Side.eastWest), 260);
    expect(find.text('Alice & Carol win by 490 points'), findsOneWidget);
    expect(find.byKey(const Key('unfinished-eastWest')), findsOneWidget);
  });

  group('Reload at each stage', () {
    for (final stage in DealStage.values) {
      testWidgets('reload at ${stage.label}', (tester) async {
        var s = newSession(settings(bidding: true));
        s = run(s, [
          if (stage.index >= DealStage.auction.index) const AdvanceFromStart(),
          if (stage.index >= DealStage.auction.index)
            RecordCall(Call.fromJson('1S')),
          if (stage.index >= DealStage.contract.index)
            for (var i = 0; i < 3; i++) const RecordCall(Call.pass),
          if (stage.index >= DealStage.play.index) const ConfirmContract(),
          if (stage.index >= DealStage.result.index) const FinishPlay(),
          if (stage.index >= DealStage.result.index) const SetTricks(8),
          if (stage.index >= DealStage.scored.index) const ScoreDeal(),
        ]);
        expect(s.draft!.stage, stage);
        // pumpApp saves the state and loads it again, as a reload does.
        final h = await pumpApp(tester, active: s, location: '/deal');
        final loaded = h.session!;
        expect(loaded.draft!.stage, stage);
        expect(loaded.toJson(), s.toJson());
        expect(
          tester.widget<Text>(find.byKey(const Key('current-stage'))).data,
          stage.label,
        );
        if (stage == DealStage.auction) {
          expect(loaded.draft!.auction!.calls, hasLength(1));
        }
        if (stage == DealStage.result) {
          expect(
            find.text('Contract fulfilled with 1 overtrick'),
            findsOneWidget,
          );
        }
      });
    }
  });
}
