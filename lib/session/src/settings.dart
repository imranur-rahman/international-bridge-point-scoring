import '../../core/core.dart';
import '../../scoring/scoring.dart';
import 'end_rule.dart';
import 'players.dart';

/// The settings of a session. They do not change after the session starts.
class SessionSettings {
  const SessionSettings({
    required this.players,
    required this.firstDealer,
    required this.endRule,
    required this.biddingStep,
    required this.components,
    required this.preset,
    required this.values,
  });

  final Players players;
  final Seat firstDealer;
  final EndRule endRule;
  final bool biddingStep;
  final ScoringComponents components;
  final ScoringPreset preset;

  /// A copy of the preset values at the session start. A later change to
  /// "House rules" does not change it.
  final ScoringValues values;

  Map<String, Object?> toJson() => {
    'players': players.toJson(),
    'firstDealer': firstDealer.toJson(),
    'endRule': endRule.toJson(),
    'biddingStep': biddingStep,
    'components': components.toJson(),
    'preset': preset.toJson(),
    'values': values.toJson(),
  };

  static SessionSettings fromJson(Object? json) {
    final map = json as Map<String, Object?>;
    return SessionSettings(
      players: Players.fromJson(map['players']),
      firstDealer: Seat.fromJson(map['firstDealer']),
      endRule: EndRule.fromJson(map['endRule']),
      biddingStep: map['biddingStep'] as bool,
      components: ScoringComponents.fromJson(map['components']),
      preset: ScoringPreset.fromJson(map['preset']),
      values: ScoringValues.fromJson(map['values']),
    );
  }
}
