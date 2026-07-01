import XCTest
@testable import Backloger

final class StorageAndDayLogicTests: XCTestCase {
    private var store: UserDefaults!
    private var database: SQLiteStorage!

    override func setUp() {
        super.setUp()
        store = UserDefaults(suiteName: "StorageAndDayLogicTests")!
        store.removePersistentDomain(forName: "StorageAndDayLogicTests")
        let databaseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("BacklogerTests.sqlite", isDirectory: false)
        database = SQLiteStorage(url: databaseURL)
        database.deleteAllRecords()
    }

    override func tearDown() {
        database.deleteAllRecords()
        database = nil
        store.removePersistentDomain(forName: "StorageAndDayLogicTests")
        store = nil
        super.tearDown()
    }

    func testBacklogStorageRoundTripPersistsItems() {
        let allLists = BacklogListAll()
        allLists.gameItems.items = [BacklogItem(task: "Mass Effect")]
        allLists.bookItems.items = [BacklogItem(task: "Dune")]

        BacklogListAll.saveToStorage(backlogList: allLists, database: database)
        let loaded = BacklogListAll.loadFromStorage(database: database)

        XCTAssertEqual(loaded.gameItems.items.map(\.task), ["Mass Effect"])
        XCTAssertEqual(loaded.bookItems.items.map(\.task), ["Dune"])
    }

    func testCollectionSettingsRoundTripPersistsSelection() {
        let settings = CollectionSettings(
            selectedCategories: [.games, .books, .lego],
            hasCompletedOnboarding: true
        )

        CollectionSettings.saveToStorage(settings: settings, database: database)
        let loaded = CollectionSettings.loadFromStorage(database: database)

        XCTAssertEqual(loaded.selectedCategories, [.games, .books, .lego])
        XCTAssertTrue(loaded.hasCompletedOnboarding)
    }

    func testActivityStorageRoundTripPersistsDays() {
        let day = DayActivityBacklogList(items: [ActivityBacklogItem(task: "Walk")])
        let list = ActivityBacklogListAll()
        list.days = [day]

        ActivityBacklogListAll.saveToStorage(backlogList: list, database: database)
        let loaded = ActivityBacklogListAll.loadFromStorage(database: database)

        XCTAssertEqual(loaded.days.count, 1)
        XCTAssertEqual(loaded.days[0].items.map(\.task), ["Walk"])
    }

    func testBuyListStorageRoundTripPersistsItems() {
        let items = [BacklogItem(task: "Keyboard")]

        BuyListStorage.save(items, database: database)
        let loaded = BuyListStorage.load(database: database)

        XCTAssertEqual(loaded.map(\.task), ["Keyboard"])
    }

    func testPreparedForTodayCreatesInitialDayWhenStorageIsEmpty() {
        let prepared = ActivityBacklogListAll.preparedForToday(database: database)

        XCTAssertEqual(prepared.days.count, 1)
        XCTAssertTrue(prepared.days[0].items.isEmpty)
    }

    func testPreparedForTodayKeepsExistingTodayEntry() {
        let today = Date(timeIntervalSince1970: 10_000)
        let todayEntry = DayActivityBacklogList(items: [ActivityBacklogItem(task: "Read")])
        todayEntry.currentDate = today
        let existing = ActivityBacklogListAll()
        existing.days = [todayEntry]
        ActivityBacklogListAll.saveToStorage(backlogList: existing, database: database)

        let calendar = Calendar(identifier: .gregorian)
        let prepared = ActivityBacklogListAll.preparedForToday(calendar: calendar, today: today, database: database)

        XCTAssertEqual(prepared.days.count, 1)
        XCTAssertEqual(prepared.days[0].items.map(\.task), ["Read"])
    }

