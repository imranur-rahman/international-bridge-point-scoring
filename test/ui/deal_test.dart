import 'package:bridge_scorekeeper/core/core.dart';
import 'package:bridge_scorekeeper/scoring/scoring.dart';
import 'package:bridge_scorekeeper/session/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../session/helpers.dart';
import 'harness.dart';

Future<Harness> atDeal(
  WidgetTester tester,
  SessionState s, {
  Size size = const Size(400, 900),
}) => pumpApp(tester, active: s, location: '/deal', size: size);

String currentStage(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('current-stage'))).data!;

void main() {
  testWidgets('deal start shows the stages, dealer, and vulnerability', (
    tester,
  ) async {
    var s = newSession();
    s = playDeal(s, '4S', Seat.north);
    await atDeal(tester, s);
    expect(currentStage(tester), 'Start');
    for (final name in ['Start', 'Contract', 'Play', 'Result', 'Scored']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('Auction'), findsNothing);
    expect(find.text('Dealer: Bob (East)'), findsOneWidget);
    expect(find.text('Alice & Carol: vulnerable'), findsOneWidget);
    expect(find.text('Bob & Dave: not vulnerable'), findsOneWidget);
  });

  testWidgets('auction to a contract', (tester) async {
    final s = run(newSession(settings(bidding: true, firstDealer: Seat.east)), [
      const AdvanceFromStart(),
    ]);
    final h = await atDeal(tester, s);
    expect(find.text('Auction'), findsOneWidget);
    expect(find.byKey(const Key('dealer-mark')), findsOneWidget);
    expect(find.text('Bob to call'), findsOneWidget);
    await h.tapKey('call-P'); // Bob.
    await h.tapKey('bid-1N'); // Carol.
    // Lower bids are disabled now.
    final oneClub = tester.widget<OutlinedButton>(
      find.byKey(const Key('bid-1C')),
    );
    expect(oneClub.onPressed, isNull);
    final dbl = tester.widget<OutlinedButton>(find.byKey(const Key('call-X')));
    expect(dbl.onPressed, isNotNull);
    await h.tapKey('call-P'); // Dave.
    await h.tapKey('bid-3N'); // Alice.
    await h.tapKey('call-X'); // Bob.
    await h.tapKey('call-P');
    await h.tapKey('call-P');
    await h.tapKey('call-P');
    expect(currentStage(tester), 'Contract');
    expect(find.text('3NT doubled by Carol'), findsOneWidget);
    // Back to the auction and undo.
    await h.tapKey('back');
    expect(currentStage(tester), 'Auction');
    await h.tapKey('undo-call');
    expect(h.session!.draft!.auction!.calls, hasLength(7));
  });

  testWidgets('auction passed out', (tester) async {
    final s = run(newSession(settings(bidding: true)), [
      const AdvanceFromStart(),
    ]);
    final h = await atDeal(tester, s);
    for (var i = 0; i < 4; i++) {
      await h.tapKey('call-P');
    }
    expect(h.session!.records.single.isPassedOut, isTrue);
    expect(find.text('Deal 2 of 16'), findsOneWidget);
    expect(find.text('Dealer: Bob (East)'), findsOneWidget);
  });

  testWidgets('contract entry: complete and incomplete', (tester) async {
    final s = run(newSession(), [const AdvanceFromStart()]);
    final h = await atDeal(tester, s);
    await h.tapKey('level-4');
    await h.tapKey('strain-spades');
    var cont = tester.widget<FilledButton>(
      find.byKey(const Key('confirm-contract')),
    );
    expect(cont.onPressed, isNull);
    await h.tapKey('declarer-south');
    expect(find.text('4♠ by Carol'), findsOneWidget);
    cont = tester.widget<FilledButton>(
      find.byKey(const Key('confirm-contract')),
    );
    expect(cont.onPressed, isNotNull);
    await h.tapKey('confirm-contract');
    expect(currentStage(tester), 'Play');
  });

  for (final (seat, dummy, lead) in [
    (Seat.south, 'Alice (North)', 'Dave (West)'),
    (Seat.west, 'Bob (East)', 'Alice (North)'),
  ]) {
    testWidgets('play roles for a ${seat.label} declarer', (tester) async {
      final s = run(newSession(), [
        const AdvanceFromStart(),
        SetContract(contract('4S', seat)),
        const ConfirmContract(),
      ]);
      await atDeal(tester, s);
      expect(
        tester.widget<Text>(find.byKey(const Key('role-dummy'))).data,
        dummy,
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('role-lead'))).data,
        lead,
      );
    });
  }

  testWidgets('result buttons and honors entry', (tester) async {
    final s = run(
      newSession(
        settings(
          components: const ScoringComponents(),
          preset: ScoringPreset.houseRules,
          values: ScoringValues.houseDefaults(),
        ),
      ),
      [
        const AdvanceFromStart(),
        SetContract(contract('4S', Seat.south)),
        const ConfirmContract(),
        const FinishPlay(),
      ],
    );
    final h = await atDeal(tester, s);
    expect(find.text('Needs 10 tricks'), findsOneWidget);
    // On a phone, "−3" to "+3" show first; the rest scroll sideways.
    for (final label in ['−3', '−1', 'Made', '+3']) {
      expect(
        find.descendant(
          of: find.byKey(const Key('result-main')),
          matching: find.byKey(Key('result-$label')),
        ),
        findsOneWidget,
      );
    }
    expect(find.byKey(const Key('result-+4')), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const Key('result-−10')),
      100,
      scrollable: find.descendant(
        of: find.byKey(const Key('result-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.byKey(const Key('result-−10')), findsOneWidget);
    await h.tapKey('result-Made');
    expect(find.text('Contract fulfilled'), findsOneWidget);
    expect(find.text('4 honors in one hand · 80'), findsOneWidget);
    expect(find.text('5 honors, 4 + 1 · 90'), findsOneWidget);
    // Scoring needs the honors.
    var score = tester.widget<FilledButton>(
      find.byKey(const Key('score-deal')),
    );
    expect(score.onPressed, isNull);
    await h.tapKey('honors-side-eastWest');
    await h.tapKey('holding-fourPlusOne');
    score = tester.widget<FilledButton>(find.byKey(const Key('score-deal')));
    expect(score.onPressed, isNotNull);
    await h.tapKey('score-deal');
    expect(currentStage(tester), 'Scored');
    expect(find.text('Honors: 90'), findsOneWidget);
  });

  testWidgets('result Down 2 in full words', (tester) async {
    final s = run(newSession(), [
      const AdvanceFromStart(),
      SetContract(contract('3N', Seat.south)),
      const ConfirmContract(),
      const FinishPlay(),
    ]);
    final h = await atDeal(tester, s);
    await h.tapKey('result-−2');
    expect(find.text('Down 2 (2 undertricks)'), findsOneWidget);
    expect(h.session!.draft!.tricksTaken, 7);
  });

  testWidgets('no overtrick at the grand slam', (tester) async {
    final s = run(newSession(), [
      const AdvanceFromStart(),
      SetContract(contract('7N', Seat.south)),
      const ConfirmContract(),
      const FinishPlay(),
    ]);
    await atDeal(tester, s);
    expect(find.byKey(const Key('result-+1')), findsNothing);
    expect(find.byKey(const Key('result-Made')), findsOneWidget);
  });

  testWidgets('breakdown for a doubled failed contract', (tester) async {
    var s = newSession();
    s = playDeal(s, '4SX', Seat.south, diff: -2, next: false);
    final h = await atDeal(tester, s);
    expect(find.text('Undertricks (penalty): 300'), findsOneWidget);
    expect(find.text('Bob & Dave · above'), findsOneWidget);
    await h.tapKey('next-deal');
    expect(currentStage(tester), 'Start');
  });

  group('Two panes', () {
    testWidgets('wide window', (tester) async {
      await atDeal(tester, newSession(), size: const Size(1200, 900));
      expect(find.byKey(const Key('side-sheet')), findsOneWidget);
      expect(find.byKey(const Key('open-sheet')), findsNothing);
    });

    testWidgets('phone', (tester) async {
      final h = await atDeal(tester, newSession(), size: const Size(390, 844));
      expect(find.byKey(const Key('side-sheet')), findsNothing);
      // The "Sheet" button is a filled button, so it stands out.
      expect(
        find.ancestor(
          of: find.text('Sheet'),
          matching: find.byWidgetPredicate((w) => w is FilledButton),
        ),
        findsOneWidget,
      );
      await h.tapKey('open-sheet');
      expect(find.byKey(const Key('paper-sheet')), findsOneWidget);
    });

    testWidgets('resize during a deal keeps the result', (tester) async {
      final s = run(newSession(), [
        const AdvanceFromStart(),
        SetContract(contract('4S', Seat.south)),
        const ConfirmContract(),
        const FinishPlay(),
      ]);
      final h = await atDeal(tester, s, size: const Size(1200, 900));
      await h.tapKey('result-Made');
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('open-sheet')), findsOneWidget);
      expect(find.text('Contract fulfilled'), findsOneWidget);
      expect(h.session!.draft!.tricksTaken, 10);
    });
  });

  testWidgets('suit symbols are bigger than the text around them', (
    tester,
  ) async {
    final s = run(newSession(), [
      const AdvanceFromStart(),
      SetContract(contract('4S', Seat.south)),
      const ConfirmContract(),
    ]);
    await atDeal(tester, s);
    final rich = tester.widget<RichText>(
      find.descendant(
        of: find.byKey(const Key('contract-headline')),
        matching: find.byType(RichText),
      ),
    );
    final base = rich.text.style!.fontSize!;
    double? suitSize;
    rich.text.visitChildren((span) {
      if (span is TextSpan && span.text == '♠') suitSize = span.style?.fontSize;
      return true;
    });
    expect(suitSize, closeTo(base * 1.3, 0.01));
  });
}
