import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../scoring/scoring.dart';
import '../../session/session.dart';
import '../../storage/storage.dart';

/// The data that the app loads before the first frame.
class AppBootstrap {
  const AppBootstrap({
    required this.active,
    required this.houseRules,
    required this.lastPreset,
    required this.display,
  });

  final SessionState? active;
  final ScoringValues houseRules;
  final ScoringPreset lastPreset;
  final DisplayPreferences display;

  static Future<AppBootstrap> load({
    required SessionRepository sessions,
    required PresetRepository presets,
    required DisplayPreferencesRepository display,
  }) async => AppBootstrap(
    active: await sessions.loadActive(),
    houseRules: await presets.loadHouseRules(),
    lastPreset: await presets.loadLastPreset(),
    display: await display.load(),
  );
}

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => throw UnimplementedError('Override sessionRepositoryProvider'),
);
final presetRepositoryProvider = Provider<PresetRepository>(
  (ref) => throw UnimplementedError('Override presetRepositoryProvider'),
);
final displayRepositoryProvider = Provider<DisplayPreferencesRepository>(
  (ref) => throw UnimplementedError('Override displayRepositoryProvider'),
);
final bootstrapProvider = Provider<AppBootstrap>(
  (ref) => throw UnimplementedError('Override bootstrapProvider'),
);

/// Holds the active session. Each new state is saved at once.
class SessionNotifier extends Notifier<SessionState?> {
  @override
  SessionState? build() => ref.read(bootstrapProvider).active;

  SessionRepository get _repo => ref.read(sessionRepositoryProvider);

  /// Sends [command] to the session. Returns an error text, or null.
  Future<String?> send(SessionCommand command) async {
    final current = state;
    if (current == null) return 'No active session';
    final SessionState next;
    try {
      next = SessionController.apply(current, command);
    } on InvalidCommandException catch (e) {
      return e.message;
    }
    state = next;
    await _repo.saveActive(next);
    return null;
  }

  /// Starts a new session. An earlier active session is ended and moved to
  /// the past sessions.
  Future<void> start(SessionSettings settings) async {
    await archiveActive();
    final now = DateTime.now();
    final session = SessionController.start(
      id: 'session-${now.microsecondsSinceEpoch}',
      now: now,
      settings: settings,
    );
    state = session;
    await _repo.saveActive(session);
    await ref.read(lastPresetProvider.notifier).set(settings.preset);
  }

  /// Ends the active session if needed and moves it to the past sessions.
  Future<void> archiveActive() async {
    final current = state;
    if (current == null) return;
    final ended = current.isEnded
        ? current
        : current.copyWith(
            status: SessionStatus.ended,
            endReason: () => EndReason.early,
            endedAt: DateTime.now,
            draft: () =>
                current.draft?.stage == DealStage.scored ? current.draft : null,
          );
    await _repo.archive(ended);
    state = null;
    ref.invalidate(pastSessionsProvider);
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, SessionState?>(
  SessionNotifier.new,
);

/// The replay of the active session.
final ledgerProvider = Provider<LedgerSnapshot?>(
  (ref) => ref.watch(sessionProvider)?.ledger,
);

/// The saved "House rules" values.
class HouseRulesNotifier extends Notifier<ScoringValues> {
  @override
  ScoringValues build() => ref.read(bootstrapProvider).houseRules;

  Future<void> save(ScoringValues values) async {
    state = values;
    await ref.read(presetRepositoryProvider).saveHouseRules(values);
  }
}

final houseRulesProvider = NotifierProvider<HouseRulesNotifier, ScoringValues>(
  HouseRulesNotifier.new,
);

/// The preset of the most recent session.
class LastPresetNotifier extends Notifier<ScoringPreset> {
  @override
  ScoringPreset build() => ref.read(bootstrapProvider).lastPreset;

  Future<void> set(ScoringPreset preset) async {
    state = preset;
    await ref.read(presetRepositoryProvider).saveLastPreset(preset);
  }
}

final lastPresetProvider = NotifierProvider<LastPresetNotifier, ScoringPreset>(
  LastPresetNotifier.new,
);

/// The display settings of this device.
class DisplayNotifier extends Notifier<DisplayPreferences> {
  @override
  DisplayPreferences build() => ref.read(bootstrapProvider).display;

  Future<void> update(DisplayPreferences preferences) async {
    state = preferences;
    await ref.read(displayRepositoryProvider).save(preferences);
  }
}

final displayProvider = NotifierProvider<DisplayNotifier, DisplayPreferences>(
  DisplayNotifier.new,
);

final pastSessionsProvider = FutureProvider<List<PastSessionEntry>>(
  (ref) => ref.read(sessionRepositoryProvider).listPast(),
);

/// Values of a preset: "Standard" or the saved "House rules".
ScoringValues valuesOf(ScoringPreset preset, ScoringValues houseRules) =>
    preset == ScoringPreset.standard ? ScoringValues.standard() : houseRules;
