import '../../core/core.dart';
import '../../scoring/scoring.dart';
import 'end_rule.dart';
import 'session_state.dart';
import 'settings.dart';

/// One row of the rubber table.
class RubberRow {
  const RubberRow(this.number, this.totals, {required this.isComplete});

  final int number;
  final Map<Side, int> totals;
  final bool isComplete;
}

/// One point of the score chart: the session totals after a deal.
class ChartPoint {
  const ChartPoint(this.dealNumber, this.totals);

  final int dealNumber;
  final Map<Side, int> totals;
}

/// A deal with many points for one side.
class BigDeal {
  const BigDeal({
    required this.dealNumber,
    required this.result,
    required this.side,
    required this.points,
  });

  final int dealNumber;
  final DealResult result;
  final Side side;
  final int points;
}

/// Statistics of one player as declarer.
class PlayerStats {
  const PlayerStats({
    required this.seat,
    required this.declared,
    required this.fulfilled,
    required this.down,
    required this.slamsBid,
    required this.slamsMade,
  });

  final Seat seat;
  final int declared;
  final int fulfilled;
  final int down;
  final int slamsBid;
  final int slamsMade;
}

/// The data of the final summary.
class SessionSummary {
  const SessionSummary({
    required this.dealCount,
    required this.finalTotals,
    required this.winner,
    required this.margin,
    required this.rubbers,
    required this.unfinishedBonus,
    required this.chart,
    required this.target,
    required this.biggestDeals,
    required this.playerStats,
  });

  final int dealCount;
  final Map<Side, int> finalTotals;

  /// The winning side, or null for a tie.
  final Side? winner;
  final int margin;
  final List<RubberRow> rubbers;
  final List<ScoreItem> unfinishedBonus;
  final List<ChartPoint> chart;

  /// The target of the "Target score" end rule, or null.
  final int? target;
  final List<BigDeal> biggestDeals;
  final List<PlayerStats> playerStats;

  static SessionSummary of(SessionState state) {
    final ledger = state.ledger;
    final unfinished = ledger.unfinishedRubberBonus();
    final totals = {
      for (final side in Side.values) side: ledger.finalTotalFor(side),
    };
    final ns = totals[Side.northSouth]!;
    final ew = totals[Side.eastWest]!;

    final chart = <ChartPoint>[
      const ChartPoint(0, {Side.northSouth: 0, Side.eastWest: 0}),
    ];
    final running = {Side.northSouth: 0, Side.eastWest: 0};
    for (final d in ledger.deals) {
      for (final side in Side.values) {
        running[side] = running[side]! + d.score.totalFor(side);
      }
      chart.add(ChartPoint(d.index + 1, Map.of(running)));
    }

    final big = <BigDeal>[
      for (final d in ledger.deals)
        if (d.result != null)
          for (final side in Side.values)
            if (d.score.totalFor(side) > 0)
              BigDeal(
                dealNumber: d.index + 1,
                result: d.result!,
                side: side,
                points: d.score.totalFor(side),
              ),
    ]..sort((a, b) => b.points.compareTo(a.points));

    final stats = [
      for (final seat in Seat.values) _statsFor(seat, state.records),
    ];

    final rule = state.settings.endRule;
    return SessionSummary(
      dealCount: state.records.length,
      finalTotals: totals,
      winner: ns == ew
          ? null
          : ns > ew
          ? Side.northSouth
          : Side.eastWest,
      margin: (ns - ew).abs(),
      rubbers: [
        for (final r in ledger.rubbers)
          RubberRow(r.number, r.totals, isComplete: r.isComplete),
      ],
      unfinishedBonus: unfinished,
      chart: chart,
      target: rule is TargetScoreRule ? rule.points : null,
      biggestDeals: big.take(3).toList(),
      playerStats: stats,
    );
  }

  static PlayerStats _statsFor(Seat seat, List<DealRecord> records) {
    var declared = 0, fulfilled = 0, down = 0, slamsBid = 0, slamsMade = 0;
    for (final r in records) {
      final result = r.result;
      if (result == null || result.contract.declarer != seat) continue;
      declared++;
      final slam = result.contract.level >= 6;
      if (slam) slamsBid++;
      if (result.isFulfilled) {
        fulfilled++;
        if (slam) slamsMade++;
      } else {
        down++;
      }
    }
    return PlayerStats(
      seat: seat,
      declared: declared,
      fulfilled: fulfilled,
      down: down,
      slamsBid: slamsBid,
      slamsMade: slamsMade,
    );
  }
}

/// The settings for "New session, same players". The first dealer is the
/// next player clockwise after the dealer of the last deal.
SessionSettings rematchSettings(SessionState ended) {
  final s = ended.settings;
  final lastDealer = ended.records.isEmpty
      ? s.firstDealer.previous
      : ended.records.last.dealer;
  return SessionSettings(
    players: s.players,
    firstDealer: lastDealer.next,
    endRule: s.endRule,
    biddingStep: s.biddingStep,
    components: s.components,
    preset: s.preset,
    values: s.values,
  );
}
