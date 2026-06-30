//
//  SQLiteStorage.swift
//  Backloger
//

import Foundation
import SQLite3

final class SQLiteStorage {
    static let shared = SQLiteStorage()

    private let db: OpaquePointer?
    private let url: URL

    init(url: URL = SQLiteStorage.defaultDatabaseURL()) {
        self.url = url

        let parentDirectory = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: parentDirectory, withIntermediateDirectories: true)

        var database: OpaquePointer?
        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        let result = sqlite3_open_v2(url.path, &database, flags, nil)

        guard result == SQLITE_OK else {
            if let database {
                sqlite3_close(database)
            }
            self.db = nil
            assertionFailure("Unable to open SQLite database at \(url.path)")
            return
        }

        self.db = database
        createRecordsTableIfNeeded()
    }

    deinit {
        sqlite3_close(db)
    }

    func load(forKey key: String) -> Data? {
        guard let db else {
            return nil
        }

        let sql = "SELECT payload FROM records WHERE storage_key = ? LIMIT 1;"
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            finalize(statement)
            return nil
        }

        defer { finalize(statement) }

        sqlite3_bind_text(statement, 1, key, -1, SQLITE_TRANSIENT)

        guard sqlite3_step(statement) == SQLITE_ROW,
              let bytes = sqlite3_column_blob(statement, 0) else {
            return nil
        }

        let count = Int(sqlite3_column_bytes(statement, 0))
        return Data(bytes: bytes, count: count)
    }

    func save(_ data: Data, forKey key: String) {
        guard let db else {
            return
        }

        let sql = """
        INSERT INTO records (storage_key, payload, updated_at)
        VALUES (?, ?, ?)
        ON CONFLICT(storage_key) DO UPDATE SET
            payload = excluded.payload,
            updated_at = excluded.updated_at;
        """
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            finalize(statement)
            assertionFailure("Unable to prepare SQLite save statement for \(key)")
            return
        }

        defer { finalize(statement) }

        let timestamp = Date().timeIntervalSince1970
        sqlite3_bind_text(statement, 1, key, -1, SQLITE_TRANSIENT)
        data.withUnsafeBytes { buffer in
            sqlite3_bind_blob(statement, 2, buffer.baseAddress, Int32(data.count), SQLITE_TRANSIENT)
        }
        sqlite3_bind_double(statement, 3, timestamp)

        guard sqlite3_step(statement) == SQLITE_DONE else {
            assertionFailure("Unable to save SQLite record for \(key)")
            return
        }
    }

    func deleteAllRecords() {
        execute("DELETE FROM records;")
    }

    private func createRecordsTableIfNeeded() {
        execute(
            """
            CREATE TABLE IF NOT EXISTS records (
                storage_key TEXT PRIMARY KEY,
                payload BLOB NOT NULL,
                updated_at REAL NOT NULL
            );
            """
        )
    }

    private func execute(_ sql: String) {
        guard let db else {
            return
        }

        guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else {
            assertionFailure("SQLite execution failed for database at \(url.path)")
            return
        }
    }

    private func finalize(_ statement: OpaquePointer?) {
        sqlite3_finalize(statement)
    }

    private static func defaultDatabaseURL() -> URL {
        let baseDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

        return baseDirectory
            .appendingPathComponent("Backloger", isDirectory: true)
            .appendingPathComponent("Backloger.sqlite", isDirectory: false)
    }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
