import 'package:bridge_scorekeeper/core/core.dart';
import 'package:bridge_scorekeeper/session/session.dart';
import 'package:bridge_scorekeeper/storage/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../session/helpers.dart';
import 'harness.dart';

List<String> columnTexts(WidgetTester tester, String key) => [
  for (final t in tester.widgetList<Text>(
    find.descendant(of: find.byKey(Key(key)), matching: find.byType(Text)),
  ))
    t.data!,
];

void main() {
  group('Paper view', () {
    testWidgets('points above and below the line', (tester) async {
      var s = newSession();
      s = playDeal(s, '2S', Seat.south, diff: 1);
      await pumpApp(tester, active: s, location: '/sheet');
      expect(columnTexts(tester, 'above-ns'), ['30']);
      expect(columnTexts(tester, 'above-ew'), isEmpty);
      expect(find.text('60'), findsWidgets);
      expect(find.text('Deal 2 of 16'), findsOneWidget);
    });

    testWidgets('game line and games won', (tester) async {
      var s = newSession();
      s = playDeal(s, '4S', Seat.south);
      s = playDeal(s, '1C', Seat.east);
      await pumpApp(tester, active: s, location: '/sheet');
      expect(find.byKey(const Key('game-line-1')), findsOneWidget);
      expect(find.text('Rubber 1 · Games 1 · 0'), findsOneWidget);
    });

    testWidgets('totals and deals left', (tester) async {
      var s = newSession(settings(endRule: const DealCountRule(8)));
      for (var i = 0; i < 3; i++) {
        s = playDeal(s, '1C', Seat.north);
      }
      await pumpApp(tester, active: s, location: '/sheet');
      expect(find.text('Deal 4 of 8'), findsOneWidget);
      expect(find.text('Session total'), findsOneWidget);
    });
  });

  group('Card view', () {
    testWidgets('toggle and remember', (tester) async {
      var s = newSession();
      s = playDeal(s, '2S', Seat.south, diff: 1);
      final h = await pumpApp(tester, active: s, location: '/sheet');
      expect(find.byKey(const Key('paper-sheet')), findsOneWidget);
      await h.tapKey('view-cards');
      expect(find.byKey(const Key('card-sheet')), findsOneWidget);
      expect(textContaining('Alice & Carol: 90'), findsOneWidget);
      expect((await h.display.load()).sheetView, SheetView.cards);
    });

    testWidgets('both views show the same totals', (tester) async {
      var s = newSession();
      s = playDeal(s, '4S', Seat.south);
      final h = await pumpApp(tester, active: s, location: '/sheet');
      final paper = tester.widget<Table>(find.byKey(const Key('totals')));
      await h.tapKey('view-cards');
      final cards = tester.widget<Table>(find.byKey(const Key('totals')));
      String cell(Table t, int r, int c) =>
          ((t.children[r].children[c]) as Text).data!;
      expect(cell(paper, 2, 1), cell(cards, 2, 1));
      expect(cell(cards, 2, 1), '120');
    });
  });

  group('History', () {
    testWidgets('history entry', (tester) async {
      var s = newSession();
      s = playDeal(s, '4S', Seat.north);
      s = playDeal(s, '4HX', Seat.east, diff: -1);
      final h = await pumpApp(tester, active: s, location: '/sheet');
      await h.tapKey('tab-history');
      expect(
        textContaining('Deal 2 · 4♥X by Bob · −1 · Alice & Carol +100'),
        findsOneWidget,
      );
    });

    testWidgets('undo last deal', (tester) async {
      var s = newSession();
      for (var i = 0; i < 5; i++) {
        s = playDeal(s, '1C', Seat.north);
      }
      final h = await pumpApp(tester, active: s, location: '/sheet');
      await h.tapKey('tab-history');
      await h.tapKey('undo-deal');
      await h.tap(find.text('Undo deal'));
      expect(h.session!.records, hasLength(4));
      expect(find.byKey(const Key('history-5')), findsNothing);
    });

    testWidgets('edit, preview, and edit mark', (tester) async {
      var s = newSession();
      s = playDeal(s, '4S', Seat.north);
      s = playDeal(s, '1C', Seat.east);
      s = playDeal(s, '3NX', Seat.south, diff: -1);
      final h = await pumpApp(tester, active: s, location: '/sheet');
      await h.tapKey('tab-history');
      await h.tapKey('history-1');
      expect(find.text('Edit deal 1'), findsOneWidget);
      await h.tapKey('result-−1');
      await h.tapKey('preview-edit');
      expect(find.byKey(const Key('edit-preview')), findsOneWidget);
      expect(textContaining('Alice & Carol now not vulnerable'), findsWidgets);
      expect(find.byKey(const Key('changed-3')), findsOneWidget);
      // Cancel leaves the session unchanged.
      await h.tapKey('cancel-edit');
      expect(h.session!.records[0].result!.tricksTaken, 10);
      await h.tapKey('preview-edit');
      await h.tapKey('save-edit');
      expect(h.session!.records[0].result!.tricksTaken, 9);
      expect(find.byKey(const Key('edit-mark-1')), findsOneWidget);
      await h.tapKey('edit-mark-1');
      expect(textContaining('Original: 4♠ by Alice · Made'), findsOneWidget);
    });

    testWidgets('edit to passed out', (tester) async {
      var s = newSession();
      s = playDeal(s, '2S', Seat.north);
      final h = await pumpApp(tester, active: s, location: '/sheet');
      await h.tapKey('tab-history');
      await h.tapKey('history-1');
      await h.tapKey('edit-passed-out');
      expect(find.byKey(const Key('edit-level-2')), findsNothing);
      await h.tapKey('preview-edit');
      await h.tapKey('save-edit');
      expect(h.session!.records.single.isPassedOut, isTrue);
    });
  });

  group('Final summary', () {
    testWidgets('end session and summary', (tester) async {
      var s = newSession(settings(endRule: const TargetScoreRule(5000)));
      s = playDeal(s, '4S', Seat.north);
      s = playDeal(s, '2C', Seat.east);
      final h = await pumpApp(tester, active: s, location: '/deal');
      await h.tapKey('deal-menu');
      await h.tap(find.text('End session').last);
      await h.tap(find.widgetWithText(FilledButton, 'End session'));
      expect(find.text('Final summary'), findsOneWidget);
      // 120 + 300 for A&C; 40 + 100 for B&D.
      expect(find.text('Alice & Carol win by 280 points'), findsOneWidget);
      expect(find.byKey(const Key('unfinished-northSouth')), findsOneWidget);
      expect(find.byKey(const Key('chart')), findsOneWidget);
      expect(textContaining('Deal 1 · 4♠ by Alice · Made'), findsWidgets);
      expect(
        find.descendant(
          of: find.byKey(const Key('stats')),
          matching: find.text('Alice'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('view-sheet')), findsOneWidget);
      expect(find.byKey(const Key('rematch')), findsOneWidget);
      expect(find.byKey(const Key('home')), findsOneWidget);
    });

    testWidgets('new session with the same players', (tester) async {
      var s = newSession();
      s = playDeal(s, '1C', Seat.north);
      s = run(s, [const EndSession()]);
      final h = await pumpApp(tester, active: s, location: '/summary');
      await h.tapKey('rematch');
      expect(find.text('Step 1 of 3 · Players'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Alice'), findsOneWidget);
      final chip = tester.widget<ChoiceChip>(
        find.byKey(const Key('dealer-east')),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('end by number of deals shows the summary button', (
      tester,
    ) async {
      var s = newSession(settings(endRule: const DealCountRule(1)));
      s = run(s, [
        const AdvanceFromStart(),
        SetContract(contract('2S', Seat.north)),
        const ConfirmContract(),
        const FinishPlay(),
        const SetTricks(8),
        const ScoreDeal(),
      ]);
      final h = await pumpApp(tester, active: s, location: '/deal');
      await h.tapKey('final-summary');
      expect(find.text('Alice & Carol win by 160 points'), findsOneWidget);
    });
  });

  group('Past sessions', () {
    testWidgets('list, open, delete, and damaged data', (tester) async {
      final h = await pumpApp(tester);
      var s = SessionController.start(id: 'old', now: t0, settings: settings());
      s = playDeal(s, '4S', Seat.north);
      await h.sessions.archive(run(s, [const EndSession()]));
      await (h.sessions.store as MemoryKeyValueStore).write(
        StorageKeys.pastSession('bad'),
        'damaged',
      );
      await h.sessions.store.write(StorageKeys.pastIndex, '["bad", "old"]');
      await h.push('/past');
      expect(find.text('Alice & Carol vs Bob & Dave'), findsOneWidget);
      expect(find.text('Cannot be opened'), findsOneWidget);
      expect(textContaining('420 – 0'), findsOneWidget);
      await h.tap(find.text('Alice & Carol vs Bob & Dave'));
      expect(find.text('Alice & Carol win by 420 points'), findsOneWidget);
      await h.tapKey('view-sheet');
      expect(find.byKey(const Key('paper-sheet')), findsOneWidget);
      await h.tapKey('tab-history');
      expect(find.byKey(const Key('undo-deal')), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await h.tapKey('delete-old');
      await h.tap(find.text('Delete'));
      expect(find.text('Alice & Carol vs Bob & Dave'), findsNothing);
      expect(await h.sessions.loadPast('old'), isNull);
    });
  });

  testWidgets('session settings are read-only during a session', (
    tester,
  ) async {
    final h = await pumpApp(tester, active: newSession(), location: '/deal');
    await h.tapKey('deal-menu');
    await h.tap(find.text('Session settings'));
    expect(find.byKey(const Key('session-settings')), findsOneWidget);
    expect(
      find.text('These settings cannot change during a session.'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNothing);
  });

  group('Settings screen', () {
    testWidgets('open from the deal screen keeps the stage', (tester) async {
      final s = run(newSession(), [
        const AdvanceFromStart(),
        SetContract(contract('4S', Seat.south)),
        const ConfirmContract(),
        const FinishPlay(),
        const SetTricks(10),
      ]);
      final h = await pumpApp(tester, active: s, location: '/deal');
      await h.tapKey('deal-menu');
      await h.tap(find.text('Settings').last);
      expect(find.text('Theme'), findsOneWidget);
      await h.tapKey('setting-dark');
      await h.tapKey('setting-large');
      await h.tapKey('setting-four');
      final d = await h.display.load();
      expect(d.themeMode, ThemeModeSetting.dark);
      expect(d.textSize, TextSizeSetting.large);
      expect(d.suitColors, SuitColorsSetting.four);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(h.session!.draft!.stage, DealStage.result);
      expect(find.text('Contract fulfilled'), findsOneWidget);
    });

    testWidgets('four colors change the club color', (tester) async {
      await pumpApp(
        tester,
        display: const DisplayPreferences(suitColors: SuitColorsSetting.four),
        location: '/settings',
      );
      final rich = tester.widget<RichText>(
        find.descendant(
          of: find.byKey(const Key('suit-preview')),
          matching: find.byType(RichText),
        ),
      );
      final spans = <TextSpan>[];
      rich.text.visitChildren((s) {
        if (s is TextSpan && s.text == '♣') spans.add(s);
        return true;
      });
      expect(spans.single.style?.color, isNotNull);
    });

    testWidgets('settings on the home gear', (tester) async {
      final h = await pumpApp(tester);
      await h.tap(find.byTooltip('Settings'));
      expect(find.text('Suit colors'), findsOneWidget);
    });
  });
}
