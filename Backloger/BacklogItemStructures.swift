//
//  BackLogItem.swift
//  Backloger
//
//  Created by Mike Pastula on 19.06.2023.
//

import Foundation

final class BacklogItem: Identifiable, Codable, Hashable, ObservableObject {
    var id: UUID
    var task: String
    var complete: Bool
    var dateAdded: Date
    var dateCompleted: Date
    
    init(task: String) {
        self.id = UUID()
        self.task = task
        self.complete = false
        self.dateAdded = Date()
        self.dateCompleted = Date()
    }
    
    init() {
        self.id = UUID()
        self.task = "task"
        self.complete = false
        self.dateAdded = Date()
        self.dateCompleted = Date()
    }
    
    static func == (lhs: BacklogItem, rhs: BacklogItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(task)
    }
}

final class BacklogList: Codable, Hashable, ObservableObject {
    var currentItem: BacklogItem
    var items: [BacklogItem]
    
    init() {
        currentItem = BacklogItem()
        items = []
    }
    
    static func == (lhs: BacklogList, rhs: BacklogList) -> Bool {
        return lhs.currentItem == rhs.currentItem && lhs.items == rhs.items
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(currentItem)
        hasher.combine(items)
    }
}

final class BacklogListAll: Codable, Hashable, ObservableObject {
    var bookItems: BacklogList
    var comicsItems: BacklogList
    var playstationGameItems: BacklogList
    var xboxGameItems: BacklogList
    var switchGameItems: BacklogList
    var pcGameItems: BacklogList
    var activityItems: BacklogList
    
    init() {
        bookItems = BacklogList()
        comicsItems = BacklogList()
        playstationGameItems = BacklogList()
        xboxGameItems = BacklogList()
        switchGameItems = BacklogList()
        pcGameItems = BacklogList()
        activityItems = BacklogList()
    }
    
    static func == (lhs: BacklogListAll, rhs: BacklogListAll) -> Bool {
        return lhs.bookItems == rhs.bookItems && lhs.comicsItems == rhs.comicsItems
        && lhs.playstationGameItems == rhs.playstationGameItems && lhs.activityItems == rhs.activityItems
    }
    
    static func loadFromStorage(
        database: SQLiteStorage = .shared,
        legacyStore: UserDefaults = .standard
    ) -> BacklogListAll {
        loadCodableValue(
            forKey: StorageKey.backlogList,
            database: database,
            legacyStore: legacyStore,
            defaultValue: BacklogListAll()
        )
    }
    
    static func saveToStorage(backlogList: BacklogListAll, database: SQLiteStorage = .shared) {
        saveCodableValue(backlogList, forKey: StorageKey.backlogList, database: database)
    }

    func list(for category: Category) -> BacklogList {
        switch category {
        case .comics:
            return comicsItems
        case .books:
            return bookItems
        case .activities:
            return activityItems
        case .games_playstation:
            return playstationGameItems
        case .games_switch:
            return switchGameItems
        case .games_windows:
            return pcGameItems
        case .games_xbox:
            return xboxGameItems
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(bookItems)
        hasher.combine(comicsItems)
    }
}

//---------DAY ACTIVITY-------------------
final class ActivityBacklogItem: Identifiable, Codable, Hashable, ObservableObject {
    var id: UUID
    var task: String
    var complete: Bool
    var dateAdded: Date
    
    init(task: String) {
        self.id = UUID()
        self.task = task
        self.complete = false
        self.dateAdded = Date()
    }
    
    static func == (lhs: ActivityBacklogItem, rhs: ActivityBacklogItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(task)
    }
}

final class DayActivityBacklogList: Codable, Hashable, ObservableObject {
    var currentDate: Date
    var items: [ActivityBacklogItem]
    
    init() {
        self.currentDate = Date()
        self.items = [ActivityBacklogItem]()
    }
    
    init(items: [ActivityBacklogItem]) {
        self.currentDate = Date()
        self.items = items
    }
    
    static func == (lhs: DayActivityBacklogList, rhs: DayActivityBacklogList) -> Bool {
        return lhs.currentDate == rhs.currentDate
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(currentDate)
        hasher.combine(items)
    }
}

final class ActivityBacklogListAll: Codable, Hashable, ObservableObject {
    var days: [DayActivityBacklogList]
    
    init() {
        self.days = [DayActivityBacklogList]()
    }
    
