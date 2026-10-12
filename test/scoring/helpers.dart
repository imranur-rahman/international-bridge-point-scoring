import 'package:bridge_scorekeeper/core/core.dart';
import 'package:bridge_scorekeeper/scoring/scoring.dart';

final ScoringValues standard = ScoringValues.standard();
final ScoringValues house = ScoringValues.houseDefaults();
const ScoringComponents allOn = ScoringComponents();

const Vulnerability nv = Vulnerability.none;
const Vulnerability bothV = Vulnerability(northSouth: true, eastWest: true);

/// Builds a result. [code] is a contract such as "4S", "3NX", or "2HXX".
/// The declarer defaults to South (side N-S).
DealResult deal(
  String code, {
  int? tricks,
  int diff = 0,
  Seat declarer = Seat.south,
  Honors? honors,
}) {
  final level = int.parse(code.substring(0, 1));
  final strain = Strain.fromCode(code.substring(1, 2));
  final doubling = code.endsWith('XX')
      ? Doubling.redoubled
      : code.endsWith('X')
      ? Doubling.doubled
      : Doubling.none;
  return DealResult(
    contract: Contract(
      bid: Bid(level, strain),
      doubling: doubling,
      declarer: declarer,
    ),
    tricksTaken: tricks ?? level + 6 + diff,
    honors: honors,
  );
}

DealScore scoreOf(
  DealResult r, {
  Vulnerability v = nv,
  ScoringValues? values,
  ScoringComponents components = allOn,
}) => DealScorer.score(r, v, values ?? standard, components);

/// Points of [component] for [side] in [score].
int pts(DealScore score, Side side, ScoreComponent component) => score.items
    .where((i) => i.side == side && i.component == component)
    .fold(0, (s, i) => s + i.points);

const Side ns = Side.northSouth;
const Side ew = Side.eastWest;
