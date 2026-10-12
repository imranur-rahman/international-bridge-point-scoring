# session-persistence Specification

## Purpose

Keeps scoring sessions on the device, so that a page reload, an app restart, or a closed browser tab does not lose the score, and so that the user can open past sessions.

## Requirements

### Requirement: Automatic save
The system SHALL save the active session on the device after each change: a setting at setup, each call, each stage transition, each scored deal, each undo, and each edit. The save SHALL work on Android, iOS, and web without a network connection.

#### Scenario: Reload during a deal
- **WHEN** the user records 3 calls of an auction and reloads the web page
- **THEN** the system opens the same session at the auction with the 3 calls

### Requirement: Resume active session
When the app starts and an active session exists, the system SHALL offer "Continue session" and "New session". The system SHALL keep at most one active session.

#### Scenario: Continue
- **WHEN** the app starts with an active session at deal 6
- **THEN** the system shows "Continue session" and opens deal 6 when the user selects it

#### Scenario: New session with an active one
- **WHEN** an active session exists and the user selects "New session"
- **THEN** the system asks the user to end the active session first, and moves the ended session to the past sessions

### Requirement: Past sessions
The system SHALL keep ended sessions on the device and SHALL show a list with the date, the partnership names, the session totals, and the winning side. The user SHALL be able to open a past session as a read-only score sheet with its deal history.

#### Scenario: Open a past session
- **WHEN** the user opens a past session from the list
- **THEN** the system shows its score sheet and deal history, and does not permit edits

### Requirement: Delete a past session
The system SHALL let the user delete a past session after a confirmation.

#### Scenario: Delete
- **WHEN** the user selects "Delete" on a past session and confirms
- **THEN** the system removes the session from the device and from the list

### Requirement: Store House rules and last preset
The system SHALL save the "House rules" values on the device each time the user saves them, and SHALL save which preset the most recent session used. Each session SHALL store its own copy of the scoring values, so that a past or active session does not depend on the current "House rules".

#### Scenario: House rules after restart
- **WHEN** the user saves "House rules" with a game threshold of 120 and restarts the app
- **THEN** "House rules" shows a game threshold of 120

#### Scenario: Past session keeps its values
- **WHEN** a past session used "House rules" with a rubber bonus of 600, and "House rules" now has 800
- **THEN** the past session shows the scores that it calculated with 600

### Requirement: Stored data format version
The system SHALL store each session with a data format version number. When the app reads a session with an older supported version, the system SHALL convert it to the current version. When the app reads data that it cannot read, the system SHALL show an error for that session and SHALL not stop the app or change the data.

#### Scenario: Data that cannot be read
- **WHEN** the stored data of one past session is damaged
- **THEN** the list shows that session as "Cannot be opened", and the other sessions open normally
