import 'package:bridge_scorekeeper/core/core.dart';
import 'package:bridge_scorekeeper/scoring/scoring.dart';
import 'package:bridge_scorekeeper/session/session.dart';
import 'package:bridge_scorekeeper/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../session/helpers.dart';
import 'harness.dart';

Future<void> enterNames(Harness h, List<String> names) async {
  for (var i = 0; i < 4; i++) {
    await h.enter('name-${Seat.values[i].name}', names[i]);
  }
}

void main() {
  group('Home', () {
    testWidgets('no active session', (tester) async {
      await pumpApp(tester);
      expect(find.byKey(const Key('continue')), findsNothing);
      expect(find.text('IB Scoring'), findsOneWidget);
      expect(find.text('International Bridge Scoring'), findsOneWidget);
      expect(find.byKey(const Key('new-session')), findsOneWidget);
      expect(find.byKey(const Key('past-sessions')), findsOneWidget);
    });

    testWidgets('continue an active session', (tester) async {
      var s = newSession();
      for (var i = 0; i < 5; i++) {
        s = playDeal(s, '1C', Seat.north);
      }
      final h = await pumpApp(tester, active: s);
      expect(find.text('Continue session'), findsOneWidget);
      await h.tapKey('continue');
      expect(find.text('Deal 6 of 16'), findsOneWidget);
    });

    testWidgets('new session with an active one asks first', (tester) async {
      final h = await pumpApp(tester, active: newSession());
      await h.tapKey('new-session');
      expect(find.text('End the active session?'), findsOneWidget);
      await h.tap(find.text('Cancel'));
      expect(find.byKey(const Key('step-title')), findsNothing);
      await h.tapKey('new-session');
      await h.tap(find.text('End and continue'));
      expect(find.text('Step 1 of 3 · Players'), findsOneWidget);
    });
  });

  group('Setup wizard', () {
    testWidgets('error stops Next', (tester) async {
      final h = await pumpApp(tester, location: '/setup');
      await enterNames(h, ['Alice', 'Bob', '  ', 'Dave']);
      await h.tapKey('next');
      expect(find.text('Enter a name'), findsOneWidget);
      expect(find.text('Step 1 of 3 · Players'), findsOneWidget);
    });

    testWidgets('duplicate name and partnership names', (tester) async {
      final h = await pumpApp(tester, location: '/setup');
      await enterNames(h, ['Alice', 'Bob', 'Carol', 'alice ']);
      expect(find.text('Alice & Carol'), findsOneWidget);
      await h.tapKey('next');
      expect(find.text('Each player needs a different name'), findsOneWidget);
    });

    testWidgets('value errors and Back keeps values', (tester) async {
      final h = await pumpApp(tester, location: '/setup');
      await enterNames(h, ['Alice', 'Bob', 'Carol', 'Dave']);
      await h.tapKey('dealer-east');
      await h.tapKey('next');
      expect(find.text('Step 2 of 3 · Game rules'), findsOneWidget);
      await h.enter('rule-value', '0');
      await h.tapKey('next');
      expect(find.text('Enter a whole number from 1 to 200'), findsOneWidget);
      await h.enter('rule-value', 'x');
      await h.tapKey('next');
      expect(find.text('Enter a whole number'), findsOneWidget);
      await h.enter('rule-value', '8');
      await h.tapKey('next');
      expect(find.text('Step 3 of 3 · Scoring'), findsOneWidget);
      await h.tapKey('back');
      await h.tapKey('back');
      expect(find.text('Step 1 of 3 · Players'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Carol'), findsOneWidget);
    });

    testWidgets('start from the last step with House rules', (tester) async {
      final house = ScoringValues.houseDefaults().withValue(
        ScoringField.smallSlamNotVulnerable,
        400,
      );
      final h = await pumpApp(
        tester,
        location: '/setup',
        house: house,
        lastPreset: ScoringPreset.houseRules,
      );
      await enterNames(h, ['Alice', 'Bob', 'Carol', 'Dave']);
      await h.tapKey('next');
      await h.tapKey('rule-target');
      await h.enter('rule-value', '3000');
      await h.tapKey('bidding');
      await h.tapKey('next');
      // The last preset is selected.
      final radio = tester.widget<RadioGroup<ScoringPreset>>(
        find.byType(RadioGroup<ScoringPreset>),
      );
      expect(radio.groupValue, ScoringPreset.houseRules);
      await h.tapKey('start');
      final s = h.session!;
      expect(s.settings.preset, ScoringPreset.houseRules);
      expect(s.settings.values[ScoringField.smallSlamNotVulnerable], 400);
      expect(s.settings.endRule, const TargetScoreRule(3000));
      expect(s.settings.biddingStep, isTrue);
      expect(find.text('Deal 1 · Target 3000'), findsOneWidget);
      expect(find.text('Start auction'), findsOneWidget);
    });

    testWidgets('default preset on first use is Standard', (tester) async {
      final h = await pumpApp(tester, location: '/setup');
      await enterNames(h, ['Alice', 'Bob', 'Carol', 'Dave']);
      await h.tapKey('next');
      await h.tapKey('next');
      await h.tapKey('start');
      expect(h.session!.settings.values, ScoringValues.standard());
      expect(h.session!.settings.endRule, const DealCountRule(16));
      expect(h.session!.settings.firstDealer, Seat.north);
    });
  });

  group('House rules screen', () {
    testWidgets('groups on open and marks', (tester) async {
      await pumpApp(tester, location: '/setup/house-rules?preset=houseRules');
      ExpansionTile tile(String g) =>
          tester.widget<ExpansionTile>(find.byKey(Key('group-$g')));
      for (final g in ScoringGroup.values) {
        final expanded = g == ScoringGroup.honors || g == ScoringGroup.rubber;
        expect(tile(g.name).initiallyExpanded, expanded, reason: g.name);
      }
      expect(find.byKey(const Key('mark-honorsFourInOneHand')), findsOneWidget);
      expect(find.byKey(const Key('mark-rubberTwoNil')), findsOneWidget);
      expect(find.text('5 values · ●'), findsOneWidget);
    });

    testWidgets('Standard is read-only', (tester) async {
      await pumpApp(tester, location: '/setup/house-rules?preset=standard');
      expect(find.byKey(const Key('save')), findsNothing);
      expect(find.byKey(const Key('restore')), findsNothing);
      for (final g in ScoringGroup.values) {
        await tester.ensureVisible(find.byKey(Key('group-${g.name}')));
        await tester.tap(find.byKey(Key('group-${g.name}')));
        await tester.pumpAndSettle();
      }
      final field = tester.widget<TextField>(
        find.byKey(const Key('field-minorTrick')),
      );
      expect(field.readOnly, isTrue);
    });

    testWidgets('save and value errors', (tester) async {
      final h = await pumpApp(tester);
      await h.push('/setup/house-rules?preset=houseRules');
      await h.enter('field-rubberTwoNil', '-50');
      expect(find.text('0 to 100000'), findsOneWidget);
      var save = tester.widget<TextButton>(find.byKey(const Key('save')));
      expect(save.onPressed, isNull);
      await h.enter('field-rubberTwoNil', '600');
      save = tester.widget<TextButton>(find.byKey(const Key('save')));
      expect(save.onPressed, isNotNull);
      await h.tapKey('save');
      expect(
        (await h.presets.loadHouseRules())[ScoringField.rubberTwoNil],
        600,
      );
      expect(
        h.container.read(houseRulesProvider)[ScoringField.rubberTwoNil],
        600,
      );
    });

    testWidgets('leave without save asks to discard', (tester) async {
      final h = await pumpApp(tester);
      await h.push('/setup/house-rules?preset=houseRules');
      await h.enter('field-rubberTwoNil', '600');
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);
      await h.tap(find.text('Discard'));
      expect(find.byKey(const Key('new-session')), findsOneWidget);
      expect(
        (await h.presets.loadHouseRules())[ScoringField.rubberTwoNil],
        250,
      );
    });

    testWidgets('restore House rules defaults', (tester) async {
      final house = ScoringValues.houseDefaults()
          .withValue(ScoringField.rubberTwoNil, 600)
          .withValue(ScoringField.rubberTwoOne, 400)
          .withValue(ScoringField.honorsEachOther, 20);
      final h = await pumpApp(
        tester,
        house: house,
        location: '/setup/house-rules?preset=houseRules',
      );
      await h.tapKey('restore');
      await h.tap(find.text('Restore'));
      final field = tester.widget<TextField>(
        find.byKey(const Key('field-rubberTwoNil')),
      );
      expect(field.controller!.text, '250');
    });
  });

  group('Help', () {
    test('each field has a help text', () {
      for (final f in ScoringField.values) {
        final help = helpTexts[f];
        expect(help, isNotNull, reason: '$f');
        expect(help!.meaning, isNotEmpty);
        expect(help.example, isNotEmpty);
      }
    });

    testWidgets('open, close, one at a time', (tester) async {
      final h = await pumpApp(
        tester,
        location: '/setup/house-rules?preset=houseRules',
      );
      await h.tapKey('group-undertricks');
      await h.tap(
        find.descendant(
          of: find.byKey(const Key('help-undertrickDoubledNotVulnerableFirst')),
          matching: find.byIcon(Icons.info_outline),
        ),
      );
      expect(find.byKey(const Key('help-overlay')), findsOneWidget);
      expect(textContaining('100 + 200 + 200 = 500'), findsWidgets);
      expect(find.text('Standard: 100'), findsOneWidget);

      // Tap outside closes.
      await tester.tapAt(const Offset(5, 450));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('help-overlay')), findsNothing);

      // One overlay at a time.
      await h.tap(
        find.descendant(
          of: find.byKey(const Key('help-undertrickUndoubledVulnerable')),
          matching: find.byIcon(Icons.info_outline),
        ),
      );
      expect(find.byKey(const Key('help-overlay')), findsOneWidget);
      await h.tapKey('help-close');
      expect(find.byKey(const Key('help-overlay')), findsNothing);
    });
  });

  group('Sample calculator', () {
    test('compare with Standard', () {
      final house = ScoringValues.houseDefaults().withValue(
        ScoringField.undertrickDoubledVulnerableFirst,
        250,
      );
      const deal = SampleDeal(
        level: 4,
        strain: Strain.spades,
        doubling: Doubling.doubled,
        vulnerable: true,
        tricksTaken: 9,
      );
      int defenders(List<ScoreItem> items) => items
          .where((i) => i.side == Side.eastWest)
          .fold(0, (a, i) => a + i.points);
      expect(defenders(scoreSample(deal, house)), 250);
      expect(defenders(scoreSample(deal, ScoringValues.standard())), 200);
      expect(deal.result.fullResult, 'Down 1 (1 undertrick)');
    });

    test('game and rubber bonuses from the inputs', () {
      final values = ScoringValues.standard();
      const deal = SampleDeal(completes: SampleCompletes.rubberTwoNil);
      final items = scoreSample(deal, values);
      expect(
        items
            .where((i) => i.component == ScoreComponent.rubberBonus)
            .single
            .points,
        700,
      );
    });

    testWidgets('calculator table and invalid value', (tester) async {
      final h = await pumpApp(
        tester,
        location: '/setup/house-rules?preset=houseRules',
      );
      await h.tapKey('calculator');
      expect(find.byKey(const Key('calc-table')), findsOneWidget);
      expect(find.text('Contract fulfilled'), findsOneWidget);
      await h.tapKey('group-trickValues');
      await h.enter('field-majorTrick', 'abc');
      expect(find.byKey(const Key('calc-invalid')), findsOneWidget);
    });
  });
}
