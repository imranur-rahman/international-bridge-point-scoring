import 'package:bridge_scorekeeper/auction/auction.dart';
import 'package:bridge_scorekeeper/core/core.dart';
import 'package:bridge_scorekeeper/scoring/scoring.dart';
import 'package:bridge_scorekeeper/session/session.dart';
import 'package:bridge_scorekeeper/storage/storage.dart';
import 'package:bridge_scorekeeper/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../session/helpers.dart';
import 'harness.dart';

void main() {
  group('Providers', () {
    test('each command saves the state', () async {
      final sessions = InMemorySessionRepository();
      final presets = InMemoryPresetRepository();
      final display = InMemoryDisplayPreferencesRepository();
      final container = ProviderContainer(
        overrides: appOverrides(
          sessions: sessions,
          presets: presets,
          display: display,
          bootstrap: AppBootstrap(
            active: null,
            houseRules: ScoringValues.houseDefaults(),
            lastPreset: ScoringPreset.standard,
            display: const DisplayPreferences(),
          ),
        ),
      );
      addTearDown(container.dispose);
      final notifier = container.read(sessionProvider.notifier);
      await notifier.start(settings(preset: ScoringPreset.houseRules));
      expect((await sessions.loadActive())!.records, isEmpty);
      expect(await presets.loadLastPreset(), ScoringPreset.houseRules);

      expect(await notifier.send(const AdvanceFromStart()), isNull);
      expect((await sessions.loadActive())!.draft!.stage, DealStage.contract);
      expect(await notifier.send(const FinishPlay()), isNotNull);

      for (final c in <SessionCommand>[
        SetContract(contract('4S', Seat.south)),
        const ConfirmContract(),
        const FinishPlay(),
        const SetTricks(10),
        const ScoreDeal(),
      ]) {
        expect(await notifier.send(c), isNull);
        final saved = await sessions.loadActive();
        expect(saved!.toJson(), container.read(sessionProvider)!.toJson());
      }
      expect(container.read(ledgerProvider)!.totalFor(Side.northSouth), 120);
    });

    test('a new session archives the active one', () async {
      final sessions = InMemorySessionRepository();
      final container = ProviderContainer(
        overrides: appOverrides(
          sessions: sessions,
          presets: InMemoryPresetRepository(),
          display: InMemoryDisplayPreferencesRepository(),
          bootstrap: AppBootstrap(
            active: null,
            houseRules: ScoringValues.houseDefaults(),
            lastPreset: ScoringPreset.standard,
            display: const DisplayPreferences(),
          ),
        ),
      );
      addTearDown(container.dispose);
      final notifier = container.read(sessionProvider.notifier);
      await notifier.start(settings());
      final first = container.read(sessionProvider)!.id;
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await notifier.start(settings());
      final past = await sessions.listPast();
      expect(past.single.id, first);
      expect(past.single.session!.isEnded, isTrue);
    });
  });

  group('Theme', () {
    testWidgets('Dark selected on a light device', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await pumpApp(
        tester,
        display: const DisplayPreferences(themeMode: ThemeModeSetting.dark),
      );
      final context = tester.element(find.byType(Scaffold).first);
      expect(Theme.of(context).brightness, Brightness.dark);
    });

    testWidgets('System follows a dark device', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await pumpApp(tester);
      final context = tester.element(find.byType(Scaffold).first);
      expect(Theme.of(context).brightness, Brightness.dark);
    });
  });

  test('every suit color has a contrast of at least 4.5:1', () {
    for (final brightness in Brightness.values) {
      final scheme = buildTheme(brightness).colorScheme;
      final backgrounds = [
        scheme.surface,
        scheme.surfaceContainerLow,
        scheme.surfaceContainerHighest,
      ];
      for (final setting in SuitColorsSetting.values) {
        for (final strain in Strain.values) {
          final color =
              strainColor(strain, brightness, setting) ?? scheme.onSurface;
          for (final bg in backgrounds) {
            expect(
              contrastRatio(color, bg),
              greaterThanOrEqualTo(4.5),
              reason: '$strain $setting $brightness on $bg',
            );
          }
        }
      }
    }
  });

  testWidgets('a reload at the auction opens the auction', (tester) async {
    var s = SessionController.start(
      id: 'r',
      now: t0,
      settings: settings(bidding: true),
    );
    s = run(s, [
      const AdvanceFromStart(),
      RecordCall(Call.fromJson('1H')),
      const RecordCall(Call.pass),
      RecordCall(Call.fromJson('2H')),
    ]);
    final h = await pumpApp(tester, active: s);
    await h.tapKey('continue');
    expect(find.byKey(const Key('auction-history')), findsOneWidget);
    expect(h.session!.draft!.auction!.calls, hasLength(3));
    final auction = h.session!.draft!.auction!;
    expect(auction.outcome, isA<InProgress>());
    expect(find.byKey(const Key('turn')), findsOneWidget);
    // A direct reload of /deal also opens the auction.
    final h2 = await pumpApp(tester, active: s, location: '/deal');
    expect(find.byKey(const Key('bidding-box')), findsOneWidget);
    expect(h2.session!.draft!.stage, DealStage.auction);
  });
}
