import '../../core/core.dart';
import '../../scoring/scoring.dart';

/// The rule that ends a session.
sealed class EndRule {
  const EndRule();

  /// True when the session ends after [dealCount] deals with [snapshot].
  bool isReached(LedgerSnapshot snapshot, int dealCount);

  /// An error text, or null when the rule is valid.
  String? validate();

  Map<String, Object?> toJson();

  static EndRule fromJson(Object? json) {
    final map = json as Map<String, Object?>;
    return switch (map['type']) {
      'deals' => DealCountRule(map['value'] as int),
      'target' => TargetScoreRule(map['value'] as int),
      final t => throw FormatException('Unknown end rule $t'),
    };
  }
}

/// The session ends after a number of deals.
final class DealCountRule extends EndRule {
  const DealCountRule(this.deals);

  static const int min = 1;
  static const int max = 200;
  static const int defaultDeals = 16;

  final int deals;

  @override
  bool isReached(LedgerSnapshot snapshot, int dealCount) => dealCount >= deals;

  @override
  String? validate() => deals < min || deals > max
      ? 'Enter a whole number from $min to $max'
      : null;

  @override
  Map<String, Object?> toJson() => {'type': 'deals', 'value': deals};

  @override
  bool operator ==(Object other) =>
      other is DealCountRule && other.deals == deals;

  @override
  int get hashCode => deals.hashCode;
}

/// The session ends after the deal in which a side reaches a target total.
/// The total does not include the unfinished rubber bonus.
final class TargetScoreRule extends EndRule {
  const TargetScoreRule(this.points);

  static const int min = 100;
  static const int max = 100000;

  final int points;

  @override
  bool isReached(LedgerSnapshot snapshot, int dealCount) =>
      Side.values.any((side) => snapshot.totalFor(side) >= points);

  @override
  String? validate() => points < min || points > max
      ? 'Enter a whole number from $min to $max'
      : null;

  @override
  Map<String, Object?> toJson() => {'type': 'target', 'value': points};

  @override
  bool operator ==(Object other) =>
      other is TargetScoreRule && other.points == points;

  @override
  int get hashCode => points.hashCode;
}
