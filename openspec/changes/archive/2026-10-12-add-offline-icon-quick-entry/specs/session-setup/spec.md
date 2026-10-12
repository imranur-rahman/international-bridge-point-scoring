## ADDED Requirements

### Requirement: Quick entry option
The "Game rules" step of the setup SHALL have a "Quick entry" switch with the text "One screen for contract, result, and honors". The default SHALL be off. The switch SHALL be available only when the bidding step is off; when the user turns the bidding step on, the system SHALL turn quick entry off and disable the switch. Quick entry SHALL be fixed after the session starts, like the other session settings, and the read-only session settings SHALL show it.

#### Scenario: Turn on quick entry
- **WHEN** the bidding step is off and the user turns on "Quick entry" and starts the session
- **THEN** each deal of the session uses the quick-entry screen

#### Scenario: Bidding step turns quick entry off
- **WHEN** quick entry is on and the user turns the bidding step on
- **THEN** the system turns quick entry off and disables its switch

#### Scenario: Older stored session
- **WHEN** the app reads a stored session that has no quick-entry value
- **THEN** the session uses quick entry off
