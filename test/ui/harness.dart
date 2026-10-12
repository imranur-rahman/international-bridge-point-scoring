import 'dart:async';

import 'package:bridge_scorekeeper/scoring/scoring.dart';
import 'package:bridge_scorekeeper/session/session.dart';
import 'package:bridge_scorekeeper/storage/storage.dart';
import 'package:bridge_scorekeeper/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class Harness {
  Harness(this.tester, this.sessions, this.presets, this.display);

  final WidgetTester tester;
  final InMemorySessionRepository sessions;
  final InMemoryPresetRepository presets;
  final InMemoryDisplayPreferencesRepository display;

  ProviderContainer get container => ProviderScope.containerOf(
    tester.element(find.byType(BridgeScorekeeperApp)),
  );

  SessionState? get session => container.read(sessionProvider);

  /// Opens [location] on top of the current screen.
  Future<void> push(String location) async {
    unawaited(container.read(routerProvider).push(location));
    await tester.pumpAndSettle();
  }

  Future<void> go(String location) async {
    container.read(routerProvider).go(location);
    await tester.pumpAndSettle();
  }

  /// Scrolls [finder] into view and taps it.
  Future<void> tap(Finder finder) async {
    await tester.ensureVisible(finder.first);
    await tester.pumpAndSettle();
    await tester.tap(finder.first);
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(String key) => tap(find.byKey(Key(key)));

  Future<void> enter(String key, String text) async {
    final f = find.byKey(Key(key));
    await tester.ensureVisible(f);
    await tester.enterText(f, text);
    await tester.pumpAndSettle();
  }

  Future<void> send(SessionCommand c) async {
    final error = await container.read(sessionProvider.notifier).send(c);
    expect(error, isNull);
    await tester.pumpAndSettle();
  }
}

Future<Harness> pumpApp(
  WidgetTester tester, {
  SessionState? active,
  ScoringValues? house,
  ScoringPreset lastPreset = ScoringPreset.standard,
  DisplayPreferences display = const DisplayPreferences(),
  Size size = const Size(400, 900),
  String? location,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);

  final sessions = InMemorySessionRepository();
  final presets = InMemoryPresetRepository();
  final displayRepo = InMemoryDisplayPreferencesRepository();
  if (active != null) await sessions.saveActive(active);
  if (house != null) await presets.saveHouseRules(house);
  await presets.saveLastPreset(lastPreset);
  await displayRepo.save(display);
  final bootstrap = await AppBootstrap.load(
    sessions: sessions,
    presets: presets,
    display: displayRepo,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: appOverrides(
        sessions: sessions,
        presets: presets,
        display: displayRepo,
        bootstrap: bootstrap,
      ),
      child: const BridgeScorekeeperApp(),
    ),
  );
  await tester.pumpAndSettle();
  final h = Harness(tester, sessions, presets, displayRepo);
  if (location != null) await h.go(location);
  return h;
}

/// Text that contains [part], also inside rich text. Each [Text] builds
/// one [RichText], so the finder matches [RichText] only.
Finder textContaining(String part) => find.byWidgetPredicate(
  (w) => w is RichText && w.text.toPlainText().contains(part),
);
