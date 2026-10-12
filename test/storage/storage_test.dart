import 'dart:convert';

import 'package:bridge_scorekeeper/core/core.dart';
import 'package:bridge_scorekeeper/scoring/scoring.dart';
import 'package:bridge_scorekeeper/session/session.dart';
import 'package:bridge_scorekeeper/storage/storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../session/helpers.dart';

SessionState sampleSession(String id) {
  var s = SessionController.start(id: id, now: t0, settings: settings());
  s = playDeal(s, '4S', Seat.north);
  return s;
}

/// The shared contract for every store implementation.
void contractTests(String name, KeyValueStore Function() makeStore) {
  group('$name contract', () {
    late KeyValueStore store;
    late SessionRepository sessions;
    late PresetRepository presets;
    late DisplayPreferencesRepository display;

    setUp(() {
      store = makeStore();
      sessions = KeyValueSessionRepository(store);
      presets = KeyValuePresetRepository(store);
      display = KeyValueDisplayPreferencesRepository(store);
    });

    test('active session round trip', () async {
      expect(await sessions.loadActive(), isNull);
      final s = sampleSession('a');
      await sessions.saveActive(s);
      final loaded = await sessions.loadActive();
      expect(jsonEncode(loaded!.toJson()), jsonEncode(s.toJson()));
      await sessions.clearActive();
      expect(await sessions.loadActive(), isNull);
    });

    test('archive moves the active session to past sessions', () async {
      final s = run(sampleSession('a'), [const EndSession()]);
      await sessions.saveActive(s);
      await sessions.archive(s);
      expect(await sessions.loadActive(), isNull);
      final past = await sessions.listPast();
      expect(past.single.id, 'a');
      expect(past.single.readable, isTrue);
      expect(past.single.title, 'Alice & Carol vs Bob & Dave');
      expect((await sessions.loadPast('a'))!.records, hasLength(1));
    });

    test('past sessions are newest first', () async {
      await sessions.archive(sampleSession('a'));
      await sessions.archive(sampleSession('b'));
      expect((await sessions.listPast()).map((e) => e.id), ['b', 'a']);
    });

    test('delete a past session', () async {
      await sessions.archive(sampleSession('a'));
      await sessions.archive(sampleSession('b'));
      await sessions.deletePast('a');
      expect((await sessions.listPast()).map((e) => e.id), ['b']);
      expect(await sessions.loadPast('a'), isNull);
    });

    test('House rules and last preset', () async {
      expect(await presets.loadHouseRules(), ScoringValues.houseDefaults());
      expect(await presets.loadLastPreset(), ScoringPreset.standard);
      final v = ScoringValues.houseDefaults().withValue(
        ScoringField.gameThreshold,
        120,
      );
      await presets.saveHouseRules(v);
      await presets.saveLastPreset(ScoringPreset.houseRules);
      expect((await presets.loadHouseRules())[ScoringField.gameThreshold], 120);
      expect(await presets.loadLastPreset(), ScoringPreset.houseRules);
    });

    test('display preferences', () async {
      expect(await display.load(), const DisplayPreferences());
      const p = DisplayPreferences(
        themeMode: ThemeModeSetting.dark,
        textSize: TextSizeSetting.large,
        suitColors: SuitColorsSetting.four,
        sheetView: SheetView.cards,
      );
      await display.save(p);
      expect(await display.load(), p);
    });
  });
}

