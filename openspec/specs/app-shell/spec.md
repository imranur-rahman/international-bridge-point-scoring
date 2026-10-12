# app-shell Specification

## Purpose

Defines how the web app loads, works without a network, updates, and presents itself as an installed app with its own name, icon, and colors, and how its pages make the important information stand out.

## Requirements

### Requirement: Offline use after the first visit
After the app opened once in a browser with a network, the system SHALL open and work in that browser without a network. The system SHALL keep a copy of every file that the app loaded from its own address and of the fonts that the app loaded from other addresses. Without a network, the system SHALL use these copies. Scoring, setup, history, and all other functions SHALL work offline, because they do not use a network.

#### Scenario: Open without a network
- **WHEN** the user opened the app once with a network, then turns the network off and opens the app again
- **THEN** the app opens, shows the active session, and permits the next deal

#### Scenario: First visit without a network
- **WHEN** the browser never opened the app and has no network
- **THEN** the browser shows its normal error for a missing network

### Requirement: Fast start from the stored copy
After the first visit, the system SHALL open the app from its stored copy at once, with no wait for the network. When the network is available, the system SHALL check for a new version in the background. When a new version exists, the system SHALL download all of its files in the background and SHALL use the new version from the next open. The system SHALL never open the app with files from two different versions.

#### Scenario: Second visit
- **WHEN** the user opens the app again in the same browser
- **THEN** the app opens from the stored copy without a wait for the network

#### Scenario: New version deployed
- **WHEN** a new version is deployed and the user opens the app with a network
- **THEN** the app opens in the old version, downloads the new version in the background, and opens in the new version the next time

#### Scenario: Update stops halfway
- **WHEN** the network stops during the download of a new version
- **THEN** the next open uses the complete old version

### Requirement: App name, icon, and colors
The installed app SHALL have the name "IB Scoring" and an icon that shows a white ♠ above the letters "IB" on felt green with rounded corners. The web app SHALL use this icon for the browser tab, for "Add to Home Screen", and as a maskable icon whose ♠ and letters stay inside the safe zone. The Android and iOS builds SHALL use the same icon. The web manifest SHALL use the felt green as its theme color and background color. The home screen of the app SHALL show the heading "International Bridge Scoring". The app name, the home heading, and the descriptions of the app SHALL not use the words "rubber bridge"; the scoring terms "rubber", "rubber bonus", and "unfinished rubber" SHALL stay.

#### Scenario: Add to Home Screen
- **WHEN** the user adds the web app to the home screen of a phone
- **THEN** the home screen shows the IB Scoring icon with the name "IB Scoring"

#### Scenario: Browser tab
- **WHEN** the user opens the web app in a browser
- **THEN** the tab shows the IB Scoring icon and the title "IB Scoring"

#### Scenario: Home heading
- **WHEN** the user opens the home screen
- **THEN** the app bar shows "IB Scoring" and the heading shows "International Bridge Scoring"

### Requirement: Visual emphasis of important information
Each page SHALL make its structure and its key information stand out with weight and color:
- Page titles and section titles SHALL be bold (weight 700). Section titles SHALL use the theme primary color.
- These key values SHALL be bold (weight 600 or more): the contract headline of a deal, the result in full words, the names in the play roles, the totals rows of the score sheet and of the final summary, the winner line of the final summary, the label and points of each item in a score breakdown, and the current step and the highlighted value of a demo.
- The current item of a list or a sequence SHALL stand out from the other items with weight and color: the current stage in the stage bar, the player to call in the auction, and the current deal in a demo.
- Body text and help text SHALL stay at normal weight, so that the bold parts stand out.

All emphasized text SHALL keep a contrast ratio of at least 4.5:1 with its background in the light theme and in the dark theme.

#### Scenario: Section title
- **WHEN** the user opens the setup step "Game rules"
- **THEN** the section titles "End rule" and "Options" show bold in the primary color

#### Scenario: Score sheet totals
- **WHEN** the user opens the score sheet
- **THEN** the "Session total" row and its points show bold, and the rubber rows show at normal weight

#### Scenario: Final summary winner
- **WHEN** the final summary shows "Alice & Carol win by 360 points"
- **THEN** that line shows bold

### Requirement: Install action
The home screen SHALL show an "Install IB Scoring" action when the app runs in a browser and is not installed:
- When the browser offers an install prompt for the app (for example Chrome, Edge, or Chrome on Android), the action SHALL show that prompt.
- On iPhone and iPad, where the browser offers no prompt, the action SHALL show a short guide: tap Share, then "Add to Home Screen".
- In other browsers with no prompt, the action SHALL not show.

The action SHALL not show when the app runs installed (as a home screen app or as an Android or iOS build), and SHALL hide after the user installs the app from the prompt.

#### Scenario: Install in Chrome
- **WHEN** the user opens the web app in Chrome, and Chrome offers an install prompt
- **THEN** the home screen shows "Install IB Scoring", and a tap shows the install prompt of Chrome

#### Scenario: iPhone guide
- **WHEN** the user opens the web app in Safari on an iPhone
- **THEN** a tap on "Install IB Scoring" shows the guide "Tap Share, then Add to Home Screen"

#### Scenario: Installed app
- **WHEN** the app runs from the home screen
- **THEN** the home screen does not show the install action

### Requirement: Heading font
Page titles, section titles, the contract headline, and the winner line of the final summary SHALL use the Montserrat font. Normal text, buttons, and values SHALL keep the default font. The app SHALL bundle the heading font, so that headings look the same offline. The heading font SHALL keep the weights of the "Visual emphasis of important information" requirement.

#### Scenario: Section title font
- **WHEN** the user opens the setup step "Game rules"
- **THEN** the section title "End rule" uses Montserrat, and the text "Number of deals" uses the default font

### Requirement: Clear the offline copy and the local data
The Settings screen SHALL have a "Storage" section with these actions:
- **Refresh app files** (web app only): shows the size of the offline copy of the app, and after a confirmation deletes the offline copy, removes the service worker, and reloads the app from the network. Sessions, past sessions, House rules, and settings SHALL stay.
- **Delete all data**: deletes all sessions, past sessions, House rules, the last preset, and the display settings on this device. Before the deletion, the system SHALL ask for a strong confirmation: the user types "delete" to enable the action. After the deletion, the app SHALL show the home screen with no session, the House rules defaults, and the default display settings.

On Android and iOS builds, which have no offline copy, the section SHALL show only "Delete all data".

#### Scenario: Refresh app files
- **WHEN** the user selects "Refresh app files" in the web app and confirms
- **THEN** the system deletes the offline copy, reloads the app from the network, and the active session is still there

#### Scenario: Delete all data needs the typed word
- **WHEN** the user selects "Delete all data"
- **THEN** the delete action stays disabled until the user types "delete"

#### Scenario: Delete all data
- **WHEN** the user types "delete" and confirms
- **THEN** the system removes all sessions, past sessions, House rules, and settings, and shows the home screen with no "Continue session"

#### Scenario: Phone build
- **WHEN** the app runs as an Android or iOS build
- **THEN** the Storage section shows "Delete all data" and no "Refresh app files"
