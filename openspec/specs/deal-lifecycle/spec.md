# deal-lifecycle Specification

## Purpose

Defines the stages of one deal, the transitions between the stages, the rotation of the dealer, and the display of the declarer, the dummy, and the opening leader, so that players always know the current step.

## Requirements

### Requirement: Deal stages
Each deal SHALL move through these stages in this order:
1. **Deal start**: the system shows the deal number, the dealer, and the vulnerability of each side.
2. **Auction**: only when the bidding step is on.
3. **Contract**: the final contract, the declarer, and the double or redouble state.
4. **Play**: the system shows the declarer, the dummy, and the opening leader.
5. **Result**: the user enters the number of tricks that the declarer took and, if honors are on, the honors held.
6. **Scored**: the system shows the score for this deal and the updated totals.

When quick entry is on, each deal SHALL instead move through two stages: **Entry** (the quick-entry screen) and **Scored**.

The system SHALL show the name of the current stage at all times during a deal. The system SHALL permit a move only to the next stage, or back to the previous stage before the deal is scored.

#### Scenario: Normal deal without bidding step
- **WHEN** the bidding step is off and the user completes each stage
- **THEN** the deal moves through deal start, contract, play, result, and scored, in this order

#### Scenario: Normal deal with bidding step
- **WHEN** the bidding step is on and the auction ends with a contract
- **THEN** the system moves to the contract stage with the contract and the declarer from the auction already filled in

#### Scenario: Move back before scoring
- **WHEN** the deal is at the result stage and the user selects "Back"
- **THEN** the system returns to the play stage and keeps the data already entered

#### Scenario: Deal with quick entry
- **WHEN** quick entry is on and the user scores a deal
- **THEN** the deal moves through entry and scored, in this order

### Requirement: Direct contract entry
When the bidding step is off, the contract stage SHALL let the user enter the level (1 to 7), the denomination (clubs, diamonds, hearts, spades, or no trump), the declarer (one of the four players), and the double state (undoubled, doubled, or redoubled). The system SHALL not move to the play stage until all four values are set. The contract stage SHALL also offer "Passed out".

#### Scenario: Complete contract
- **WHEN** the user enters 4, spades, Carol, undoubled
- **THEN** the system shows "4♠ by Carol" and permits the move to the play stage

#### Scenario: Incomplete contract
- **WHEN** the user did not select a declarer
- **THEN** the system does not permit the move to the play stage

### Requirement: Contract from auction is read-only
When the bidding step is on, the contract stage SHALL show the contract and the declarer that the auction found and SHALL not permit a direct change. To change the contract, the user SHALL go back to the auction.

#### Scenario: Change contract after auction
- **WHEN** the contract stage shows "3NT doubled by Bob" from the auction and the user wants a different contract
- **THEN** the user selects "Back" to return to the auction and changes the calls there

### Requirement: Play roles
At the play stage, the system SHALL show:
- the **declarer**: the player who plays the contract,
- the **dummy**: the partner of the declarer,
- the **opening leader**: the player to the left of the declarer (the next player clockwise after the declarer).

#### Scenario: Roles for a South declarer
- **WHEN** the players are Alice (North), Bob (East), Carol (South), Dave (West) and Carol is the declarer
- **THEN** the system shows Carol as the declarer, Alice as the dummy, and Dave as the player who makes the opening lead

#### Scenario: Roles for a West declarer
- **WHEN** Dave (West) is the declarer
- **THEN** the system shows Bob as the dummy and Alice as the player who makes the opening lead

### Requirement: Result entry
At the result stage, the system SHALL show the contract and the number of tricks that the declarer needs (level + 6). The system SHALL let the user select the result with one button for each possible result, with short texts in one style:
- "−N" for N from 1 to the level + 6 (N undertricks),
- "Made" when the declarer took exactly the level + 6 tricks,
- "+N" for N from 1 to 7 − level (N overtricks).

The system SHALL not show a result that is not possible for the contract. Each contract has 14 possible results (0 to 13 tricks), so the system SHALL show all of them at once, in order, in an even grid of 2 rows and 7 columns. All cells SHALL have the same width and height, at least 44 logical pixels high, and SHALL fit the width of the screen at each text size with no horizontal scroll. The cells SHALL use one color for undertricks, one for "Made", and one for overtricks; the selected cell SHALL be filled. The system SHALL store the result as the number of tricks taken, from 0 to 13. After the selection, the system SHALL show the result in full words, bold and in the color of its group:
- "Contract fulfilled" for "Made",
- "Contract fulfilled with N overtrick(s)" for "+N",
- "Down N (N undertricks)" for "−N".

#### Scenario: Buttons for a game contract
- **WHEN** the contract is 4♠ by Carol
- **THEN** the system shows "Needs 10 tricks" and the buttons "−10" to "−1", "Made", "+1", "+2", and "+3"

#### Scenario: Even grid on a phone
- **WHEN** the contract is 4♠ and the screen is 360 logical pixels wide
- **THEN** the system shows "−10" to "−4" in the first row and "−3" to "+3" in the second row, all cells with the same width, and no horizontal scroll

