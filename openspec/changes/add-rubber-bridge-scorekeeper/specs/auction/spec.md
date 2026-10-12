## Purpose

Lets the players record the calls of the auction (optional), with turn order, legal calls only, and automatic detection of the final contract, the declarer, and a passed-out deal.

## ADDED Requirements

### Requirement: Table view of players
During the auction, the system SHALL show the four players in their seats around a table (North at the top, East at the right, South at the bottom, West at the left). The system SHALL mark the dealer and SHALL highlight the player whose turn it is.

#### Scenario: Turn highlight
- **WHEN** Bob (East) is the dealer and the auction starts
- **THEN** the system highlights Bob as the player to call

### Requirement: Turn order
The first call SHALL belong to the dealer. Each later call SHALL belong to the next player clockwise.

#### Scenario: Clockwise turns
- **WHEN** the dealer is South and South makes a call
- **THEN** the next call belongs to West

### Requirement: Call history
The system SHALL show all calls of the auction in a grid with one column per seat (West, North, East, South), in call order.

#### Scenario: History grid
- **WHEN** North opens 1♣ and East passes
- **THEN** the grid shows "1♣" in the North column and "Pass" in the East column of the same round

### Requirement: Legal bids only
The system SHALL accept a bid (level 1 to 7 and denomination) only when it is higher than the last bid of the auction. The rank of denominations from lowest to highest SHALL be clubs, diamonds, hearts, spades, no trump. A bid is higher when its level is higher, or when its level is the same and its denomination ranks higher. The system SHALL disable the bids that are not legal.

#### Scenario: Lower bid is not legal
- **WHEN** the last bid is 2♥
- **THEN** the system disables 1♣ to 2♥ and enables 2♠ and higher

### Requirement: Legal double and redouble
The system SHALL accept "Double" only when the last call that is not a pass is a bid made by an opponent of the player to call. The system SHALL accept "Redouble" only when the last call that is not a pass is a double made by an opponent of the player to call. "Pass" SHALL always be legal.

#### Scenario: Double of partner's bid
- **WHEN** North bid 1♠, East passed, and South is to call
- **THEN** "Double" is disabled for South

#### Scenario: Double of opponent's bid
- **WHEN** North bid 1♠ and East is to call
- **THEN** "Double" is enabled for East

#### Scenario: Redouble after double
- **WHEN** North bid 1♠, East doubled, and South is to call
- **THEN** "Redouble" is enabled for South

#### Scenario: Second double is not legal
- **WHEN** North bid 1♠, East doubled, South passed, and West is to call
- **THEN** "Double" is disabled for West

### Requirement: End of auction
The auction SHALL end when three passes in a row follow a bid, a double, or a redouble. If the first four calls are all passes, the system SHALL end the auction as a passed-out deal.

#### Scenario: Contract reached
- **WHEN** the calls are 1NT, Pass, 3NT, Pass, Pass, Pass
- **THEN** the auction ends and the final contract is 3NT

#### Scenario: Passed out
- **WHEN** the first four calls are Pass, Pass, Pass, Pass
- **THEN** the auction ends and the system records a passed-out deal

### Requirement: Final contract and declarer
At the end of the auction, the system SHALL set the final contract to the last bid, with the double state from the doubles and redoubles that follow that bid. The declarer SHALL be the player of the side that made the last bid who first bid the denomination of the final contract.

#### Scenario: Declarer is first to name the denomination
- **WHEN** North bid 1♥, South bid 4♥, and three passes follow
- **THEN** the contract is 4♥ and the declarer is North

#### Scenario: Doubled contract
- **WHEN** West bid 2♠, North doubled, and three passes follow
- **THEN** the contract is 2♠ doubled by West

#### Scenario: Double cancelled by a new bid
- **WHEN** North bid 1♠, East doubled, South bid 2♠, and three passes follow
- **THEN** the contract is 2♠ undoubled

### Requirement: Undo last call
Before the auction ends, the system SHALL let the user undo the last call. After the auction ends and before the deal moves past the contract stage, the system SHALL let the user return to the auction and undo calls.

#### Scenario: Undo a mistaken call
- **WHEN** the user records 3♦ for East by mistake and selects "Undo"
- **THEN** the system removes the 3♦ call and East is again the player to call
