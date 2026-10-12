import '../../core/core.dart';
import 'deal_result.dart';
import 'deal_scorer.dart';
import 'scoring_values.dart';

/// One deal after the replay.
class LedgerDeal {
  const LedgerDeal({
    required this.index,
    required this.result,
    required this.vulnerability,
    required this.rubberNumber,
    required this.gameNumber,
    required this.score,
    this.gameWonBy,
    this.rubberWonBy,
  });

  /// The position of the deal in the session, from 0.
  final int index;

  /// The result, or null for a passed-out deal.
  final DealResult? result;

  /// The vulnerability before the deal.
  final Vulnerability vulnerability;

  /// The rubber of the deal, from 1.
  final int rubberNumber;

  /// The game of the rubber that the below-the-line points of this deal
  /// count toward, from 1.
  final int gameNumber;

  /// All score items of the deal, including game and rubber bonuses.
  final DealScore score;

  final Side? gameWonBy;
  final Side? rubberWonBy;

  bool get isPassedOut => result == null;
}

/// One rubber after the replay.
class RubberSummary {
  RubberSummary({
    required this.number,
    required List<int> dealIndexes,
    required Map<Side, int> games,
    required Map<Side, int> totals,
    this.winner,
  }) : dealIndexes = List.unmodifiable(dealIndexes),
       games = Map.unmodifiable(games),
       totals = Map.unmodifiable(totals);

  final int number;
  final List<int> dealIndexes;
  final Map<Side, int> games;
  final Map<Side, int> totals;

  /// The side that won the rubber, or null while it is not complete.
  final Side? winner;

  bool get isComplete => winner != null;
}

/// The result of a replay of all recorded deals.
class LedgerSnapshot {
  LedgerSnapshot._({
    required List<LedgerDeal> deals,
    required List<RubberSummary> rubbers,
    required this.games,
    required this.partScores,
    required this.values,
    required this.components,
  }) : deals = List.unmodifiable(deals),
       rubbers = List.unmodifiable(rubbers);

  final List<LedgerDeal> deals;

  /// All rubbers. The last one is the current rubber. It can be complete
  /// only when the last deal completed it; the next deal then starts a new
  /// rubber.
  final List<RubberSummary> rubbers;

  /// Games won in the current rubber (the rubber of the next deal).
  final Map<Side, int> games;

  /// Points below the line in the current game.
  final Map<Side, int> partScores;

  final ScoringValues values;
  final ScoringComponents components;

  /// The vulnerability for the next deal.
  Vulnerability get nextVulnerability => Vulnerability(
    northSouth: games[Side.northSouth]! >= 1,
    eastWest: games[Side.eastWest]! >= 1,
  );

  /// The number of the rubber of the next deal.
  int get nextRubberNumber {
    if (rubbers.isEmpty) return 1;
    return rubbers.last.isComplete
        ? rubbers.last.number + 1
        : rubbers.last.number;
  }

  /// The session total of [side], without the unfinished rubber bonus.
  int totalFor(Side side) =>
      deals.fold(0, (sum, d) => sum + d.score.totalFor(side));

  /// The unfinished rubber bonus that applies if the session ends now.
  List<ScoreItem> unfinishedRubberBonus() {
    if (!components.unfinishedRubberBonus) return const [];
    final items = <ScoreItem>[];
    void add(Side side, int points) {
      if (points != 0) {
        items.add(ScoreItem(side, ScoreComponent.unfinishedRubber, points));
      }
    }

    for (final side in Side.values) {
      if (games[side] == 1 && games[side.opponent] == 0) {
        add(side, values[ScoringField.unfinishedOneGame]);
      }
    }
    for (final side in Side.values) {
      if (partScores[side]! > 0) {
        add(side, values[ScoringField.unfinishedPartScore]);
      }
    }
    return items;
  }

  /// The session total with the unfinished rubber bonus.
  int finalTotalFor(Side side) =>
      totalFor(side) +
      unfinishedRubberBonus()
          .where((i) => i.side == side)
          .fold(0, (sum, i) => sum + i.points);
}

