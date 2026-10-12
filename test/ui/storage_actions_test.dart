import 'package:bridge_scorekeeper/core/core.dart';
import 'package:bridge_scorekeeper/scoring/scoring.dart';
import 'package:bridge_scorekeeper/session/session.dart';
import 'package:bridge_scorekeeper/storage/storage.dart';
import 'package:bridge_scorekeeper/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../session/helpers.dart';
import 'harness.dart';

class FakeAppFiles implements AppFiles {
  FakeAppFiles({this.hasOfflineCopy = true});

  @override
  final bool hasOfflineCopy;
  int refreshes = 0;

  @override
  Future<int> offlineSize() async => 3250586;

  @override
  Future<void> refresh() async => refreshes++;
}

void main() {
  testWidgets('refresh app files keeps the session', (tester) async {
    final files = FakeAppFiles();
    final s = playDeal(newSession(), '4S', Seat.north);
    final h = await pumpApp(
      tester,
      active: s,
      appFiles: files,
      location: '/settings',
    );
    expect(find.text('Offline copy of the app: 3.1 MB'), findsOneWidget);
    await h.tapKey('refresh-app-files');
    await h.tap(find.text('Refresh'));
    expect(files.refreshes, 1);
    expect(h.session, isNotNull);
    expect(await h.sessions.loadActive(), isNotNull);
  });

  testWidgets('delete all data needs the typed word', (tester) async {
    final h = await pumpApp(
      tester,
      appFiles: FakeAppFiles(),
      location: '/settings',
    );
    await h.tapKey('delete-all-data');
    FilledButton button() => tester.widget<FilledButton>(
      find.byKey(const Key('confirm-delete-all')),
    );
    expect(button().onPressed, isNull);
    await h.enter('delete-word', 'del');
    expect(button().onPressed, isNull);
    await h.enter('delete-word', ' Delete ');
    expect(button().onPressed, isNotNull);
  });

  testWidgets('delete all data', (tester) async {
    var s = playDeal(newSession(), '4S', Seat.north);
    final h = await pumpApp(
      tester,
      active: s,
      appFiles: FakeAppFiles(),
      house: ScoringValues.houseDefaults().withValue(
        ScoringField.gameThreshold,
        120,
      ),
      lastPreset: ScoringPreset.houseRules,
      display: const DisplayPreferences(themeMode: ThemeModeSetting.dark),
    );
    s = run(s, [const EndSession()]);
    await h.sessions.archive(s.copyWith());
    await h.push('/settings');
    await h.tapKey('delete-all-data');
    await h.enter('delete-word', 'delete');
    await h.tapKey('confirm-delete-all');
    // The home screen with no session.
    expect(find.byKey(const Key('home-heading')), findsOneWidget);
    expect(find.byKey(const Key('continue')), findsNothing);
    expect(h.session, isNull);
    expect(h.store.data, isEmpty);
    expect(await h.sessions.listPast(), isEmpty);
    expect(h.container.read(houseRulesProvider), ScoringValues.houseDefaults());
    expect(h.container.read(lastPresetProvider), ScoringPreset.standard);
    expect(h.container.read(displayProvider), const DisplayPreferences());
  });

  testWidgets('phone build shows only delete all data', (tester) async {
    await pumpApp(
      tester,
      appFiles: FakeAppFiles(hasOfflineCopy: false),
      location: '/settings',
    );
    expect(find.byKey(const Key('delete-all-data')), findsOneWidget);
    expect(find.byKey(const Key('refresh-app-files')), findsNothing);
    expect(find.byKey(const Key('offline-size')), findsNothing);
  });

  test('byte sizes', () {
    expect(formatBytes(512), '512 B');
    expect(formatBytes(655360), '640 KB');
    expect(formatBytes(3250586), '3.1 MB');
  });
}
