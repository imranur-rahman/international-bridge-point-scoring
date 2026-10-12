import '../../../core/core.dart';
import '../../../scoring/scoring.dart';
import '../../../session/session.dart';

/// The example players of every demo.
final Players demoPlayers = Players({
  Seat.north: 'Alice',
  Seat.east: 'Bob',
  Seat.south: 'Carol',
  Seat.west: 'Dave',
});

/// One deal of a demo, with one line of text about it.
class DemoStep {
  const DemoStep(this.result, this.text);

  final DealResult? result;
  final String text;
}

/// A scripted mini game that shows one scoring value in action.
class ScoringDemo {
  const ScoringDemo({
    required this.field,
    required this.steps,
    required this.highlight,
    this.endsSession = false,
  });

  final ScoringField field;
  final List<DemoStep> steps;

  /// The score component that the demonstrated value adds to.
  final ScoreComponent highlight;

  /// True when the value applies at the session end (unfinished rubber).
  final bool endsSession;

  /// The replay of the first [count] deals with [values].
  LedgerSnapshot replay(int count, ScoringValues values) => RubberLedger.replay(
    [for (final s in steps.take(count)) s.result],
    values,
    const ScoringComponents(),
  );

  /// The unfinished rubber bonus that the last step shows, or nothing.
  List<ScoreItem> sessionEndItems(int step, ScoringValues values) =>
      endsSession && step == steps.length
      ? replay(step, values).unfinishedRubberBonus()
      : const [];
}

DealResult _deal(String code, Seat declarer, {int diff = 0, Honors? honors}) {
  final doubling = code.endsWith('XX')
      ? Doubling.redoubled
      : code.endsWith('X')
      ? Doubling.doubled
      : Doubling.none;
  final level = int.parse(code.substring(0, 1));
  return DealResult(
    contract: Contract(
      bid: Bid(level, Strain.fromCode(code.substring(1, 2))),
      doubling: doubling,
      declarer: declarer,
    ),
    tricksTaken: level + 6 + diff,
    honors: honors,
  );
}

const Seat _carol = Seat.south;
const Seat _alice = Seat.north;
const Seat _bob = Seat.east;

/// A game for Alice & Carol with the standard values.
final DemoStep _acGame = DemoStep(
  _deal('4S', _carol),
  'Carol fulfills 4♠, usually a game for Alice & Carol.',
);

/// A game for Bob & Dave with the standard values.
final DemoStep _bdGame = DemoStep(
  _deal('4H', _bob),
  'Bob fulfills 4♥, usually a game for Bob & Dave.',
);

DemoStep _doubledDown(int down) => DemoStep(
  _deal('4SX', _bob, diff: -down),
  'Bob plays 4♠ doubled and goes down $down. Alice & Carol score the '
  'penalty for each undertrick by its position.',
);

