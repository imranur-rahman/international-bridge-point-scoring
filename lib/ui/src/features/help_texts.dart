import '../../../scoring/scoring.dart';

/// The help text of one scoring value.
class HelpText {
  const HelpText({
    required this.title,
    required this.meaning,
    required this.applies,
    required this.example,
  });

  final String title;
  final String meaning;
  final String applies;
  final String example;

  /// The short version for the hover tooltip.
  String get short => meaning;
}

/// The help for the values that the user cannot change.
const HelpText redoubledHelp = HelpText(
  title: 'Redoubled overtricks and undertricks',
  meaning:
      'Redoubled overtricks and redoubled undertricks are always 2 × the '
      'doubled values. You cannot set them separately.',
  applies: 'Only when the contract is redoubled.',
  example: 'Doubled, not vulnerable, 1st undertrick = 100, so redoubled = 200.',
);

/// One help text for each of the 34 scoring values.
const Map<ScoringField, HelpText> helpTexts = {
  ScoringField.minorTrick: HelpText(
    title: 'Trick value, ♣ or ♦',
    meaning:
        'Points for each trick over 6 that the contract names in clubs or '
        'diamonds. They go below the line.',
    applies: 'When the declarer fulfills a ♣ or ♦ contract.',
    example: '3♦ fulfilled: 3 × 20 = 60 below the line.',
  ),
  ScoringField.majorTrick: HelpText(
    title: 'Trick value, ♥ or ♠',
    meaning:
        'Points for each trick over 6 that the contract names in hearts or '
        'spades. They go below the line.',
    applies: 'When the declarer fulfills a ♥ or ♠ contract.',
    example: '4♠ fulfilled: 4 × 30 = 120 below the line (a game).',
  ),
  ScoringField.noTrumpFirstTrick: HelpText(
    title: 'Trick value, no trump, first trick',
    meaning: 'Points for the first trick over 6 in a no trump contract.',
    applies: 'When the declarer fulfills a no trump contract.',
    example: '1NT fulfilled: 40 below the line.',
  ),
  ScoringField.noTrumpLaterTrick: HelpText(
    title: 'Trick value, no trump, each later trick',
    meaning:
        'Points for each trick after the first trick over 6 in a no trump '
        'contract. Undoubled no trump overtricks also use this value.',
    applies: 'When the declarer fulfills a no trump contract.',
    example: '3NT fulfilled: 40 + 30 + 30 = 100 below the line.',
  ),
  ScoringField.doubleMultiplier: HelpText(
    title: 'Doubled contract points',
    meaning: 'The contract points are multiplied by this value when doubled.',
    applies: 'When the declarer fulfills a doubled contract.',
    example: '2♥ doubled, fulfilled: 60 × 2 = 120 below the line.',
  ),
  ScoringField.redoubleMultiplier: HelpText(
    title: 'Redoubled contract points',
    meaning: 'The contract points are multiplied by this value when redoubled.',
    applies: 'When the declarer fulfills a redoubled contract.',
    example: '1NT redoubled, fulfilled: 40 × 4 = 160 below the line.',
  ),
  ScoringField.overtrickDoubledNotVulnerable: HelpText(
    title: 'Doubled overtrick, not vulnerable',
    meaning: 'Points for each overtrick when the contract is doubled.',
    applies:
        'Only when the contract is doubled and the declaring side is not '
        'vulnerable. Redoubled = 2 × this value.',
    example: '2♠ doubled, 1 overtrick: 100 above the line.',
  ),
  ScoringField.overtrickDoubledVulnerable: HelpText(
    title: 'Doubled overtrick, vulnerable',
    meaning: 'Points for each overtrick when the contract is doubled.',
    applies:
        'Only when the contract is doubled and the declaring side is '
        'vulnerable. Redoubled = 2 × this value.',
    example: '3♣ doubled, vulnerable, 1 overtrick: 200 above the line.',
  ),
  ScoringField.insultDoubled: HelpText(
    title: 'Insult bonus, doubled',
    meaning:
        'A bonus for the declaring side when it fulfills a doubled '
        'contract.',
    applies:
        'When a doubled contract is fulfilled. Vulnerability does not '
        'matter.',
    example: '2♥ doubled, fulfilled: 120 below and 50 above the line.',
  ),
  ScoringField.insultRedoubled: HelpText(
    title: 'Insult bonus, redoubled',
    meaning:
        'A bonus for the declaring side when it fulfills a redoubled '
        'contract.',
    applies: 'When a redoubled contract is fulfilled.',
    example: '2♦ redoubled, fulfilled: 160 below and 100 above the line.',
  ),
  ScoringField.gameThreshold: HelpText(
    title: 'Game threshold',
    meaning:
        'A side wins a game when its points below the line in the current '
        'game reach this value. Then both sides start the next game at 0.',
    applies: 'After each fulfilled contract.',
    example: '2♠ (60) then 2♣ (40): 100, so the side wins a game.',
  ),
  ScoringField.gameBonusNotVulnerable: HelpText(
    title: 'Game bonus, not vulnerable',
    meaning:
        'A bonus above the line for each game that a side wins. The Laws '
        'have no game bonus, so the standard value is 0.',
    applies: 'When a side that is not vulnerable wins a game.',
    example: 'With 300: 4♥ fulfilled gives 120 below and 300 above the line.',
  ),
  ScoringField.gameBonusVulnerable: HelpText(
    title: 'Game bonus, vulnerable',
    meaning:
        'A bonus above the line for each game that a vulnerable side wins. '
        'The standard value is 0.',
    applies: 'When a vulnerable side wins a game.',
    example: 'With 500: the second game gives 500 plus the rubber bonus.',
  ),
  ScoringField.smallSlamNotVulnerable: HelpText(
    title: 'Small slam, not vulnerable',
    meaning: 'A bonus for a fulfilled contract at the 6 level.',
    applies: 'When the declaring side is not vulnerable.',
    example: '6♥ fulfilled: 180 below and 500 above the line.',
  ),
  ScoringField.smallSlamVulnerable: HelpText(
    title: 'Small slam, vulnerable',
    meaning: 'A bonus for a fulfilled contract at the 6 level.',
    applies: 'When the declaring side is vulnerable.',
    example: '6♠ fulfilled, vulnerable: 180 below and 750 above the line.',
  ),
  ScoringField.grandSlamNotVulnerable: HelpText(
    title: 'Grand slam, not vulnerable',
    meaning: 'A bonus for a fulfilled contract at the 7 level.',
    applies: 'When the declaring side is not vulnerable.',
    example: '7♣ fulfilled: 140 below and 1000 above the line.',
  ),
  ScoringField.grandSlamVulnerable: HelpText(
    title: 'Grand slam, vulnerable',
    meaning: 'A bonus for a fulfilled contract at the 7 level.',
    applies: 'When the declaring side is vulnerable.',
    example: '7NT fulfilled, vulnerable: 220 below and 1500 above the line.',
  ),
  ScoringField.undertrickUndoubledNotVulnerable: HelpText(
    title: 'Undertrick, undoubled, not vulnerable',
    meaning:
        'The penalty for each trick that the declarer is short. The '
        'defenders score it above the line.',
    applies:
        'When an undoubled contract fails and the declaring side is not '
        'vulnerable.',
    example: '4♠, down 2: 50 + 50 = 100 for the defenders.',
  ),
  ScoringField.undertrickUndoubledVulnerable: HelpText(
    title: 'Undertrick, undoubled, vulnerable',
    meaning: 'The penalty for each trick that the declarer is short.',
    applies:
        'When an undoubled contract fails and the declaring side is '
        'vulnerable.',
    example: '4♠ vulnerable, down 2: 100 + 100 = 200 for the defenders.',
  ),
  ScoringField.undertrickDoubledNotVulnerableFirst: HelpText(
    title: 'Undertrick, doubled, not vulnerable, 1st',
    meaning:
        'The penalty for the first trick that the declarer is short, when '
        'the contract is doubled.',
    applies:
        'Only when the contract is doubled and the declaring side is not '
        'vulnerable. Standard values: 100 / 200 / 300.',
    example: '4♠ doubled, down 3: 100 + 200 + 200 = 500 for the defenders.',
  ),
  ScoringField.undertrickDoubledNotVulnerableSecondThird: HelpText(
    title: 'Undertrick, doubled, not vulnerable, 2nd and 3rd',
    meaning: 'The penalty for the 2nd and for the 3rd undertrick, each.',
    applies:
        'Only when the contract is doubled and the declaring side is not '
        'vulnerable. Set all three positions equal to count each undertrick '
        'equally.',
    example: '4♠ doubled, down 3: 100 + 200 + 200 = 500 for the defenders.',
  ),
  ScoringField.undertrickDoubledNotVulnerableFourthOn: HelpText(
    title: 'Undertrick, doubled, not vulnerable, 4th and later',
    meaning: 'The penalty for each undertrick from the 4th.',
    applies:
        'Only when the contract is doubled and the declaring side is not '
        'vulnerable.',
    example: '4♠ doubled, down 4: 100 + 200 + 200 + 300 = 800.',
  ),
  ScoringField.undertrickDoubledVulnerableFirst: HelpText(
    title: 'Undertrick, doubled, vulnerable, 1st',
    meaning:
        'The penalty for the first trick that the declarer is short, when '
        'the contract is doubled.',
    applies:
        'Only when the contract is doubled and the declaring side is '
        'vulnerable. Standard values: 200 / 300 / 300.',
    example: '4♠ doubled, vulnerable, down 1: 200 for the defenders.',
  ),
  ScoringField.undertrickDoubledVulnerableSecondThird: HelpText(
    title: 'Undertrick, doubled, vulnerable, 2nd and 3rd',
    meaning: 'The penalty for the 2nd and for the 3rd undertrick, each.',
    applies:
        'Only when the contract is doubled and the declaring side is '
        'vulnerable.',
    example: '4♠ doubled, vulnerable, down 3: 200 + 300 + 300 = 800.',
  ),
  ScoringField.undertrickDoubledVulnerableFourthOn: HelpText(
    title: 'Undertrick, doubled, vulnerable, 4th and later',
    meaning: 'The penalty for each undertrick from the 4th.',
    applies:
        'Only when the contract is doubled and the declaring side is '
        'vulnerable.',
    example: '4♠ doubled, vulnerable, down 4: 200 + 300 + 300 + 300 = 1100.',
  ),
  ScoringField.honorsFourInOneHand: HelpText(
    title: '4 trump honors in one hand',
    meaning:
        'The honors are the A, K, Q, J, and 10 of trumps. This value is for '
        'one hand that holds 4 of them.',
    applies:
        'Only the side with 3 or more honors scores. It scores whether the '
        'contract is fulfilled or not.',
    example: '4♥, Bob holds A K Q J of hearts: Bob & Dave score this value.',
  ),
  ScoringField.honorsFiveInOneHand: HelpText(
    title: '5 trump honors in one hand',
    meaning: 'For one hand that holds all 5 trump honors.',
    applies: 'Suit contracts. Vulnerability and doubles do not matter.',
    example: '4♠ down 1 with all 5 spade honors in one hand: still scores.',
  ),
  ScoringField.honorsEachOther: HelpText(
    title: 'Each other honor of the majority side',
    meaning:
        'Points for each trump honor of the side with 3 or more honors that '
        'is not part of a 4 or 5 in one hand. The Laws give 0.',
    applies: 'Suit contracts, majority side only.',
    example: 'With 10: 3 honors = 30; 4 split = 40; 4 + 1 = 80 + 10 = 90.',
  ),
  ScoringField.acesFourInOneHand: HelpText(
    title: '4 aces in one hand (no trump)',
    meaning: 'For one hand that holds all 4 aces in a no trump contract.',
    applies: 'No trump contracts only.',
    example: '3NT, the defenders hold 4 aces in one hand: they score it.',
  ),
  ScoringField.acesEachOther: HelpText(
    title: 'Each other ace of the majority side (no trump)',
    meaning:
        'Points for each ace of the side with 3 or more aces that is not '
        'part of 4 aces in one hand. The Laws give 0.',
    applies: 'No trump contracts. A 2 + 2 split of aces scores nothing.',
    example: 'With 10: 3 aces = 30; 4 aces split = 40.',
  ),
  ScoringField.rubberTwoNil: HelpText(
    title: 'Rubber bonus, 2 games to 0',
    meaning:
        'The first side to win 2 games wins the rubber. This bonus applies '
        'when the opponents won no game.',
    applies: 'When a side wins its second game of the rubber.',
    example: 'Game, then game: the side scores this bonus above the line.',
  ),
  ScoringField.rubberTwoOne: HelpText(
    title: 'Rubber bonus, 2 games to 1',
    meaning: 'The rubber bonus when the opponents won one game.',
    applies: 'When a side wins its second game and the opponents have one.',
    example: 'A game, B game, A game: A scores this bonus.',
  ),
  ScoringField.unfinishedOneGame: HelpText(
    title: 'Unfinished rubber, one game won',
    meaning:
        'When the session ends during a rubber, a side that won one game '
        '(while the opponents won none) scores this bonus.',
    applies: 'Only at the session end, and only if the bonus is on.',
    example: 'Session ends with A at 1 game, B at 0: A scores this bonus.',
  ),
  ScoringField.unfinishedPartScore: HelpText(
    title: 'Unfinished rubber, part-score',
    meaning:
        'When the session ends during a game, each side with a part-score '
        'in that game scores this bonus.',
    applies: 'Only at the session end, and only if the bonus is on.',
    example: 'Session ends with B at 40 below the line: B scores this bonus.',
  ),
};
