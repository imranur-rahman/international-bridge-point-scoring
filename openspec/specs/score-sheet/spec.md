# score-sheet Specification

## Purpose

Shows the score of each partnership in the traditional rubber bridge layout, keeps the deal history, lets the user correct recorded deals, and ends the session by the configured end rule.

## Requirements

### Requirement: Score sheet layout
The system SHALL show a score sheet with one column for each partnership, headed by the partnership name. For the current rubber, the sheet SHALL show the points above the line and the points below the line in separate areas. The sheet SHALL show a line under each completed game. The sheet SHALL show the number of games that each side won in the current rubber.

#### Scenario: Points above and below the line
- **WHEN** "Alice & Carol" fulfills 2♠ with 1 overtrick
- **THEN** the sheet shows 60 below the line and 30 above the line in the "Alice & Carol" column

#### Scenario: Game line
- **WHEN** a side wins a game
- **THEN** the sheet shows a line under the below-the-line points of that game

### Requirement: Two sheet views
The score sheet SHALL have two views, and a toggle on the sheet SHALL change between them:
- **Paper view** (the default): the traditional score pad layout of the "Score sheet layout" requirement.
- **Card view**: a list with one card for each deal of the current rubber (newest first), with the contract, the result, and the points for each side, and with the rubber total and the session total at the top.

The system SHALL remember the selected view on the device for later sessions. Both views SHALL show the same numbers.

#### Scenario: Default view
- **WHEN** the user opens the score sheet for the first time on a device
- **THEN** the system shows the paper view

#### Scenario: Toggle and remember
- **WHEN** the user changes to the card view and later starts a new session
- **THEN** the score sheet opens in the card view

### Requirement: Score sheet beside the deal on wide screens
When the window is 900 logical pixels wide or wider, the system SHALL show the deal screen and the score sheet side by side, with the deal on the left. When the window is narrower, the system SHALL show the deal screen alone with a "Sheet" button that opens the score sheet. The score sheet SHALL update right after each scored deal, in both layouts. A change of the window width SHALL not lose any entered data.

#### Scenario: Wide window
- **WHEN** the app runs in a browser window that is 1200 pixels wide
- **THEN** the deal screen and the score sheet show side by side

#### Scenario: Phone
- **WHEN** the app runs on a phone in portrait
- **THEN** the deal screen shows alone, and "Sheet" opens the score sheet

#### Scenario: Resize during a deal
- **WHEN** the user is at the result stage in a wide window and makes the window narrow
- **THEN** the deal screen keeps the selected result and shows the "Sheet" button

### Requirement: Score breakdown for each deal
After a deal is scored, the system SHALL show each score component for that deal, with its traditional name and its points: contract points, overtricks, insult bonus, slam bonus, undertricks (penalty), honors, game bonus, rubber bonus, and the side that receives each component. The system SHALL show only the components that are not zero.

#### Scenario: Breakdown for a doubled failed contract
- **WHEN** a side that is not vulnerable goes down 2 in a doubled contract
- **THEN** the breakdown shows "Undertricks (penalty): 300" for the defending side

### Requirement: Totals
The score sheet SHALL show, for each side, the total of the current rubber, the result of each completed rubber, and the session total. The system SHALL show the number of the current deal and, for the "Number of deals" end rule, the number of deals left; for the "Target score" end rule, the target.

#### Scenario: Deals left
- **WHEN** the end rule is 8 deals and 3 deals are scored
- **THEN** the sheet shows "Deal 4 of 8"

### Requirement: Deal history
The system SHALL show a list of all recorded deals in order. Each entry SHALL show the deal number, the dealer, the vulnerability, the contract with the double state and the declarer (or "Passed out"), the result in traditional words, and the points for each side. When the bidding step was on, the entry SHALL let the user open the full auction of that deal.

#### Scenario: History entry
- **WHEN** deal 2 was 4♥ doubled by Bob, down 1, with Bob & Dave vulnerable
- **THEN** the history shows "Deal 2 · 4♥X by Bob · Down 1 · Alice & Carol +200"

### Requirement: Undo last deal
The system SHALL let the user undo the last scored deal. The undo SHALL remove the deal from the history, recalculate all totals, and return the dealer to the dealer of the removed deal. The system SHALL ask for confirmation before the undo.

#### Scenario: Undo
- **WHEN** 5 deals are scored and the user confirms "Undo last deal"
- **THEN** the history shows 4 deals, the totals match the 4 deals, and the next deal is deal 5 with the same dealer as before

### Requirement: Edit a recorded deal
The system SHALL let the user open any recorded deal from the deal history and edit its contract (level, denomination, double state), its declarer, its result, and its honors. The edit screen SHALL use the same inputs as the deal stages. The dealer of the deal SHALL not change. A "Passed out" check box SHALL let the user change a played deal to a passed-out deal, or a passed-out deal to a played deal. When the bidding step was on for that deal, the edit SHALL replace the recorded auction with the changed contract and mark the auction as edited.

#### Scenario: Edit the result
- **WHEN** the user opens deal 3 "4♠X by Carol · Down 1", changes the result to "Made", and saves
- **THEN** the history shows deal 3 as "4♠X by Carol · Made"

#### Scenario: Played deal to passed out
- **WHEN** the user opens deal 2 and selects "Passed out"
- **THEN** the system hides the contract, result, and honors inputs, and after the save, deal 2 scores 0 for both sides with the same dealer

#### Scenario: Passed out to played deal
- **WHEN** the user opens a passed-out deal and clears "Passed out"
- **THEN** the system shows the contract, result, and honors inputs, and does not permit the save until they are complete

