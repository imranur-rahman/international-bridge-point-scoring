## Purpose

Calculates the rubber bridge score for each deal and for each rubber from the session's scoring values: trick points, overtricks, undertricks (penalties), double and redouble, the insult bonus, slam bonuses, honors, games, the optional game bonus, vulnerability, rubber bonuses, and the unfinished rubber bonus.

## ADDED Requirements

### Requirement: Scoring values table
The scoring calculation SHALL use only the scoring values of the session. The session SHALL have 34 configurable values. The standard defaults SHALL be the values from the Laws of Contract Bridge for rubber bridge, plus a game bonus of 0. The "House rules" defaults SHALL be the same as the standard defaults, except for the honors values, the rubber bonuses, and the unfinished rubber bonuses:

| Value | Standard default | House rules default |
|---|---|---|
| Trick value, clubs or diamonds (each trick over 6) | 20 | 20 |
| Trick value, hearts or spades (each trick over 6) | 30 | 30 |
| Trick value, no trump, first trick over 6 | 40 | 40 |
| Trick value, no trump, each later trick | 30 | 30 |
| Double multiplier for contract trick points | 2 | 2 |
| Redouble multiplier for contract trick points | 4 | 4 |
| Game threshold (contract points below the line) | 100 | 100 |
| Overtrick, doubled, not vulnerable (each) | 100 | 100 |
| Overtrick, doubled, vulnerable (each) | 200 | 200 |
| Insult bonus, doubled contract fulfilled | 50 | 50 |
| Insult bonus, redoubled contract fulfilled | 100 | 100 |
| Small slam bonus, not vulnerable | 500 | 500 |
| Small slam bonus, vulnerable | 750 | 750 |
| Grand slam bonus, not vulnerable | 1000 | 1000 |
| Grand slam bonus, vulnerable | 1500 | 1500 |
| Undertrick, undoubled, not vulnerable (each) | 50 | 50 |
| Undertrick, undoubled, vulnerable (each) | 100 | 100 |
| Undertrick, doubled, not vulnerable: 1st / 2nd and 3rd (each) / 4th and later (each) | 100 / 200 / 300 | 100 / 200 / 300 |
| Undertrick, doubled, vulnerable: 1st / 2nd and 3rd (each) / 4th and later (each) | 200 / 300 / 300 | 200 / 300 / 300 |
| Honors, trump honors: 4 in one hand | 100 | 80 |
| Honors, trump honors: 5 in one hand | 150 | 100 |
| Honors, trump honors: each other honor of the majority side | 0 | 10 |
| Honors, aces at no trump: 4 in one hand | 150 | 80 |
| Honors, aces at no trump: each other ace of the majority side | 0 | 10 |
| Game bonus, for each game won, not vulnerable | 0 | 0 |
| Game bonus, for each game won, vulnerable | 0 | 0 |
| Rubber bonus, rubber won 2 games to 0 | 700 | 250 |
| Rubber bonus, rubber won 2 games to 1 | 500 | 250 |
| Unfinished rubber, one game won | 300 | 125 |
| Unfinished rubber, part-score in the unfinished game | 100 | 0 |

The redoubled overtrick values and the redoubled undertrick values SHALL not be configurable. Each one SHALL be 2 × the matching doubled value. With the standard defaults this gives: redoubled overtricks 200 not vulnerable and 400 vulnerable; redoubled undertricks 200 / 400 / 600 not vulnerable and 400 / 600 / 600 vulnerable.

All scenarios in this capability use the standard defaults, unless a scenario says otherwise.

#### Scenario: Changed value is used
- **WHEN** the session sets the trick value for hearts or spades to 35 and a side fulfills 2♠ undoubled
- **THEN** the side scores 70 contract points below the line

#### Scenario: Redoubled value follows the doubled value
- **WHEN** the session sets the doubled overtrick value, not vulnerable, to 150, and a side that is not vulnerable fulfills 1♠ redoubled with 1 overtrick
- **THEN** the side scores 300 for the overtrick

### Requirement: Contract points below the line
When the declarer fulfills the contract, the declaring side SHALL score contract points below the line. The contract points SHALL be the trick values of the contracted tricks over 6, multiplied by the double multiplier if the contract is doubled or by the redouble multiplier if it is redoubled. Only contract points SHALL go below the line.

#### Scenario: Minor suit part-score
- **WHEN** a side fulfills 3♦ undoubled
- **THEN** the side scores 60 below the line

#### Scenario: No trump game
- **WHEN** a side fulfills 3NT undoubled
- **THEN** the side scores 100 below the line

#### Scenario: Doubled contract
- **WHEN** a side fulfills 2♥ doubled
- **THEN** the side scores 120 below the line

#### Scenario: Redoubled contract
- **WHEN** a side fulfills 1NT redoubled
- **THEN** the side scores 160 below the line

### Requirement: Overtricks above the line
For each trick over the contract, the declaring side SHALL score above the line: the trick value of the denomination when undoubled (for no trump, the "each later trick" value), or the doubled overtrick value for the vulnerability of the declaring side when doubled, or 2 × that value when redoubled.

