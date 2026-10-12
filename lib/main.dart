import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'storage/storage.dart';
import 'ui/ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = SharedPreferencesStore();
  final sessions = KeyValueSessionRepository(store);
  final presets = KeyValuePresetRepository(store);
  final display = KeyValueDisplayPreferencesRepository(store);
  final bootstrap = await AppBootstrap.load(
    sessions: sessions,
    presets: presets,
    display: display,
  );
  runApp(
    ProviderScope(
      overrides: appOverrides(
        sessions: sessions,
        presets: presets,
        display: display,
        localData: KeyValueLocalDataRepository(store),
        bootstrap: bootstrap,
      ),
      child: const BridgeScorekeeperApp(),
    ),
  );
}
