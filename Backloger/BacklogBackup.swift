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
    var collectionSettings: CollectionSettings
    var activityBacklogList: ActivityBacklogListAll
    var buyItems: [BacklogItem]

    private enum CodingKeys: String, CodingKey {
        case exportedAt
        case backlogList
        case collectionSettings
        case activityBacklogList
        case buyItems
    }

    init(
        exportedAt: Date = Date(),
        backlogList: BacklogListAll,
        collectionSettings: CollectionSettings,
        activityBacklogList: ActivityBacklogListAll,
        buyItems: [BacklogItem]
    ) {
        self.exportedAt = exportedAt
        self.backlogList = backlogList
        self.collectionSettings = collectionSettings
        self.activityBacklogList = activityBacklogList
        self.buyItems = buyItems
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        exportedAt = try container.decode(Date.self, forKey: .exportedAt)
        backlogList = try container.decode(BacklogListAll.self, forKey: .backlogList)
        collectionSettings = try container.decodeIfPresent(CollectionSettings.self, forKey: .collectionSettings)
            ?? CollectionSettings()
        activityBacklogList = try container.decode(ActivityBacklogListAll.self, forKey: .activityBacklogList)
        buyItems = try container.decode([BacklogItem].self, forKey: .buyItems)
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
                collectionSettings: CollectionSettings.loadFromStorage(database: database, legacyStore: legacyStore),
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
        CollectionSettings.saveToStorage(settings: document.backup.collectionSettings, database: database)
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
