import 'dart:convert';

import '../../core/core.dart';
import '../../scoring/scoring.dart';
import '../../session/session.dart';
import 'display_preferences.dart';
import 'format.dart';
import 'key_value_store.dart';

/// One entry of the past sessions list.
class PastSessionEntry {
  const PastSessionEntry.readable({
    required this.id,
    required SessionState this.session,
  }) : readable = true;

  const PastSessionEntry.unreadable(this.id) : readable = false, session = null;

  final String id;
  final bool readable;

  /// The session, only when [readable].
  final SessionState? session;

  DateTime? get date => session?.endedAt ?? session?.createdAt;

  String? get title {
    final p = session?.settings.players;
    if (p == null) return null;
    return '${p.partnershipName(Side.northSouth)} vs '
        '${p.partnershipName(Side.eastWest)}';
  }
}

abstract interface class SessionRepository {
  /// The active session, or null. An active session that cannot be read is
  /// moved, unchanged, to the past sessions list.
  Future<SessionState?> loadActive();
  Future<void> saveActive(SessionState state);
  Future<void> clearActive();

  /// Past sessions, newest first.
  Future<List<PastSessionEntry>> listPast();
  Future<SessionState?> loadPast(String id);

  /// Saves [state] as a past session and clears the active session if it
  /// has the same id.
  Future<void> archive(SessionState state);
  Future<void> deletePast(String id);
}

abstract interface class PresetRepository {
  /// "House rules", or the House rules defaults when nothing is saved.
  Future<ScoringValues> loadHouseRules();
  Future<void> saveHouseRules(ScoringValues values);

  /// The preset of the most recent session, or "Standard".
  Future<ScoringPreset> loadLastPreset();
  Future<void> saveLastPreset(ScoringPreset preset);
}

abstract interface class DisplayPreferencesRepository {
  Future<DisplayPreferences> load();
  Future<void> save(DisplayPreferences preferences);
}

/// Storage keys.
abstract final class StorageKeys {
  static const String activeSession = 'session.active';
  static const String pastIndex = 'session.past.index';
  static String pastSession(String id) => 'session.past.$id';
  static const String houseRules = 'preset.houseRules';
  static const String lastPreset = 'preset.last';
  static const String display = 'display.preferences';
}

/// The migration steps for stored sessions, by format version.
const Map<int, Migration> sessionMigrations = {};

/// A [SessionRepository] on a [KeyValueStore].
class KeyValueSessionRepository implements SessionRepository {
  KeyValueSessionRepository(
    this.store, {
    this.migrations = sessionMigrations,
    this.formatVersion = currentFormatVersion,
  });

  final KeyValueStore store;
  final Map<int, Migration> migrations;
  final int formatVersion;

  SessionState _decode(String raw) {
    final data = decodeEnvelope(
      raw,
      migrations: migrations,
      targetVersion: formatVersion,
    );
    try {
      return SessionState.fromJson(data);
    } on Object catch (e) {
      throw UnreadableDataException('Not a session: $e');
    }
  }

  String _encode(SessionState s) =>
      encodeEnvelope(s.toJson(), version: formatVersion);

  Future<List<String>> _index() async {
    final raw = await store.read(StorageKeys.pastIndex);
    if (raw == null) return [];
    try {
      return [for (final id in jsonDecode(raw) as List<Object?>) id as String];
    } on Object {
      return [];
    }
  }

  Future<void> _writeIndex(List<String> ids) =>
      store.write(StorageKeys.pastIndex, jsonEncode(ids));

  @override
  Future<SessionState?> loadActive() async {
    final raw = await store.read(StorageKeys.activeSession);
    if (raw == null) return null;
    try {
      return _decode(raw);
    } on UnreadableDataException {
      // Keep the data unchanged, but move it out of the way.
      final id = 'unreadable-${DateTime.now().microsecondsSinceEpoch}';
      await store.write(StorageKeys.pastSession(id), raw);
      await _writeIndex([id, ...await _index()]);
      await store.remove(StorageKeys.activeSession);
      return null;
    }
  }

  @override
  Future<void> saveActive(SessionState state) =>
      store.write(StorageKeys.activeSession, _encode(state));