    func testPreparedForTodayCarriesForwardOnlyUnfinishedItems() {
        let calendar = Calendar(identifier: .gregorian)
        let previousDate = Date(timeIntervalSince1970: 20_000)
        let today = previousDate.addingTimeInterval(86_400)

        let unfinished = ActivityBacklogItem(task: "Open")
        let finished = ActivityBacklogItem(task: "Done")
        finished.complete = true

        let previousDay = DayActivityBacklogList(items: [unfinished, finished])
        previousDay.currentDate = previousDate

        let existing = ActivityBacklogListAll()
        existing.days = [previousDay]
        ActivityBacklogListAll.saveToStorage(backlogList: existing, database: database)

        let prepared = ActivityBacklogListAll.preparedForToday(calendar: calendar, today: today, database: database)

        XCTAssertEqual(prepared.days.count, 2)
        XCTAssertEqual(prepared.days[0].items.map(\.task), ["Open"])
        XCTAssertEqual(prepared.days[1].items.map(\.task), ["Open", "Done"])

        let persisted = ActivityBacklogListAll.loadFromStorage(database: database)
        XCTAssertEqual(persisted.days.count, 2)
    }

    func testBacklogStorageMigratesLegacyUserDefaultsIntoSQLite() {
        let allLists = BacklogListAll()
        allLists.bookItems.items = [BacklogItem(task: "Foundation")]

        let legacyData = try! JSONEncoder().encode(allLists)
        store.set(legacyData, forKey: StorageKey.backlogList)

        let loaded = BacklogListAll.loadFromStorage(database: database, legacyStore: store)

        XCTAssertEqual(loaded.bookItems.items.map(\.task), ["Foundation"])

        store.removeObject(forKey: StorageKey.backlogList)
        let sqliteOnlyLoaded = BacklogListAll.loadFromStorage(database: database, legacyStore: store)
        XCTAssertEqual(sqliteOnlyLoaded.bookItems.items.map(\.task), ["Foundation"])
    }

    func testBacklogStorageMergesLegacyPlatformSpecificGameLists() throws {
        struct LegacyBacklogListAll: Encodable {
            let bookItems = BacklogList()
            let comicsItems = BacklogList()
            let playstationGameItems: BacklogList
            let xboxGameItems: BacklogList
            let switchGameItems = BacklogList()
            let pcGameItems = BacklogList()
        }

        let playstation = BacklogList()
        playstation.items = [BacklogItem(task: "Spider-Man")]
        playstation.currentItem = playstation.items[0]

        let xbox = BacklogList()
        xbox.items = [BacklogItem(task: "Halo")]
        xbox.currentItem = xbox.items[0]

        let legacyPayload = try JSONEncoder().encode(
            LegacyBacklogListAll(
                playstationGameItems: playstation,
                xboxGameItems: xbox
            )
        )

        store.set(legacyPayload, forKey: StorageKey.backlogList)

        let loaded = BacklogListAll.loadFromStorage(database: database, legacyStore: store)

        XCTAssertEqual(loaded.gameItems.items.map(\.task), ["Halo", "Spider-Man"])
    }

    func testBackupDocumentRoundTripPreservesAllStoredCollections() throws {
        let backlog = BacklogListAll()
        backlog.bookItems.items = [BacklogItem(task: "Hyperion")]
        BacklogListAll.saveToStorage(backlogList: backlog, database: database)

        let activity = ActivityBacklogListAll()
        activity.days = [DayActivityBacklogList(items: [ActivityBacklogItem(task: "Run")])]
        ActivityBacklogListAll.saveToStorage(backlogList: activity, database: database)

        BuyListStorage.save([BacklogItem(task: "Headphones")], database: database)

        let document = BacklogBackupTransfer.makeBackupDocument(database: database)
        let wrapper = try document.fileWrapper(configuration: .init())
        let restoredData = try XCTUnwrap(wrapper.regularFileContents)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let restoredBackup = try decoder.decode(BacklogBackup.self, from: restoredData)

        XCTAssertEqual(restoredBackup.backlogList.bookItems.items.map(\.task), ["Hyperion"])
        XCTAssertEqual(restoredBackup.collectionSettings.selectedCategories, [])
        XCTAssertEqual(restoredBackup.activityBacklogList.days.first?.items.map(\.task), ["Run"])
        XCTAssertEqual(restoredBackup.buyItems.map(\.task), ["Headphones"])
    }

