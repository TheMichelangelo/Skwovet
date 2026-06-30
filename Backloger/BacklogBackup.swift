//
//  BacklogBackup.swift
//  Backloger
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct BacklogBackup: Codable {
    var exportedAt: Date
    var backlogList: BacklogListAll
    var activityBacklogList: ActivityBacklogListAll
    var buyItems: [BacklogItem]

    init(
        exportedAt: Date = Date(),
        backlogList: BacklogListAll,
        activityBacklogList: ActivityBacklogListAll,
        buyItems: [BacklogItem]
    ) {
        self.exportedAt = exportedAt
        self.backlogList = backlogList
        self.activityBacklogList = activityBacklogList
        self.buyItems = buyItems
    }
}

struct BacklogBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.json]

    let backup: BacklogBackup

    init(backup: BacklogBackup) {
        self.backup = backup
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        backup = try decoder.decode(BacklogBackup.self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(backup)
        return .init(regularFileWithContents: data)
    }
}

enum BacklogBackupTransfer {
    static func makeBackupDocument(
        database: SQLiteStorage = .shared,
        legacyStore: UserDefaults = .standard
    ) -> BacklogBackupDocument {
        BacklogBackupDocument(
            backup: BacklogBackup(
                backlogList: BacklogListAll.loadFromStorage(database: database, legacyStore: legacyStore),
                activityBacklogList: ActivityBacklogListAll.loadFromStorage(database: database, legacyStore: legacyStore),
                buyItems: BuyListStorage.load(database: database, legacyStore: legacyStore)
            )
        )
    }

    static func importBackup(
        from document: BacklogBackupDocument,
        database: SQLiteStorage = .shared
    ) {
        BacklogListAll.saveToStorage(backlogList: document.backup.backlogList, database: database)
        ActivityBacklogListAll.saveToStorage(backlogList: document.backup.activityBacklogList, database: database)
        BuyListStorage.save(document.backup.buyItems, database: database)
    }

    static func importBackup(
        from data: Data,
        database: SQLiteStorage = .shared
    ) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(BacklogBackup.self, from: data)
        importBackup(from: BacklogBackupDocument(backup: backup), database: database)
    }

    static func defaultFilename(now: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        return "BackLogger-backup-\(formatter.string(from: now))"
    }
}
