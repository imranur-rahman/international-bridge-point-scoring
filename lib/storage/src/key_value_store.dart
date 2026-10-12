import 'package:shared_preferences/shared_preferences.dart';

/// A minimal string store. The repositories use it so that tests can run
/// them in memory.
abstract interface class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

/// A [KeyValueStore] in memory, for tests.
class MemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> data = {};

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;

  @override
  Future<void> remove(String key) async => data.remove(key);
}

/// A [KeyValueStore] on `shared_preferences`: `localStorage` on web,
/// `NSUserDefaults` on iOS, and `SharedPreferences` on Android.
class SharedPreferencesStore implements KeyValueStore {
  SharedPreferencesStore([Future<SharedPreferences>? prefs])
    : _prefs = prefs ?? SharedPreferences.getInstance();

  final Future<SharedPreferences> _prefs;

  @override
  Future<String?> read(String key) async => (await _prefs).getString(key);

  @override
  Future<void> write(String key, String value) async {
    await (await _prefs).setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await (await _prefs).remove(key);
  }
}