/// One demo for each of the 34 scoring values.
final Map<ScoringField, ScoringDemo> scoringDemos = {
  ScoringField.minorTrick: ScoringDemo(
    field: ScoringField.minorTrick,
    highlight: ScoreComponent.contractPoints,
    steps: [
      DemoStep(
        _deal('3D', _carol),
        'Carol fulfills 3♦. Each of the 3 tricks over 6 scores the ♦ trick '
        'value below the line.',
      ),
    ],
  ),
  ScoringField.majorTrick: ScoringDemo(
    field: ScoringField.majorTrick,
    highlight: ScoreComponent.contractPoints,
    steps: [
      DemoStep(
        _deal('2S', _carol),
        'Carol fulfills 2♠. Each of the 2 tricks over 6 scores the ♠ trick '
        'value below the line.',
      ),
    ],
  ),
  ScoringField.noTrumpFirstTrick: ScoringDemo(
    field: ScoringField.noTrumpFirstTrick,
    highlight: ScoreComponent.contractPoints,
    steps: [
      DemoStep(
        _deal('1N', _carol),
        'Carol fulfills 1NT. The first trick over 6 in no trump scores this '
        'value below the line.',
      ),
    ],
  ),
  ScoringField.noTrumpLaterTrick: ScoringDemo(
    field: ScoringField.noTrumpLaterTrick,
    highlight: ScoreComponent.contractPoints,
    steps: [
      DemoStep(
        _deal('3N', _carol),
        'Carol fulfills 3NT: the first trick over 6, plus 2 later tricks '
        'at this value. That is often exactly a game.',
      ),
    ],
  ),
  ScoringField.doubleMultiplier: ScoringDemo(
    field: ScoringField.doubleMultiplier,
    highlight: ScoreComponent.contractPoints,
    steps: [
      DemoStep(
        _deal('2HX', _carol),
        'Carol fulfills 2♥ doubled. The contract points are multiplied, so '
        'a part-score can become a game.',
      ),
    ],
  ),
  ScoringField.redoubleMultiplier: ScoringDemo(
    field: ScoringField.redoubleMultiplier,
    highlight: ScoreComponent.contractPoints,
    steps: [
      DemoStep(
        _deal('2HXX', _carol),
        'Carol fulfills 2♥ redoubled. The contract points are multiplied '
        'by the redouble value.',
      ),
    ],
  ),
  ScoringField.overtrickDoubledNotVulnerable: ScoringDemo(
    field: ScoringField.overtrickDoubledNotVulnerable,
    highlight: ScoreComponent.overtricks,
    steps: [
      DemoStep(
        _deal('2SX', _carol, diff: 1),
        'Carol plays 2♠ doubled and takes 1 trick more. The overtrick value '
        'depends on whether Alice & Carol are vulnerable.',
      ),
    ],
  ),
  ScoringField.overtrickDoubledVulnerable: ScoringDemo(
    field: ScoringField.overtrickDoubledVulnerable,
    highlight: ScoreComponent.overtricks,
    steps: [
      _acGame,
      DemoStep(
        _deal('2SX', _carol, diff: 1),
        'Carol plays 2♠ doubled again and takes 1 trick more, now after a '
        'game for Alice & Carol.',
      ),
    ],
  ),
  ScoringField.insultDoubled: ScoringDemo(
    field: ScoringField.insultDoubled,
    highlight: ScoreComponent.insultBonus,
    steps: [
      DemoStep(
        _deal('2HX', _carol),
        'Bob doubles, but Carol fulfills 2♥ doubled. Alice & Carol get the '
        'insult bonus above the line.',
      ),
    ],
  ),
  ScoringField.insultRedoubled: ScoringDemo(
    field: ScoringField.insultRedoubled,
    highlight: ScoreComponent.insultBonus,
    steps: [
      DemoStep(
        _deal('2HXX', _carol),
        'Bob doubles, Alice redoubles, and Carol fulfills 2♥ redoubled. '
        'Alice & Carol get the redoubled insult bonus.',
      ),
    ],
  ),
  ScoringField.gameThreshold: ScoringDemo(
    field: ScoringField.gameThreshold,
    highlight: ScoreComponent.contractPoints,
    steps: [
      DemoStep(
        _deal('2S', _carol),
        'Carol fulfills 2♠: a part-score below the line.',
      ),
      DemoStep(
        _deal('2C', _alice),
        'Alice fulfills 2♣. The points below the line in this game add up. A '
        'side wins a game when they reach the game threshold.',
      ),
    ],
  ),
  ScoringField.gameBonusNotVulnerable: ScoringDemo(
    field: ScoringField.gameBonusNotVulnerable,
    highlight: ScoreComponent.gameBonus,
    steps: [
      DemoStep(
        _deal('4H', _bob),
        'Bob fulfills 4♥, usually a game. A side that wins a game while not '
        'vulnerable gets this game bonus above the line.',
      ),
    ],
  ),
  ScoringField.gameBonusVulnerable: ScoringDemo(
    field: ScoringField.gameBonusVulnerable,
    highlight: ScoreComponent.gameBonus,
    steps: [
      _bdGame,
      DemoStep(
        _deal('4H', _bob),
        'Bob fulfills 4♥ again. A side that wins a game while vulnerable gets '
        'this game bonus.',
      ),
    ],
  ),
  ScoringField.smallSlamNotVulnerable: ScoringDemo(
    field: ScoringField.smallSlamNotVulnerable,
    highlight: ScoreComponent.slamBonus,
    steps: [
      DemoStep(
        _deal('6H', _carol),
        'Carol bids and fulfills 6♥, a small slam.',
      ),
    ],
  ),
  ScoringField.smallSlamVulnerable: ScoringDemo(
    field: ScoringField.smallSlamVulnerable,
    highlight: ScoreComponent.slamBonus,
    steps: [
      _acGame,
      DemoStep(
        _deal('6H', _carol),
        'Carol bids and fulfills 6♥, a small slam, after a game for Alice & '
        'Carol.',
      ),
    ],
  ),
  ScoringField.grandSlamNotVulnerable: ScoringDemo(
    field: ScoringField.grandSlamNotVulnerable,
    highlight: ScoreComponent.slamBonus,
    steps: [
      DemoStep(
        _deal('7C', _carol),
        'Carol bids and fulfills 7♣, a grand slam: all 13 tricks.',
      ),
    ],
  ),
  ScoringField.grandSlamVulnerable: ScoringDemo(
    field: ScoringField.grandSlamVulnerable,
    highlight: ScoreComponent.slamBonus,
    steps: [
      _acGame,
      DemoStep(
        _deal('7N', _carol),
        'Carol bids and fulfills 7NT, a grand slam, after a game for Alice & '
        'Carol.',
      ),
    ],
  ),
  ScoringField.undertrickUndoubledNotVulnerable: ScoringDemo(
    field: ScoringField.undertrickUndoubledNotVulnerable,
    highlight: ScoreComponent.undertricks,
    steps: [
      DemoStep(
        _deal('4S', _bob, diff: -2),
        'Bob plays 4♠ and goes down 2. Alice & Carol score the penalty for '
        'each undertrick.',
      ),
    ],
  ),
  ScoringField.undertrickUndoubledVulnerable: ScoringDemo(
    field: ScoringField.undertrickUndoubledVulnerable,
    highlight: ScoreComponent.undertricks,
    steps: [
      _bdGame,
      DemoStep(
        _deal('4S', _bob, diff: -2),
        'Bob plays 4♠ and goes down 2, now after a game for Bob & Dave. Alice '
        '& Carol score the penalty for each undertrick.',
      ),
    ],
  ),
  ScoringField.undertrickDoubledNotVulnerableFirst: ScoringDemo(
    field: ScoringField.undertrickDoubledNotVulnerableFirst,
    highlight: ScoreComponent.undertricks,
    steps: [_doubledDown(1)],
  ),
  ScoringField.undertrickDoubledNotVulnerableSecondThird: ScoringDemo(
    field: ScoringField.undertrickDoubledNotVulnerableSecondThird,
    highlight: ScoreComponent.undertricks,
    steps: [_doubledDown(3)],
  ),
  ScoringField.undertrickDoubledNotVulnerableFourthOn: ScoringDemo(
    field: ScoringField.undertrickDoubledNotVulnerableFourthOn,
    highlight: ScoreComponent.undertricks,
    steps: [_doubledDown(4)],
  ),
  ScoringField.undertrickDoubledVulnerableFirst: ScoringDemo(
    field: ScoringField.undertrickDoubledVulnerableFirst,
    highlight: ScoreComponent.undertricks,
    steps: [_bdGame, _doubledDown(1)],
  ),
  ScoringField.undertrickDoubledVulnerableSecondThird: ScoringDemo(
    field: ScoringField.undertrickDoubledVulnerableSecondThird,
    highlight: ScoreComponent.undertricks,
    steps: [_bdGame, _doubledDown(3)],
  ),
  ScoringField.undertrickDoubledVulnerableFourthOn: ScoringDemo(
    field: ScoringField.undertrickDoubledVulnerableFourthOn,
    highlight: ScoreComponent.undertricks,
    steps: [_bdGame, _doubledDown(4)],
  ),
  ScoringField.honorsFourInOneHand: ScoringDemo(
    field: ScoringField.honorsFourInOneHand,
    highlight: ScoreComponent.honors,
    steps: [
      DemoStep(
        _deal(
          '4H',
          _bob,
          diff: -1,
          honors: const Honors(HonorsHolding.fourInOneHand, Side.eastWest),
        ),
        'Bob plays 4♥ and goes down 1, but he holds A K Q J of hearts. Bob & '
        'Dave still score honors.',
      ),
    ],
  ),
  ScoringField.honorsFiveInOneHand: ScoringDemo(
    field: ScoringField.honorsFiveInOneHand,
    highlight: ScoreComponent.honors,
    steps: [
      DemoStep(
        _deal(
          '4H',
          _carol,
          honors: const Honors(HonorsHolding.fiveInOneHand, Side.eastWest),
        ),
        'Carol fulfills 4♥, but Dave, a defender, holds all 5 heart honors. '
        'Bob & Dave score honors.',
      ),
    ],
  ),
  ScoringField.honorsEachOther: ScoringDemo(
    field: ScoringField.honorsEachOther,
    highlight: ScoreComponent.honors,
    steps: [
      DemoStep(
        _deal(
          '4H',
          _bob,
          honors: const Honors(HonorsHolding.fourPlusOne, Side.eastWest),
        ),
        'Bob fulfills 4♥. Bob holds 4 heart honors and Dave holds the 5th. '
        'The 5th honor scores this value.',
      ),
    ],
  ),
  ScoringField.acesFourInOneHand: ScoringDemo(
    field: ScoringField.acesFourInOneHand,
    highlight: ScoreComponent.honors,
    steps: [
      DemoStep(
        _deal(
          '3N',
          _carol,
          honors: const Honors(
            HonorsHolding.fourAcesInOneHand,
            Side.northSouth,
          ),
        ),
        'Carol fulfills 3NT and holds all 4 aces. At no trump, the aces are '
        'the honors.',
      ),
    ],
  ),
  ScoringField.acesEachOther: ScoringDemo(
    field: ScoringField.acesEachOther,
    highlight: ScoreComponent.honors,
    steps: [
      DemoStep(
        _deal(
          '3N',
          _carol,
          honors: const Honors(HonorsHolding.threeAces, Side.northSouth),
        ),
        'Carol fulfills 3NT. Alice & Carol hold 3 of the 4 aces, so each '
        'ace scores this value.',
      ),
    ],
  ),
  ScoringField.rubberTwoNil: ScoringDemo(
    field: ScoringField.rubberTwoNil,
    highlight: ScoreComponent.rubberBonus,
    steps: [
      _acGame,
      DemoStep(
        _deal('3N', _alice),
        'Alice fulfills 3NT, usually a second game for Alice & Carol before '
        'Bob & Dave win one.',
      ),
    ],
  ),
  ScoringField.rubberTwoOne: ScoringDemo(
    field: ScoringField.rubberTwoOne,
    highlight: ScoreComponent.rubberBonus,
    steps: [
      _acGame,
      DemoStep(
        _deal('4H', _bob),
        'Bob fulfills 4♥, usually a game for Bob & Dave too.',
      ),
      DemoStep(
        _deal('3N', _carol),
        'Carol fulfills 3NT, usually the deciding game of the rubber.',
      ),
    ],
  ),
  ScoringField.unfinishedOneGame: ScoringDemo(
    field: ScoringField.unfinishedOneGame,
    highlight: ScoreComponent.unfinishedRubber,
    endsSession: true,
    steps: [
      DemoStep(
        _deal('4S', _carol),
        'Carol fulfills 4♠, usually a game. Then the session ends before the '
        'rubber is complete.',
      ),
    ],
  ),
  ScoringField.unfinishedPartScore: ScoringDemo(
    field: ScoringField.unfinishedPartScore,
    highlight: ScoreComponent.unfinishedRubber,
    endsSession: true,
    steps: [
      DemoStep(
        _deal('2D', _bob),
        'Bob fulfills 2♦: a part-score. Then the session ends during this '
        'game.',
      ),
    ],
  ),
};