void main() {
  contractTests('in-memory', MemoryKeyValueStore.new);

  contractTests('shared_preferences', () {
    SharedPreferences.setMockInitialValues({});
    return SharedPreferencesStore();
  });

  test('in-memory repository classes', () async {
    final r = InMemorySessionRepository();
    await r.saveActive(sampleSession('x'));
    expect((await r.loadActive())!.id, 'x');
    expect(
      await InMemoryPresetRepository().loadHouseRules(),
      ScoringValues.houseDefaults(),
    );
    expect(
      await InMemoryDisplayPreferencesRepository().load(),
      const DisplayPreferences(),
    );
  });

  group('Stored data format version', () {
    test('an older version is converted with its migration', () async {
      final store = MemoryKeyValueStore();
      final s = sampleSession('old');
      // Version 1 data that stores the session under an old key name.
      store.data[StorageKeys.activeSession] = encodeEnvelope({
        'legacy': s.toJson(),
      }, version: 1);
      final repo = KeyValueSessionRepository(
        store,
        formatVersion: 2,
        migrations: {1: (data) => data['legacy']! as Map<String, Object?>},
      );
      expect((await repo.loadActive())!.id, 'old');
    });

    test('a version without a migration cannot be read', () {
      expect(
        () => decodeEnvelope(encodeEnvelope({}, version: 1), targetVersion: 2),
        throwsA(isA<UnreadableDataException>()),
      );
      expect(
        () => decodeEnvelope(encodeEnvelope({}, version: 9)),
        throwsA(isA<UnreadableDataException>()),
      );
    });

    test('damaged past session shows as cannot be opened', () async {
      final store = MemoryKeyValueStore();
      final repo = KeyValueSessionRepository(store);
      await repo.archive(sampleSession('good'));
      await repo.archive(sampleSession('bad'));
      const damaged = '{"formatVersion": 1, "data": {"id": 3';
      store.data[StorageKeys.pastSession('bad')] = damaged;
      final past = await repo.listPast();
      expect(past.firstWhere((e) => e.id == 'bad').readable, isFalse);
      expect(past.firstWhere((e) => e.id == 'good').readable, isTrue);
      expect(await repo.loadPast('good'), isNotNull);
      // The data stays unchanged.
      expect(store.data[StorageKeys.pastSession('bad')], damaged);
    });

    test('damaged active session moves unchanged to past sessions', () async {
      final store = MemoryKeyValueStore();
      final repo = KeyValueSessionRepository(store);
      const damaged = 'not json';
      store.data[StorageKeys.activeSession] = damaged;
      expect(await repo.loadActive(), isNull);
      final past = await repo.listPast();
      expect(past.single.readable, isFalse);
      expect(store.data[StorageKeys.pastSession(past.single.id)], damaged);
    });
  });

  test('a past session keeps its own values', () async {
    final repo = InMemorySessionRepository();
    final presets = InMemoryPresetRepository();
    final house = ScoringValues.houseDefaults().withValue(
      ScoringField.rubberTwoNil,
      600,
    );
    var s = SessionController.start(
      id: 'p',
      now: t0,
      settings: settings(preset: ScoringPreset.houseRules, values: house),
    );
    s = playDeal(s, '4S', Seat.north);
    s = playDeal(s, '4S', Seat.north);
    await repo.archive(run(s, [const EndSession()]));
    await presets.saveHouseRules(
      house.withValue(ScoringField.rubberTwoNil, 800),
    );
    final past = (await repo.loadPast('p'))!;
    expect(
      past.ledger.deals[1].score.componentTotal(ScoreComponent.rubberBonus),
      600,
    );
  });

  test('delete all data', () async {
    final store = MemoryKeyValueStore();
    final sessions = KeyValueSessionRepository(store);
    final presets = KeyValuePresetRepository(store);
    final display = KeyValueDisplayPreferencesRepository(store);
    await sessions.saveActive(sampleSession('a'));
    await sessions.archive(sampleSession('b'));
    await presets.saveHouseRules(
      ScoringValues.houseDefaults().withValue(ScoringField.gameThreshold, 120),
    );
    await presets.saveLastPreset(ScoringPreset.houseRules);
    await display.save(
      const DisplayPreferences(themeMode: ThemeModeSetting.dark),
    );
    await KeyValueLocalDataRepository(store).deleteAll();
    expect(await sessions.loadActive(), isNull);
    expect(await sessions.listPast(), isEmpty);
    expect(await presets.loadHouseRules(), ScoringValues.houseDefaults());
    expect(await presets.loadLastPreset(), ScoringPreset.standard);
    expect(await display.load(), const DisplayPreferences());
  });

  test('shared_preferences clear removes the app data', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SharedPreferencesStore();
    await store.write('session.active', 'x');
    await KeyValueLocalDataRepository(store).deleteAll();
    expect(await store.read('session.active'), isNull);
  });
}