    func testImportBackupReplacesPersistedData() {
        let importedBacklog = BacklogListAll()
        importedBacklog.comicsItems.items = [BacklogItem(task: "Saga")]
        let importedSettings = CollectionSettings(selectedCategories: [.comics, .boardGames], hasCompletedOnboarding: true)

        let importedActivity = ActivityBacklogListAll()
        importedActivity.days = [DayActivityBacklogList(items: [ActivityBacklogItem(task: "Stretch")])]

        let importedBuyItems = [BacklogItem(task: "Mouse")]

        let document = BacklogBackupDocument(
            backup: BacklogBackup(
                backlogList: importedBacklog,
                collectionSettings: importedSettings,
                activityBacklogList: importedActivity,
                buyItems: importedBuyItems
            )
        )

        BacklogBackupTransfer.importBackup(from: document, database: database)

        XCTAssertEqual(
            BacklogListAll.loadFromStorage(database: database).comicsItems.items.map(\.task),
            ["Saga"]
        )
        XCTAssertEqual(
            CollectionSettings.loadFromStorage(database: database).selectedCategories,
            [.comics, .boardGames]
        )
        XCTAssertEqual(
            ActivityBacklogListAll.loadFromStorage(database: database).days.first?.items.map(\.task),
            ["Stretch"]
        )
        XCTAssertEqual(BuyListStorage.load(database: database).map(\.task), ["Mouse"])
    }

    func testDayLogicTodayIndexOpenItemsProgressAndPreviousDays() {
        let calendar = Calendar(identifier: .gregorian)
        let olderDate = Date(timeIntervalSince1970: 100)
        let today = olderDate.addingTimeInterval(86_400)

        let older = DayActivityBacklogList(items: [ActivityBacklogItem(task: "Old")])
        older.currentDate = olderDate

        let firstToday = ActivityBacklogItem(task: "One")
        let secondToday = ActivityBacklogItem(task: "Two")
        secondToday.complete = true
        let todayList = DayActivityBacklogList(items: [firstToday, secondToday])
        todayList.currentDate = today

        let list = ActivityBacklogListAll()
        list.days = [older, todayList]

        XCTAssertEqual(DayLogic.todayIndex(in: list, calendar: calendar, today: today), 1)
        XCTAssertEqual(DayLogic.openItems(in: todayList).map(\.task), ["One"])
        XCTAssertEqual(DayLogic.completionRatio(for: todayList), 0.5, accuracy: 0.0001)
        XCTAssertEqual(DayLogic.previousDays(in: list, calendar: calendar, today: today).map(\.currentDate), [olderDate])
    }

    func testDayLogicAddRemoveAndCompleteTask() {
        let day = DayActivityBacklogList()

        XCTAssertFalse(DayLogic.addTask(" ", to: day))
        XCTAssertTrue(DayLogic.addTask("  Bravo ", to: day))
        XCTAssertTrue(DayLogic.addTask("Alpha", to: day))
        XCTAssertEqual(day.items.map(\.task), ["Alpha", "Bravo"])

        let first = day.items[0]
        DayLogic.completeTask(first, in: day)
        XCTAssertTrue(first.complete)

        DayLogic.removeTask(first, from: day)
        XCTAssertEqual(day.items.map(\.task), ["Bravo"])
    }

    func testBuyListLogicAddAndRemoveTask() {
        var items = [BacklogItem(task: "Zulu")]

        XCTAssertFalse(BuyListLogic.addTask("   ", to: &items))
        XCTAssertTrue(BuyListLogic.addTask(" alpha ", to: &items))
        XCTAssertEqual(items.map(\.task), ["alpha", "Zulu"])

        let alpha = items[0]
        BuyListLogic.removeTask(alpha, from: &items)
        XCTAssertEqual(items.map(\.task), ["Zulu"])
    }
}
