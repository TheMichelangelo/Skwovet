# Agents Guide

## Project Snapshot

This repository contains `Backloger`, a local-first SwiftUI iOS app for managing:

- long-term backlog items such as books, comics, games, and activities
- daily activity lists with unfinished-item carry-over
- a lightweight buy list

The app keeps its data on-device with `UserDefaults`. There is no backend, sync layer, file-based database, or JSON import/export feature in the current codebase.

## Current Platform Baseline

- Xcode project: `Backloger.xcodeproj`
- UI framework: SwiftUI
- language: Swift 5
- deployment target: `iOS 27.0`

## Repo Layout

- `README.md`: product-facing overview, storage summary, demo, and CI notes
- `agent.md`: contributor and coding-agent guide
- `.github/workflows/ios-ci.yml`: GitHub Actions workflow for build and test on pushes to `main`
- `.gitignore`: Xcode/macOS ignore rules
- `Backloger/`: app source
- `Backloger.xcodeproj/`: Xcode project and shared scheme
- `BacklogerTests/`: unit tests
- `BacklogerUITests/`: UI tests
- `demo.gif`, `demo_old.gif`, `demo_old_2.gif`: demo assets

## App Structure

Entry point:

- `Backloger/BacklogerApp.swift`: launches `MainView`

Shared infrastructure:

- `Backloger/AppTheme.swift`: shared colors, background, card styling, metric pills, empty states, and screen headers
- `Backloger/BacklogItemStructures.swift`: models, storage keys, persistence helpers, and shared domain logic used by tests

Screens:

- `Backloger/MainView.swift`: home screen using `NavigationStack`
- `Backloger/ContentView.swift`: backlog management by category and completion status
- `Backloger/DayView.swift`: daily planning screen with carry-over behavior and history
- `Backloger/ShopListView.swift`: buy list
- `Backloger/ExpandableListItemView.swift`: expandable history card for previous daily lists

## Persistence

Current storage implementation:

- `UserDefaults`
- `JSONEncoder` / `JSONDecoder`

Storage keys:

- `backlogList`
- `activityBacklogList`
- `buyBacklogList`

Rule: any change to persistence or database behavior must also update the `README.md` storage section in the same change.

This includes:

- moving from `UserDefaults` to a database
- changing storage keys
- adding backup/import/export behavior
- changing the location or format of persisted data

## Testing And CI

- Functional logic is covered primarily through XCTest in `BacklogerTests/`
- Shared logic lives in helper types such as `BacklogLogic`, `DayLogic`, and `BuyListLogic`
- GitHub Actions workflow lives at `.github/workflows/ios-ci.yml`
- The repo now includes a shared scheme at `Backloger.xcodeproj/xcshareddata/xcschemes/Backloger.xcscheme`

If CI behavior changes, update both this file and `README.md`.

## Working Guidelines

- Read the target screen and `BacklogItemStructures.swift` together before changing behavior.
- Treat persistence as part of the feature, not an implementation detail.
- Prefer small, cohesive SwiftUI changes over broad rewrites unless explicitly requested.
- Reuse the styling primitives in `AppTheme.swift` instead of creating one-off visual patterns.
- If you touch category behavior, verify `Category.title`, `Category.symbolName`, and `BacklogListAll.list(for:)` stay aligned.
- If you touch daily activity flow, verify carry-over and history logic together.
- If you change storage, also update `README.md` where storage is described.
- If you add or change repo automation, also update `README.md` and this file.

## Suggested Verification

Typical local verification commands:

```bash
xcodebuild -list -project Backloger.xcodeproj
xcodebuild test -project Backloger.xcodeproj -scheme Backloger -destination 'platform=iOS Simulator,name=iPhone 16'
```

In the current local environment, `xcodebuild` could not be run because the active developer directory points to Command Line Tools instead of a full Xcode app.