### Requirement: Preview of the effect of an edit
Before the system saves an edit, it SHALL show a preview with the session total of each side before and after the edit, and a list of each later deal whose vulnerability or points change. The user SHALL then select "Save edit" or "Cancel". "Cancel" SHALL leave the session with no change. After "Save edit", the system SHALL recalculate all later deals, including vulnerability, games, rubbers, and totals.

#### Scenario: Edit changes a later vulnerability
- **WHEN** the user changes deal 1 from "4♠ fulfilled" to "Down 1", and deal 3 used the vulnerability that came from the game in deal 1
- **THEN** the preview lists deal 3 with "now not vulnerable" and its old and new points, and after "Save edit" the system scores deal 3 again as not vulnerable for that side and updates all totals

#### Scenario: Cancel
- **WHEN** the preview shows and the user selects "Cancel"
- **THEN** the history and all totals stay as they were before the edit

### Requirement: Edit mark and original entry
The deal history SHALL show an edit mark on each deal that the user edited. When the user taps the mark, the system SHALL show the original entry of the deal (as it was first scored) and the date and time of each edit. Later edits of the same deal SHALL keep the original entry.

#### Scenario: Show original entry
- **WHEN** deal 3 was first scored as "4♠X by Carol · Down 1" and later edited to "Made"
- **THEN** the history shows deal 3 as "4♠X by Carol · Made" with an edit mark, and a tap on the mark shows "Original: 4♠X by Carol · Down 1" and the time of the edit

#### Scenario: Undo does not keep a mark
- **WHEN** the user undoes the last deal
- **THEN** the deal is removed from the history with no edit mark left

### Requirement: Session end
The system SHALL end the session after the deal that makes the end rule apply: the last of N deals, or the first deal after which one or both sides have a session total equal to or more than the target. The system SHALL also let the user end the session at any time between deals, after a confirmation. At the session end, the system SHALL add the unfinished rubber bonus (if on) and SHALL show the final summary.

#### Scenario: End by number of deals
- **WHEN** the end rule is 4 deals and deal 4 is scored
- **THEN** the system ends the session and shows the final summary

#### Scenario: End by target score
- **WHEN** the target is 2000 and after deal 9 "Bob & Dave" has 2050
- **THEN** the system ends the session and shows "Bob & Dave" as the winning side if its total is higher

#### Scenario: Early end
- **WHEN** the user selects "End session" between deals and confirms
- **THEN** the system ends the session and adds the unfinished rubber bonus if it is on

### Requirement: Final summary
The final summary SHALL show, from top to bottom:
1. The number of deals played and the winning side with its margin ("Alice & Carol win by 360 points"), or "Tie" for equal totals.
2. A table with one row for each rubber (the points of each side, with a mark on an unfinished rubber), and a row with the session total of each side.
3. The unfinished rubber bonus of each side and its reason ("one game" or "part-score"), when one applies.
4. A chart of the session total of each side after each deal. For the "Target score" end rule, the chart SHALL show the target as a line.
5. The three deals with the most points for one side. Each entry SHALL show the deal number, the contract, the declarer, the result, the side, and the points of that deal for that side (all components of the deal, including a rubber bonus that the deal completed).
6. Player statistics: for each of the four players, the number of contracts declared, contracts fulfilled, contracts down, and slams bid and slams made as declarer. Passed-out deals SHALL not count.

The final summary SHALL offer three actions: "View score sheet" (read-only score sheet and history), "New session, same players", and "Home".

#### Scenario: Winner and margin
- **WHEN** the session ends with "Alice & Carol" 1850 and "Bob & Dave" 1490
- **THEN** the summary shows "Alice & Carol win by 360 points"

#### Scenario: Tie
- **WHEN** the session ends with equal session totals
- **THEN** the summary shows "Tie"

#### Scenario: Player statistics
- **WHEN** Carol declared 5 contracts in the session, fulfilled 3, went down in 2, and bid and made one small slam
- **THEN** the row for Carol shows declared 5, fulfilled 3, down 2, slams bid 1, slams made 1

#### Scenario: Biggest deals
- **WHEN** the largest points of one side in one deal came from deal 7, "6♠ by Bob, made", vulnerable, which also completed a 2–1 rubber with standard values
- **THEN** the first entry is "Deal 7 · 6♠ by Bob · Made · Bob & Dave +1430" (180 + 750 slam + 500 rubber)

### Requirement: New session with the same players
"New session, same players" SHALL open the setup wizard with the players, the seats, the end rule, the bidding step, the scoring components, and the preset of the ended session filled in. The first dealer SHALL be the next player clockwise after the dealer of the last deal of the ended session. The user SHALL be able to change any value before "Start session".

#### Scenario: Next dealer
- **WHEN** Dave (West) dealt the last deal of the ended session and the user selects "New session, same players"
- **THEN** the setup wizard shows the same names and rules, with Alice (North) as the first dealer

### Requirement: Final summary of a past session
The read-only view of a past session SHALL show the same final summary, without the action "New session, same players" if another session is active.

#### Scenario: Past session summary
- **WHEN** the user opens a past session from the list
- **THEN** the system shows its final summary and a link to its read-only score sheet

### Requirement: Reopen after correction
When an undo or an edit makes the end rule no longer apply to an ended session that ended by the end rule, the system SHALL reopen the session and remove the unfinished rubber bonus.

#### Scenario: Undo of the last deal reopens the session
- **WHEN** the session ended after deal 8 of 8 and the user undoes deal 8
- **THEN** the session is active again at deal 8
