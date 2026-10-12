import 'package:bridge_scorekeeper/core/core.dart';
import 'package:bridge_scorekeeper/scoring/scoring.dart';
import 'package:bridge_scorekeeper/session/session.dart';

final Players players = Players({
  Seat.north: 'Alice',
  Seat.east: 'Bob',
  Seat.south: 'Carol',
  Seat.west: 'Dave',
});

SessionSettings settings({
  Seat firstDealer = Seat.north,
  EndRule endRule = const DealCountRule(16),
  bool bidding = false,
  ScoringComponents components = const ScoringComponents(honors: false),
  ScoringPreset preset = ScoringPreset.standard,
  ScoringValues? values,
}) => SessionSettings(
  players: players,
  firstDealer: firstDealer,
  endRule: endRule,
  biddingStep: bidding,
  components: components,
  preset: preset,
  values: values ?? ScoringValues.standard(),
);

final DateTime t0 = DateTime.utc(2026, 10, 11, 20);

SessionState newSession([SessionSettings? s]) =>
    SessionController.start(id: 's1', now: t0, settings: s ?? settings());

SessionState run(SessionState s, List<SessionCommand> commands) {
  var state = s;
  for (final c in commands) {
    state = SessionController.apply(state, c, now: t0);
  }
  return state;
}

ContractInput contract(String code, Seat declarer) {
  final doubling = code.endsWith('XX')
      ? Doubling.redoubled
      : code.endsWith('X')
      ? Doubling.doubled
      : Doubling.none;
  return ContractInput(
    level: int.parse(code.substring(0, 1)),
    strain: Strain.fromCode(code.substring(1, 2)),
    doubling: doubling,
    declarer: declarer,
  );
}

/// Plays one full deal with direct contract entry (bidding step off) and
/// moves on to the next deal unless the session ended.
SessionState playDeal(
  SessionState s,
  String code,
  Seat declarer, {
  int diff = 0,
  Honors? honors,
  bool next = true,
}) {
  final level = int.parse(code.substring(0, 1));
  var state = run(s, [
    const AdvanceFromStart(),
    SetContract(contract(code, declarer)),
    const ConfirmContract(),
    const FinishPlay(),
    SetTricks(level + 6 + diff),
    if (honors != null) SetHonors(honors),
    const ScoreDeal(),
  ]);
  if (next && !state.isEnded) {
    state = run(state, [const NextDeal()]);
  }
  return state;
}

SessionState passOut(SessionState s) =>
    run(s, [const AdvanceFromStart(), const PassOut()]);
