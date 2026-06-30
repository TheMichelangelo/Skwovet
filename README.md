# BackLogger

BackLogger is a local-first iOS app for tracking:

- backlog items like books, comics, games, and personal activities
- day-by-day activity lists with unfinished-item carry-over
- a simple buy list

All user data stays on device. The app now persists data in SQLite and also supports JSON export/import for backup and restore.

## Features

- Category-based backlog tracking
- Daily planning with carry-over from the previous day
- Buy list for quick purchase reminders
- On-device SQLite persistence
- JSON backup export
- JSON backup import

## Storage

The app stores its database in the app's `Application Support` folder:

- `Backloger/Backloger.sqlite`

Persistence is implemented as a lightweight key-value layer on top of SQLite. Instead of creating many relational tables, the app stores the main app collections as JSON blobs inside one table.

### SQLite schema

```sql
CREATE TABLE IF NOT EXISTS records (
    storage_key TEXT PRIMARY KEY,
    payload BLOB NOT NULL,
    updated_at REAL NOT NULL
);
```

### Stored keys

- `backlogList`: all category backlog data
- `activityBacklogList`: daily activity history and today's list
- `buyBacklogList`: buy-list items

### How it works

- `storage_key` identifies the logical dataset
- `payload` contains encoded JSON for that dataset
- `updated_at` stores the last write timestamp

This keeps the storage simple while avoiding `UserDefaults` loss across app rebuilds or reinstalls in the user's workflow.

## JSON backup format

The app can export everything into one JSON file and import it later.

Backup payload structure:

```json
{
  "exportedAt": "2026-07-01T02:00:00Z",
  "backlogList": { "...": "all backlog categories" },
  "activityBacklogList": { "...": "daily activity history" },
  "buyItems": [
    { "...": "buy list item" }
  ]
}
```

### Included in backup

- all backlog categories
- all daily activity entries
- all buy-list items
- export timestamp

## Migration

Older app data stored in `UserDefaults` is migrated automatically. On first load, if SQLite does not yet contain a dataset but legacy `UserDefaults` data exists, the app imports that data into SQLite and continues using the database from then on.

## Future work

- Cover test
- Refactor code
- Add congrats pop-up after completing item or set of items

## Demo

![Demo](https://github.com/TheMichelangelo/BackLogger/blob/main/demo.gif)
