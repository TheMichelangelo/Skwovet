# Agents Guide

## Project Snapshot

This repository contains `Backloger`, a local-first SwiftUI iOS app for managing:

- long-term backlog items such as books, comics, games, and activities
- daily activity lists with unfinished-item carry-over
- a lightweight buy list

The app is a personal productivity side project. It keeps everything on-device with `UserDefaults` and does not use a backend, account system, sync layer, or external dependencies.

## Current Platform Baseline

- Xcode project: `Backloger.xcodeproj`
- UI framework: SwiftUI
- language: Swift 5
- deployment target: `iOS 27.0`

Note: this repo previously targeted `iOS 16.4`; the project file has been updated to `iOS 27.0`.

## Repo Layout

- `README.md`: short product overview and demo link
- `agents.md`: contributor and agent guide
- `.gitignore`: Xcode/macOS ignore rules
- `Backloger/`: app source
- `Backloger.xcodeproj/`: Xcode project
- `BacklogerTests/`: template unit tests
- `BacklogerUITests/`: template UI tests
- `demo.gif`, `demo_old.gif`, `demo_old_2.gif`: product demo assets

## App Structure

Entry point:

- `Backloger/BacklogerApp.swift`: launches `MainView`

Shared infrastructure:

- `Backloger/AppTheme.swift`: shared colors, background, card styling, metric pills, empty states, and screen headers
- `Backloger/BacklogItemStructures.swift`: models, storage keys, category metadata, and persistence helpers

Screens:

- `Backloger/MainView.swift`: modern home screen using `NavigationStack`
- `Backloger/ContentView.swift`: backlog management by category and completion status
- `Backloger/DayView.swift`: daily planning screen with carry-over behavior and history
- `Backloger/ShopListView.swift`: buy list
- `Backloger/ExpandableListItemView.swift`: expandable history card for previous daily lists

## Architecture Notes

- The app still uses a simple local architecture with SwiftUI views owning most screen state.
- Persistence remains `UserDefaults` + `JSONEncoder`/`JSONDecoder`.
- Models are reference types (`class` / `final class`), not structs.
- There is no separate view model layer yet.
- Storage has been cleaned up a bit with:
  - `StorageKey`
  - `BuyListStorage`
  - `BacklogListAll.list(for:)`
  - `ActivityBacklogListAll.preparedForToday()`

## Data Model Summary

Backlog models:

- `BacklogItem`
- `BacklogList`
- `BacklogListAll`

Daily activity models:

- `ActivityBacklogItem`
- `DayActivityBacklogList`
- `ActivityBacklogListAll`

Enums:

- `Category`
- `CompleteCategory`

Storage keys:

- `backlogList`
- `activityBacklogList`
- `buyBacklogList`

## Recent Modernization

The UI and framework usage were updated to feel more current:

- replaced old `NavigationView` usage with `NavigationStack`
- removed the duplicate `MainView` definition that used to live in `ContentView.swift`
- introduced a shared visual system in `AppTheme.swift`
- moved screens toward card-based layouts, glass materials, and clearer hierarchy
- added better empty states and safer progress calculations
- removed force-unwrapped random selection behavior for empty lists
- fixed the daily backlog preparation flow so today’s list is derived more intentionally
- centralized a few repeated storage details

## Remaining Technical Reality

The project is cleaner than before, but it is still a small app with lightweight patterns:

- screen state is mostly local `@State`
- persistence side effects still happen directly from views
- tests are still mostly placeholders
- no migration strategy exists for persisted data shape changes

If you make deeper changes, preserve backward compatibility for stored Codable data unless the task explicitly allows breaking existing saved state.

## Git Hygiene

This repo now includes a `.gitignore` for common Xcode and macOS noise.

Files removed as unnecessary tracked metadata:

- `Backloger.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist`
- `Backloger.xcodeproj/xcuserdata/mikepastula.xcuserdatad/xcschemes/xcschememanagement.plist`

Files that should stay tracked:

- `Backloger.xcodeproj/project.pbxproj`
- `Backloger.xcodeproj/project.xcworkspace/contents.xcworkspacedata`
- all app source, assets, tests, and README/demo files

## Working Guidelines

- Read the target screen and `BacklogItemStructures.swift` together before changing behavior.
- Treat persistence as part of the feature, not an implementation detail.
- Prefer small, cohesive SwiftUI changes over broad rewrites unless explicitly requested.
- Reuse the styling primitives in `AppTheme.swift` instead of creating one-off visual patterns.
- If you touch category behavior, verify `Category.title`, `Category.symbolName`, and `BacklogListAll.list(for:)` stay aligned.
- If you touch daily activity flow, verify carry-over and history logic together.
- Be careful with saved-data schema changes because there is no migration layer.

## Suggested Verification

If full Xcode is installed and selected, useful commands are:

```bash
xcodebuild -list -project Backloger.xcodeproj
xcodebuild test -project Backloger.xcodeproj -scheme Backloger -destination 'platform=iOS Simulator,name=iPhone 15'
```

In the current environment, `xcodebuild` could not be run because the active developer directory points to Command Line Tools instead of a full Xcode app.

## README Relationship

`README.md` is still a lightweight product-facing file.

`agents.md` is the implementation-facing reference for future contributors and coding agents.