#### Scenario: Undoubled overtricks
- **WHEN** a side fulfills 2♠ undoubled and takes 10 tricks
- **THEN** the side scores 60 below the line and 60 above the line

#### Scenario: Doubled overtrick, vulnerable
- **WHEN** a vulnerable side fulfills 3♣ doubled and takes 10 tricks
- **THEN** the side scores 120 below the line, 200 for the overtrick and 50 insult bonus above the line

### Requirement: Insult bonus
When the declarer fulfills a doubled or redoubled contract, the declaring side SHALL score the matching insult bonus above the line.

#### Scenario: Redoubled contract fulfilled
- **WHEN** a side fulfills 2♦ redoubled with no overtricks
- **THEN** the side scores 160 below the line and 100 above the line

### Requirement: Slam bonuses
When the declarer fulfills a contract at level 6, the declaring side SHALL score the small slam bonus above the line. When the declarer fulfills a contract at level 7, the declaring side SHALL score the grand slam bonus above the line. The bonus SHALL use the vulnerability of the declaring side.

#### Scenario: Small slam not vulnerable
- **WHEN** a side that is not vulnerable fulfills 6♥
- **THEN** the side scores 180 below the line and 500 above the line

#### Scenario: Grand slam vulnerable
- **WHEN** a vulnerable side fulfills 7NT
- **THEN** the side scores 220 below the line and 1500 above the line

### Requirement: Undertrick penalties
When the declarer does not fulfill the contract, the defending side SHALL score the penalty for the undertricks above the line. The declaring side SHALL score nothing for tricks. The penalty SHALL use the vulnerability of the declaring side and the double state of the contract, and SHALL add the value of each undertrick by its position (1st, 2nd, 3rd, 4th, and later). For a redoubled contract, the value of each position SHALL be 2 × the doubled value of that position.

#### Scenario: Undoubled, not vulnerable
- **WHEN** a side that is not vulnerable goes down 2 in an undoubled contract
- **THEN** the defenders score 100 above the line

#### Scenario: Doubled, not vulnerable, down 4
- **WHEN** a side that is not vulnerable goes down 4 in a doubled contract
- **THEN** the defenders score 800 above the line (100 + 200 + 200 + 300)

#### Scenario: Doubled, vulnerable, down 3
- **WHEN** a vulnerable side goes down 3 in a doubled contract
- **THEN** the defenders score 800 above the line (200 + 300 + 300)

#### Scenario: Equal undertricks in House rules
- **WHEN** the session sets the doubled undertrick values, not vulnerable, to 100 / 100 / 100, and a side that is not vulnerable goes down 3 in a doubled contract
- **THEN** the defenders score 300 above the line (100 + 100 + 100), and 600 if the contract is redoubled

#### Scenario: Redoubled, vulnerable, down 1
- **WHEN** a vulnerable side goes down 1 in a redoubled contract
- **THEN** the defenders score 400 above the line

### Requirement: Honors
The honors SHALL be the A, K, Q, J, and 10 of the trump suit in a suit contract, and the four aces in a no trump contract. When honors are on, only the **majority side** SHALL score honors: the partnership that holds 3 or more of the 5 trump honors, or 3 or more of the 4 aces. When each side holds 2 aces, no side SHALL score honors.

The majority side SHALL score above the line:
- the "4 in one hand" value when one hand of the side holds exactly 4 honors (or 4 aces),
- the "5 in one hand" value when one hand of the side holds all 5 trump honors,
- plus the "each other honor" (or "each other ace") value for each honor that the side holds and that is not part of a 4 or 5 in one hand.

Honors SHALL score whether the contract is fulfilled or not, whether the majority side is the declaring side or the defending side, and with no change for vulnerability or for the double state.

With the standard defaults, the "each other" values are 0, so only 4 or 5 in one hand score, as the Laws define.

#### Scenario: Honors with a failed contract
- **WHEN** the declarer goes down 1 in 4♠ and the declaring side held 5 spade honors in one hand
- **THEN** the declaring side scores 150 for honors and the defenders score the penalty for 1 undertrick

#### Scenario: Aces at no trump
- **WHEN** the defenders held 4 aces in one hand in a 3NT contract
- **THEN** the defenders score 150 above the line

#### Scenario: Standard, honors split
- **WHEN** the session uses the standard defaults and the majority side holds 4 trump honors split 2 + 2
- **THEN** no side scores honors

#### Scenario: House rules, honors patterns in a suit contract
- **WHEN** the session uses the "House rules" defaults and the majority side holds these trump honors
- **THEN** the side scores: 3 honors (2 + 1 or 3 + 0) = 30; 4 split (2 + 2 or 3 + 1) = 40; 4 in one hand = 80; 5 split 3 + 2 = 50; 5 with 4 + 1 = 90; 5 in one hand = 100

#### Scenario: House rules, aces at no trump
- **WHEN** the session uses the "House rules" defaults in a no trump contract
- **THEN** the majority side scores: 3 aces = 30; 4 aces split = 40; 4 aces in one hand = 80; and with a 2 + 2 split of aces no side scores