/// Replays the recorded deals of a session and calculates games,
/// vulnerability, rubbers, and totals.
class RubberLedger {
  const RubberLedger._();

  /// [deals] holds one entry for each deal in order; null means a
  /// passed-out deal.
  static LedgerSnapshot replay(
    List<DealResult?> deals,
    ScoringValues values,
    ScoringComponents components,
  ) {
    final ledgerDeals = <LedgerDeal>[];
    final rubbers = <RubberSummary>[];

    var rubberNumber = 1;
    var gameNumber = 1;
    var games = {Side.northSouth: 0, Side.eastWest: 0};
    var partScores = {Side.northSouth: 0, Side.eastWest: 0};
    var rubberDeals = <int>[];
    var rubberTotals = {Side.northSouth: 0, Side.eastWest: 0};

    for (var i = 0; i < deals.length; i++) {
      final result = deals[i];
      final vulnerability = Vulnerability(
        northSouth: games[Side.northSouth]! >= 1,
        eastWest: games[Side.eastWest]! >= 1,
      );
      final items = <ScoreItem>[];
      Side? gameWonBy;
      Side? rubberWonBy;

      if (result != null) {
        items.addAll(
          DealScorer.score(result, vulnerability, values, components).items,
        );
        final below = items
            .where((it) => !it.aboveLine)
            .fold(0, (sum, it) => sum + it.points);
        if (below > 0) {
          final side = result.contract.declaringSide;
          partScores[side] = partScores[side]! + below;
          if (partScores[side]! >= values[ScoringField.gameThreshold]) {
            gameWonBy = side;
            games[side] = games[side]! + 1;
            final bonus =
                values[vulnerability.of(side)
                    ? ScoringField.gameBonusVulnerable
                    : ScoringField.gameBonusNotVulnerable];
            if (bonus != 0) {
              items.add(ScoreItem(side, ScoreComponent.gameBonus, bonus));
            }
            if (games[side] == 2) {
              rubberWonBy = side;
              final bonus =
                  values[games[side.opponent] == 0
                      ? ScoringField.rubberTwoNil
                      : ScoringField.rubberTwoOne];
              if (bonus != 0) {
                items.add(ScoreItem(side, ScoreComponent.rubberBonus, bonus));
              }
            }
          }
        }
      }

      final score = DealScore(items);
      ledgerDeals.add(
        LedgerDeal(
          index: i,
          result: result,
          vulnerability: vulnerability,
          rubberNumber: rubberNumber,
          gameNumber: gameNumber,
          score: score,
          gameWonBy: gameWonBy,
          rubberWonBy: rubberWonBy,
        ),
      );
      rubberDeals.add(i);
      for (final side in Side.values) {
        rubberTotals[side] = rubberTotals[side]! + score.totalFor(side);
      }

      if (gameWonBy != null) {
        // A line is drawn: the part-scores of both sides no longer count.
        partScores = {Side.northSouth: 0, Side.eastWest: 0};
        gameNumber++;
      }
      if (rubberWonBy != null) {
        rubbers.add(
          RubberSummary(
            number: rubberNumber,
            dealIndexes: rubberDeals,
            games: games,
            totals: rubberTotals,
            winner: rubberWonBy,
          ),
        );
        rubberNumber++;
        gameNumber = 1;
        games = {Side.northSouth: 0, Side.eastWest: 0};
        rubberDeals = [];
        rubberTotals = {Side.northSouth: 0, Side.eastWest: 0};
      }
    }

    if (rubberDeals.isNotEmpty) {
      rubbers.add(
        RubberSummary(
          number: rubberNumber,
          dealIndexes: rubberDeals,
          games: games,
          totals: rubberTotals,
        ),
      );
    }

    return LedgerSnapshot._(
      deals: ledgerDeals,
      rubbers: rubbers,
      games: Map.unmodifiable(games),
      partScores: Map.unmodifiable(partScores),
      values: values,
      components: components,
    );
  }
}