  @override
  Future<void> clearActive() => store.remove(StorageKeys.activeSession);

  @override
  Future<List<PastSessionEntry>> listPast() async {
    final entries = <PastSessionEntry>[];
    for (final id in await _index()) {
      final raw = await store.read(StorageKeys.pastSession(id));
      if (raw == null) continue;
      try {
        entries.add(PastSessionEntry.readable(id: id, session: _decode(raw)));
      } on UnreadableDataException {
        entries.add(PastSessionEntry.unreadable(id));
      }
    }
    return entries;
  }

  @override
  Future<SessionState?> loadPast(String id) async {
    final raw = await store.read(StorageKeys.pastSession(id));
    if (raw == null) return null;
    try {
      return _decode(raw);
    } on UnreadableDataException {
      return null;
    }
  }

  @override
  Future<void> archive(SessionState state) async {
    await store.write(StorageKeys.pastSession(state.id), _encode(state));
    final ids = (await _index())..remove(state.id);
    await _writeIndex([state.id, ...ids]);
    final active = await store.read(StorageKeys.activeSession);
    if (active != null) {
      try {
        if (_decode(active).id == state.id) await clearActive();
      } on UnreadableDataException {
        // Leave data that cannot be read unchanged.
      }
    }
  }

  @override
  Future<void> deletePast(String id) async {
    await store.remove(StorageKeys.pastSession(id));
    await _writeIndex((await _index())..remove(id));
  }
}

/// A [PresetRepository] on a [KeyValueStore].
class KeyValuePresetRepository implements PresetRepository {
  KeyValuePresetRepository(this.store);

  final KeyValueStore store;

  @override
  Future<ScoringValues> loadHouseRules() async {
    final raw = await store.read(StorageKeys.houseRules);
    if (raw == null) return ScoringValues.houseDefaults();
    try {
      return ScoringValues.fromJson(decodeEnvelope(raw));
    } on Object {
      return ScoringValues.houseDefaults();
    }
  }

  @override
  Future<void> saveHouseRules(ScoringValues values) =>
      store.write(StorageKeys.houseRules, encodeEnvelope(values.toJson()));

  @override
  Future<ScoringPreset> loadLastPreset() async {
    final raw = await store.read(StorageKeys.lastPreset);
    return ScoringPreset.values.where((p) => p.name == raw).firstOrNull ??
        ScoringPreset.standard;
  }

  @override
  Future<void> saveLastPreset(ScoringPreset preset) =>
      store.write(StorageKeys.lastPreset, preset.name);
}

/// A [DisplayPreferencesRepository] on a [KeyValueStore].
class KeyValueDisplayPreferencesRepository
    implements DisplayPreferencesRepository {
  KeyValueDisplayPreferencesRepository(this.store);

  final KeyValueStore store;

  @override
  Future<DisplayPreferences> load() async {
    final raw = await store.read(StorageKeys.display);
    if (raw == null) return const DisplayPreferences();
    try {
      return DisplayPreferences.fromJson(jsonDecode(raw));
    } on Object {
      return const DisplayPreferences();
    }
  }

  @override
  Future<void> save(DisplayPreferences preferences) =>
      store.write(StorageKeys.display, jsonEncode(preferences.toJson()));
}

/// Deletes all data of the app on this device: sessions, past sessions,
/// House rules, the last preset, and the display settings.
abstract interface class LocalDataRepository {
  Future<void> deleteAll();
}

class KeyValueLocalDataRepository implements LocalDataRepository {
  KeyValueLocalDataRepository(this.store);

  final KeyValueStore store;

  @override
  Future<void> deleteAll() => store.clear();
}

/// In-memory repositories, for tests.
class InMemorySessionRepository extends KeyValueSessionRepository {
  InMemorySessionRepository() : super(MemoryKeyValueStore());
}

class InMemoryPresetRepository extends KeyValuePresetRepository {
  InMemoryPresetRepository() : super(MemoryKeyValueStore());
}

class InMemoryDisplayPreferencesRepository
    extends KeyValueDisplayPreferencesRepository {
  InMemoryDisplayPreferencesRepository() : super(MemoryKeyValueStore());
}
