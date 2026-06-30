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
        allLists.bookItems.items = [BacklogItem(task: "Dune")]

        BacklogListAll.saveToStorage(backlogList: allLists, database: database)
        let loaded = BacklogListAll.loadFromStorage(database: database)

        XCTAssertEqual(loaded.bookItems.items.map(\.task), ["Dune"])
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
