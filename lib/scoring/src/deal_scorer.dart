import '../../core/core.dart';
import 'deal_result.dart';
import 'scoring_values.dart';

/// The components of a score, with their traditional names.
enum ScoreComponent {
  contractPoints('Contract points', aboveLine: false),
  overtricks('Overtricks'),
  insultBonus('Insult bonus'),
  slamBonus('Slam bonus'),
  undertricks('Undertricks (penalty)'),
  honors('Honors'),
  gameBonus('Game bonus'),
  rubberBonus('Rubber bonus'),
  unfinishedRubber('Unfinished rubber bonus');

  const ScoreComponent(this.label, {this.aboveLine = true});

  final String label;
  final bool aboveLine;
}

/// Points for one side from one score component.
class ScoreItem {
  const ScoreItem(this.side, this.component, this.points);

  final Side side;
  final ScoreComponent component;
  final int points;

  bool get aboveLine => component.aboveLine;

  @override
  bool operator ==(Object other) =>
      other is ScoreItem &&
      other.side == side &&
      other.component == component &&
      other.points == points;

  @override
  int get hashCode => Object.hash(side, component, points);

  @override
  String toString() => '${component.label}: $points (${side.name})';
}

/// The score items of one deal. Items with 0 points are left out.
class DealScore {
  DealScore(List<ScoreItem> items) : items = List.unmodifiable(items);

  final List<ScoreItem> items;

  int totalFor(Side side) =>
      items.where((i) => i.side == side).fold(0, (sum, i) => sum + i.points);

  int belowLineFor(Side side) => items
      .where((i) => i.side == side && !i.aboveLine)
      .fold(0, (sum, i) => sum + i.points);

  int componentTotal(ScoreComponent component) => items
      .where((i) => i.component == component)
      .fold(0, (sum, i) => sum + i.points);
}

/// Scores one deal. The scorer reads every number from [ScoringValues].
///
/// The deal-level components are: contract points, overtricks, the insult
/// bonus, slam bonuses, undertricks, and honors. Game and rubber bonuses
/// depend on earlier deals, so [RubberLedger] adds them.
class DealScorer {
  const DealScorer._();

  static DealScore score(
    DealResult result,
    Vulnerability vulnerability,
    ScoringValues values,
    ScoringComponents components,
  ) {
    final contract = result.contract;
    final declaring = contract.declaringSide;
    final vulnerable = vulnerability.of(declaring);
    final items = <ScoreItem>[];

    void add(Side side, ScoreComponent component, int points) {
      if (points != 0) items.add(ScoreItem(side, component, points));
    }

    if (result.isFulfilled) {
      add(
        declaring,
        ScoreComponent.contractPoints,
        contractPoints(contract, values),
      );
      add(
        declaring,
        ScoreComponent.overtricks,
        overtrickPoints(contract, result.overtricks, vulnerable, values),
      );
      add(declaring, ScoreComponent.insultBonus, switch (contract.doubling) {
        Doubling.none => 0,
        Doubling.doubled => values[ScoringField.insultDoubled],
        Doubling.redoubled => values[ScoringField.insultRedoubled],
      });
      add(declaring, ScoreComponent.slamBonus, switch (contract.level) {
        6 =>
          values[vulnerable
              ? ScoringField.smallSlamVulnerable
              : ScoringField.smallSlamNotVulnerable],
        7 =>
          values[vulnerable
              ? ScoringField.grandSlamVulnerable
              : ScoringField.grandSlamNotVulnerable],
        _ => 0,
      });
    } else {
      add(
        declaring.opponent,
        ScoreComponent.undertricks,
        undertrickPoints(
          result.undertricks,
          contract.doubling,
          vulnerable,
          values,
        ),
      );
    }

    final honors = result.honors;
    if (components.honors && honors != null && honors.side != null) {
      add(honors.side!, ScoreComponent.honors, honors.holding.points(values));
    }
    return DealScore(items);
  }

  /// The points of the contracted tricks over 6, with the multiplier for a
  /// double or a redouble.
  static int contractPoints(Contract contract, ScoringValues values) {
    final level = contract.level;
    final base = switch (contract.strain) {
      Strain.clubs ||
      Strain.diamonds => level * values[ScoringField.minorTrick],
      Strain.hearts || Strain.spades => level * values[ScoringField.majorTrick],
      Strain.noTrump =>
        values[ScoringField.noTrumpFirstTrick] +
            (level - 1) * values[ScoringField.noTrumpLaterTrick],
    };
    return base *
        switch (contract.doubling) {
          Doubling.none => 1,
          Doubling.doubled => values[ScoringField.doubleMultiplier],
          Doubling.redoubled => values[ScoringField.redoubleMultiplier],
        };
  }

  static int overtrickPoints(
    Contract contract,
    int overtricks,
    bool vulnerable,
    ScoringValues values,
  ) {
    if (overtricks == 0) return 0;
    final doubledValue =
        values[vulnerable
            ? ScoringField.overtrickDoubledVulnerable
            : ScoringField.overtrickDoubledNotVulnerable];
    final each = switch (contract.doubling) {
      Doubling.none => switch (contract.strain) {
        Strain.clubs || Strain.diamonds => values[ScoringField.minorTrick],
        Strain.hearts || Strain.spades => values[ScoringField.majorTrick],
        Strain.noTrump => values[ScoringField.noTrumpLaterTrick],
      },
      Doubling.doubled => doubledValue,
      // Redoubled overtricks are always 2 × the doubled value.
      Doubling.redoubled => 2 * doubledValue,
    };
    return overtricks * each;
  }

  /// The penalty for [undertricks]. Each undertrick takes the value of its
  /// position: 1st, 2nd and 3rd, 4th and later.
  static int undertrickPoints(
    int undertricks,
    Doubling doubling,
    bool vulnerable,
    ScoringValues values,
  ) {
    if (doubling == Doubling.none) {
      return undertricks *
          values[vulnerable
              ? ScoringField.undertrickUndoubledVulnerable
              : ScoringField.undertrickUndoubledNotVulnerable];
    }
    final first =
        values[vulnerable
            ? ScoringField.undertrickDoubledVulnerableFirst
            : ScoringField.undertrickDoubledNotVulnerableFirst];
    final secondThird =
        values[vulnerable
            ? ScoringField.undertrickDoubledVulnerableSecondThird
            : ScoringField.undertrickDoubledNotVulnerableSecondThird];
    final fourthOn =
        values[vulnerable
            ? ScoringField.undertrickDoubledVulnerableFourthOn
            : ScoringField.undertrickDoubledNotVulnerableFourthOn];
    var total = 0;
    for (var position = 1; position <= undertricks; position++) {
      total += position == 1
          ? first
          : position <= 3
          ? secondThird
          : fourthOn;
    }
    // Redoubled undertricks are always 2 × the doubled values.
    return doubling == Doubling.redoubled ? 2 * total : total;
  }
}
