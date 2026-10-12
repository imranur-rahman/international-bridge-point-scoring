import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../../storage/storage.dart';
import 'providers.dart';
import 'router.dart';
import 'theme.dart';

class BridgeScorekeeperApp extends ConsumerWidget {
  const BridgeScorekeeperApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final display = ref.watch(displayProvider);
    return MaterialApp.router(
      title: 'IB Scoring',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: themeModeOf(display.themeMode),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => _TextScale(
        factor: display.textSize.scale,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

/// Multiplies the device text size with the app text size.
class _TextScale extends StatelessWidget {
  const _TextScale({required this.factor, required this.child});

  final double factor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final device = MediaQuery.textScalerOf(context);
    return MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(device.scale(1) * factor)),
      child: child,
    );
  }
}

/// Creates the provider overrides for the app with [bootstrap] data.
List<Override> appOverrides({
  required SessionRepository sessions,
  required PresetRepository presets,
  required DisplayPreferencesRepository display,
  required LocalDataRepository localData,
  required AppBootstrap bootstrap,
}) => [
  sessionRepositoryProvider.overrideWithValue(sessions),
  presetRepositoryProvider.overrideWithValue(presets),
  displayRepositoryProvider.overrideWithValue(display),
  localDataRepositoryProvider.overrideWithValue(localData),
  bootstrapProvider.overrideWithValue(bootstrap),
];