    static func == (lhs: ActivityBacklogListAll, rhs: ActivityBacklogListAll) -> Bool {
        return lhs.days == rhs.days
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(days)
    }
    
    static func loadFromStorage(
        database: SQLiteStorage = .shared,
        legacyStore: UserDefaults = .standard
    ) -> ActivityBacklogListAll {
        loadCodableValue(
            forKey: StorageKey.activityBacklogList,
            database: database,
            legacyStore: legacyStore,
            defaultValue: ActivityBacklogListAll()
        )
    }
    
    static func saveToStorage(backlogList: ActivityBacklogListAll, database: SQLiteStorage = .shared) {
        saveCodableValue(backlogList, forKey: StorageKey.activityBacklogList, database: database)
    }

    static func preparedForToday(
        calendar: Calendar = .current,
        today: Date = Date(),
        database: SQLiteStorage = .shared,
        legacyStore: UserDefaults = .standard
    ) -> ActivityBacklogListAll {
        let backlogList = loadFromStorage(database: database, legacyStore: legacyStore)

        guard !backlogList.days.isEmpty else {
            backlogList.days = [DayActivityBacklogList()]
            return backlogList
        }

        if backlogList.days.contains(where: { calendar.isDate($0.currentDate, inSameDayAs: today) }) {
            backlogList.days.sort { $0.currentDate > $1.currentDate }
            return backlogList
        }

        let unfinishedItems = backlogList.days[0].items.filter { !$0.complete }
        let newDay = DayActivityBacklogList(items: unfinishedItems)
        backlogList.days.append(newDay)
        backlogList.days.sort { $0.currentDate > $1.currentDate }
        saveToStorage(backlogList: backlogList, database: database)
        return backlogList
    }
}

enum CompleteCategory: String, CaseIterable, Identifiable {
    case completed, uncompleted
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .completed:
            return "Completed"
        case .uncompleted:
            return "Open"
        }
    }
}

enum Category: String, CaseIterable, Identifiable {
    case games_playstation, games_xbox, games_switch, games_windows, comics, books, activities
    var id: Self { self }
    
    var title: String {
        switch self {
        case .games_playstation:
            return "PlayStation"
        case .games_xbox:
            return "Xbox"
        case .games_switch:
            return "Switch"
        case .games_windows:
            return "PC"
        case .comics:
            return "Comics"
        case .books:
            return "Books"
        case .activities:
            return "Activities"
        }
    }
    
    var symbolName: String {
        switch self {
        case .games_playstation:
            return "gamecontroller"
        case .games_xbox:
            return "gamecontroller.fill"
        case .games_switch:
            return "gamecontroller.circle"
        case .games_windows:
            return "desktopcomputer"
        case .comics:
            return "text.book.closed"
        case .books:
            return "books.vertical"
        case .activities:
            return "figure.run"
        }
    }
}

enum StorageKey {
    static let backlogList = "backlogList"
    static let activityBacklogList = "activityBacklogList"
    static let buyBacklogList = "buyBacklogList"
}

enum BuyListStorage {
    static func load(
        database: SQLiteStorage = .shared,
        legacyStore: UserDefaults = .standard
    ) -> [BacklogItem] {
        loadCodableValue(
            forKey: StorageKey.buyBacklogList,
            database: database,
            legacyStore: legacyStore,
            defaultValue: []
        )
    }
    
    static func save(_ items: [BacklogItem], database: SQLiteStorage = .shared) {
        saveCodableValue(items, forKey: StorageKey.buyBacklogList, database: database)
    }
}

private func loadCodableValue<T: Decodable>(
    forKey key: String,
    database: SQLiteStorage,
    legacyStore: UserDefaults,
    defaultValue: T
) -> T {
    let decoder = JSONDecoder()

    if let data = database.load(forKey: key),
       let decodedValue = try? decoder.decode(T.self, from: data) {
        return decodedValue
    }

    if let legacyData = legacyStore.data(forKey: key),
       let decodedValue = try? decoder.decode(T.self, from: legacyData) {
        database.save(legacyData, forKey: key)
        return decodedValue
    }

    return defaultValue
}

private func saveCodableValue<T: Encodable>(
    _ value: T,
    forKey key: String,
    database: SQLiteStorage
) {
    guard let encoded = try? JSONEncoder().encode(value) else {
        return
    }

    database.save(encoded, forKey: key)
}