#### Scenario: House rules, minority side
- **WHEN** the session uses the "House rules" defaults, N-S hold A K Q of trumps, and E-W hold J 10
- **THEN** N-S score 30 and E-W score no honors

### Requirement: Games and part-scores
A side SHALL win a game when its contract points below the line in the current game reach at least the game threshold, from one deal or from the total of several part-scores. When a side wins a game, the system SHALL draw a line under the current game. The part-scores of both sides from that game SHALL then not count toward the next game.

#### Scenario: Game from part-scores
- **WHEN** a side has 60 below the line in the current game and fulfills 2♣ (40)
- **THEN** the side wins a game, and the next game starts at 0 for both sides

#### Scenario: Opponent's part-score cancelled
- **WHEN** side A has 70 below the line in the current game and side B fulfills 4♥
- **THEN** side B wins the game, and side A's 70 does not count toward the next game

### Requirement: Game bonus
Each time a side wins a game, the system SHALL add the game bonus above the line for that side. The bonus SHALL use the vulnerability of the side before the deal in which it won the game. With the standard default of 0, the game bonus SHALL not show in the score.

#### Scenario: Game bonus with house rules
- **WHEN** the session sets the game bonus to 300 not vulnerable and 500 vulnerable, and a side that is not vulnerable fulfills 4♥
- **THEN** the side scores 120 below the line and 300 game bonus above the line

#### Scenario: Game bonus on the game that completes the rubber
- **WHEN** the session sets the game bonus to 300 not vulnerable and 500 vulnerable, and a vulnerable side wins its second game while the opponents have no game
- **THEN** the side scores 500 game bonus and 700 rubber bonus above the line

#### Scenario: Standard game bonus
- **WHEN** the session uses the standard defaults and a side wins a game
- **THEN** the score shows no game bonus

### Requirement: Vulnerability
A side SHALL be vulnerable when it won one game in the current rubber. A side that won no game in the current rubber SHALL be not vulnerable. At the start of each rubber, both sides SHALL be not vulnerable.

#### Scenario: Vulnerable after first game
- **WHEN** side A wins its first game in the rubber
- **THEN** side A is vulnerable for the next deal, and side B stays not vulnerable

### Requirement: Rubber completion and bonus
A rubber SHALL complete when a side wins its second game. That side SHALL score the rubber bonus above the line: the 2–0 value if the opponents won no game, or the 2–1 value if the opponents won one game. If the end rule does not apply after this deal, the system SHALL start a new rubber with no games and no vulnerability for both sides.

#### Scenario: Rubber 2–0
- **WHEN** a side wins its second game and the opponents won no game
- **THEN** the side scores 700 above the line, and a new rubber starts

#### Scenario: Rubber 2–1
- **WHEN** a side wins its second game and the opponents won one game
- **THEN** the side scores 500 above the line

#### Scenario: Full rubber with a clean slate after it
- **WHEN** side A wins a game on deal 1, side B wins a game on deal 2, and side A wins a game on deal 3
- **THEN** after deal 2 both sides are vulnerable, after deal 3 side A scores 500 above the line, and deal 4 starts a new rubber with no games, no part-scores, and no vulnerability for both sides

#### Scenario: House rules rubber bonus
- **WHEN** the session uses the "House rules" defaults and a side wins a rubber 2–0 or 2–1
- **THEN** the side scores 250 above the line

### Requirement: Unfinished rubber bonus
When the session ends during a rubber and the unfinished rubber bonus is on, the system SHALL add above the line:
- the "one game won" value for a side that won one game in the unfinished rubber, when the other side won no game,
- the "part-score" value for each side that has a part-score in the current unfinished game.

#### Scenario: One game and a part-score
- **WHEN** the session ends, side A won one game in the rubber, side B won none, and side B has 40 below the line in the current game
- **THEN** side A scores 300 and side B scores 100 above the line

#### Scenario: House rules unfinished rubber
- **WHEN** the session uses the "House rules" defaults and ends, side A won one game in the rubber, side B won none, and side B has 40 below the line in the current game
- **THEN** side A scores 125 and side B scores no unfinished rubber bonus

#### Scenario: One game each
- **WHEN** the session ends and each side won one game in the rubber, with no part-score in the current game
- **THEN** neither side scores an unfinished rubber bonus

### Requirement: Session total
The session total of a side SHALL be the sum of all its points above and below the line in all rubbers of the session, including game bonuses, rubber bonuses, and, at the end, the unfinished rubber bonus. The target score end rule SHALL use the session total without the unfinished rubber bonus.

#### Scenario: Total over two rubbers
- **WHEN** side A scored 1200 in rubber 1 and 450 in rubber 2
- **THEN** the session total of side A is 1650

### Requirement: Deterministic recalculation
The scoring result SHALL depend only on the scoring values and the ordered list of recorded deals. Calculating the same list again SHALL give the same scores, games, vulnerabilities, and rubbers.

#### Scenario: Recalculation after edit
- **WHEN** the user changes the result of deal 2 out of 5 recorded deals
- **THEN** the system calculates deals 2 to 5 again, including the vulnerability and the games of each deal, from the changed list
