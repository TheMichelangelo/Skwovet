# BackLogger

BackLogger is a local-first iOS app for tracking:

- backlog items like books, comics, games, and personal activities
- day-by-day activity lists with unfinished-item carry-over
- a simple buy list

## Features

- Category-based backlog tracking
- Daily planning with carry-over from the previous day
- Buy list for quick purchase reminders
- Modern SwiftUI navigation and refreshed visual design
- On-device persistence with `UserDefaults`
- Automated GitHub Actions build-and-test workflow on pushes to `main`

## Storage

All app data is stored locally on the device in `UserDefaults`.

Stored keys:

- `backlogList`: all category backlog data
- `activityBacklogList`: daily activity history and today's list
- `buyBacklogList`: buy-list items

The app encodes its data with `JSONEncoder` and stores the resulting blobs in `UserDefaults`. There is currently no SQLite database, file export/import flow, sync layer, or backend.

If the storage implementation changes in the future, this section should be updated together with the code.

## Tests And CI

The repository includes:

- unit tests in `BacklogerTests/`
- UI test templates in `BacklogerUITests/`
- a GitHub Actions workflow at `.github/workflows/ios-ci.yml`

The workflow builds the app and runs tests on pushes to `main`.

## Future Work

- Refactor code further
- Add a congratulations pop-up after completing an item or set of items
- Expand test coverage around UI flows if the app grows

## Demo

![Demo](demo.gif)