enum BacklogLogic {
    static func filteredItems(in backlog: BacklogList, status: CompleteCategory) -> [BacklogItem] {
        backlog.items.filter { item in
            status == .completed ? item.complete : !item.complete
        }
    }

    static func completionRatio(for backlog: BacklogList) -> Double {
        guard !backlog.items.isEmpty else {
            return 0
        }

        let completedCount = backlog.items.filter(\.complete).count
        return Double(completedCount) / Double(backlog.items.count)
    }

    static func highlightedItem(in backlog: BacklogList) -> BacklogItem? {
        if !backlog.currentItem.complete,
           backlog.items.contains(where: { $0.id == backlog.currentItem.id }) {
            return backlog.currentItem
        }

        return backlog.items.first(where: { !$0.complete })
    }

    @discardableResult
    static func addTask(_ rawTask: String, to backlog: BacklogList) -> Bool {
        let task = rawTask.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !task.isEmpty else {
            return false
        }

        backlog.items.append(BacklogItem(task: task))
        backlog.items.sort { $0.task.localizedCaseInsensitiveCompare($1.task) == .orderedAscending }
        return true
    }

    @discardableResult
    static func setRandomCurrentItem(in backlog: BacklogList) -> BacklogItem? {
        let openItems = backlog.items.filter { !$0.complete }
        guard let randomItem = openItems.randomElement() else {
            return nil
        }

        backlog.currentItem = randomItem
        return randomItem
    }

    static func removeTask(_ item: BacklogItem, from backlog: BacklogList) {
        backlog.items.removeAll { $0.id == item.id }

        if backlog.currentItem.id == item.id,
           let replacement = backlog.items.first(where: { !$0.complete }) {
            backlog.currentItem = replacement
        }
    }

    static func completeTask(_ item: BacklogItem, in backlog: BacklogList, completionDate: Date = Date()) {
        guard let index = backlog.items.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        backlog.items[index].complete = true
        backlog.items[index].dateCompleted = completionDate

        if backlog.currentItem.id == item.id,
           let replacement = backlog.items.first(where: { !$0.complete && $0.id != item.id }) {
            backlog.currentItem = replacement
        }
    }
}

enum DayLogic {
    static func todayIndex(in backlogList: ActivityBacklogListAll, calendar: Calendar = .current, today: Date = Date()) -> Int {
        backlogList.days.firstIndex(where: { calendar.isDate($0.currentDate, inSameDayAs: today) }) ?? 0
    }

    static func openItems(in day: DayActivityBacklogList) -> [ActivityBacklogItem] {
        day.items.filter { !$0.complete }
    }

    static func completionRatio(for day: DayActivityBacklogList) -> Double {
        guard !day.items.isEmpty else {
            return 0
        }

        let completedCount = day.items.filter(\.complete).count
        return Double(completedCount) / Double(day.items.count)
    }

    static func previousDays(
        in backlogList: ActivityBacklogListAll,
        calendar: Calendar = .current,
        today: Date = Date()
    ) -> [DayActivityBacklogList] {
        let index = todayIndex(in: backlogList, calendar: calendar, today: today)
        return Array(backlogList.days.enumerated())
            .filter { $0.offset != index }
            .map(\.element)
            .sorted { $0.currentDate > $1.currentDate }
    }

    @discardableResult
    static func addTask(_ rawTask: String, to day: DayActivityBacklogList) -> Bool {
        let task = rawTask.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !task.isEmpty else {
            return false
        }

        day.items.append(ActivityBacklogItem(task: task))
        day.items.sort { $0.task.localizedCaseInsensitiveCompare($1.task) == .orderedAscending }
        return true
    }

    static func removeTask(_ item: ActivityBacklogItem, from day: DayActivityBacklogList) {
        day.items.removeAll { $0.id == item.id }
    }

    static func completeTask(_ item: ActivityBacklogItem, in day: DayActivityBacklogList) {
        guard let index = day.items.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        day.items[index].complete = true
    }
}

enum BuyListLogic {
    static func addTask(_ rawTask: String, to items: inout [BacklogItem]) -> Bool {
        let task = rawTask.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !task.isEmpty else {
            return false
        }

        items.append(BacklogItem(task: task))
        items.sort { $0.task.localizedCaseInsensitiveCompare($1.task) == .orderedAscending }
        return true
    }

    static func removeTask(_ item: BacklogItem, from items: inout [BacklogItem]) {
        items.removeAll { $0.id == item.id }
    }
}