#### Scenario: No overtrick at the grand slam
- **WHEN** the contract is 7NT
- **THEN** the system shows no "+N" button

#### Scenario: Contract fulfilled exactly
- **WHEN** the contract is 4♠ and the user selects "Made"
- **THEN** the system shows "Contract fulfilled"

#### Scenario: Overtricks
- **WHEN** the contract is 2♥ and the user selects "+2"
- **THEN** the system shows "Contract fulfilled with 2 overtricks"

#### Scenario: Undertricks
- **WHEN** the contract is 3NT and the user selects "−2"
- **THEN** the system shows "Down 2 (2 undertricks)" and records 7 tricks taken

### Requirement: Honors entry
When honors are on, the result stage SHALL let the user select the majority side (the partnership with 3 or more honors) and the holding of that side, or "None" when each side holds 2 aces at no trump. The holdings SHALL be:
- For a suit contract: "3 honors", "4 honors, split", "4 honors in one hand", "5 honors, split 3 + 2", "5 honors, 4 + 1", "5 honors in one hand".
- For a no trump contract: "None (2 + 2)", "3 aces", "4 aces, split", "4 aces in one hand".

The system SHALL let the user select either partnership, whether it is the declaring side or the defending side. Next to each holding, the system SHALL show the points that it gives with the scoring values of the session. In a suit contract, one side always holds 3 or more of the 5 honors, so the system SHALL need a selection before the deal is scored.

#### Scenario: Defenders hold honors
- **WHEN** the contract is 4♥ by Carol and Bob held 4 of the 5 heart honors, and Dave held the 5th
- **THEN** the user selects "Bob & Dave" and "5 honors, 4 + 1"

#### Scenario: Honors options at no trump
- **WHEN** the contract is in no trump
- **THEN** the honors input shows "None (2 + 2)", "3 aces", "4 aces, split", and "4 aces in one hand"

#### Scenario: Points shown next to each holding
- **WHEN** the session uses the "House rules" defaults and the contract is in a suit
- **THEN** the honors input shows "4 honors in one hand · 80" and "5 honors, 4 + 1 · 90"

### Requirement: Passed-out deal
When a deal is passed out (all four players pass in the auction, or the user selects "Passed out" at the contract stage), the system SHALL score the deal as 0 for both sides, SHALL count it as one deal for the end rule, and SHALL move to the next deal.

#### Scenario: Passed out
- **WHEN** all four players pass
- **THEN** the system records a passed-out deal with no score and starts the next deal with the next dealer

### Requirement: Dealer rotation
The dealer of each deal after the first SHALL be the next player clockwise after the dealer of the previous deal (North → East → South → West → North). Passed-out deals SHALL also advance the dealer.

#### Scenario: Rotation
- **WHEN** Bob (East) dealt deal 3
- **THEN** Carol (South) deals deal 4

### Requirement: Vulnerability display
At the deal start stage and at the play stage, the system SHALL show for each side whether it is "vulnerable" or "not vulnerable", as the rubber-scoring capability defines.

#### Scenario: One side vulnerable
- **WHEN** "Alice & Carol" won one game in the current rubber and "Bob & Dave" won none
- **THEN** the deal start shows "Alice & Carol: vulnerable" and "Bob & Dave: not vulnerable"

### Requirement: Quick-entry screen
When quick entry is on, the entry stage SHALL show on one screen:
- the deal number, the dealer, and the vulnerability of each side,
- the inputs of the direct contract entry (level, denomination, double state, declarer) and a "Passed out" action,
- after a declarer is selected, the dummy and the player who makes the opening lead,
- after a level is selected, the result buttons of the "Result entry" requirement,
- when honors are on and a denomination is selected, the honors input of the "Honors entry" requirement,
- a "Score deal" action.

"Score deal" SHALL be enabled only when the contract, the declarer, the result, and (when honors are on) the honors are complete. A change of the level SHALL clear the selected result; a change of the denomination between a suit and no trump SHALL clear the selected honors. "Score deal" SHALL record the deal with the same result as the full stages would record. A deal that is passed out SHALL be recorded as in the "Passed-out deal" requirement.

#### Scenario: Score a deal in one screen
- **WHEN** quick entry is on and the user selects 4, ♠, undoubled, Carol, "Made", and the honors, and selects "Score deal"
- **THEN** the system records "4♠ by Carol · Made" and shows the scored stage

#### Scenario: Roles on the quick-entry screen
- **WHEN** quick entry is on and the user selects Carol (South) as the declarer
- **THEN** the screen shows Alice as the dummy and Dave as the player who makes the opening lead

#### Scenario: Incomplete entry
- **WHEN** quick entry is on and the result is not selected
- **THEN** "Score deal" is disabled

#### Scenario: Level change clears the result
- **WHEN** the user selected "+1" for 2♠ and then selects level 4
- **THEN** no result is selected
