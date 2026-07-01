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
    var gameItems: BacklogList
    var bookItems: BacklogList
    var comicsItems: BacklogList
    var legoItems: BacklogList
    var boardGameItems: BacklogList
    var activityCollectionItems: BacklogList
    var miniaturePaintingItems: BacklogList

    private enum CodingKeys: String, CodingKey {
        case gameItems
        case bookItems
        case comicsItems
        case legoItems
        case boardGameItems
        case activityCollectionItems
        case miniaturePaintingItems
        case playstationGameItems
        case xboxGameItems
        case switchGameItems
        case pcGameItems
    }

    init() {
        gameItems = BacklogList()
        bookItems = BacklogList()
        comicsItems = BacklogList()
        legoItems = BacklogList()
        boardGameItems = BacklogList()
        activityCollectionItems = BacklogList()
        miniaturePaintingItems = BacklogList()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        gameItems = try container.decodeIfPresent(BacklogList.self, forKey: .gameItems)
            ?? Self.mergeLegacyGameLists(from: container)
        bookItems = try container.decodeIfPresent(BacklogList.self, forKey: .bookItems) ?? BacklogList()
        comicsItems = try container.decodeIfPresent(BacklogList.self, forKey: .comicsItems) ?? BacklogList()
        legoItems = try container.decodeIfPresent(BacklogList.self, forKey: .legoItems) ?? BacklogList()
        boardGameItems = try container.decodeIfPresent(BacklogList.self, forKey: .boardGameItems) ?? BacklogList()
        activityCollectionItems = try container.decodeIfPresent(BacklogList.self, forKey: .activityCollectionItems) ?? BacklogList()
        miniaturePaintingItems = try container.decodeIfPresent(BacklogList.self, forKey: .miniaturePaintingItems) ?? BacklogList()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(gameItems, forKey: .gameItems)
        try container.encode(bookItems, forKey: .bookItems)
        try container.encode(comicsItems, forKey: .comicsItems)
        try container.encode(legoItems, forKey: .legoItems)
        try container.encode(boardGameItems, forKey: .boardGameItems)
        try container.encode(activityCollectionItems, forKey: .activityCollectionItems)
        try container.encode(miniaturePaintingItems, forKey: .miniaturePaintingItems)
    }

    static func == (lhs: BacklogListAll, rhs: BacklogListAll) -> Bool {
        lhs.gameItems == rhs.gameItems
            && lhs.bookItems == rhs.bookItems
            && lhs.comicsItems == rhs.comicsItems
            && lhs.legoItems == rhs.legoItems
            && lhs.boardGameItems == rhs.boardGameItems
            && lhs.activityCollectionItems == rhs.activityCollectionItems
            && lhs.miniaturePaintingItems == rhs.miniaturePaintingItems
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
        case .games:
            return gameItems
        case .books:
            return bookItems
        case .comics:
            return comicsItems
        case .lego:
            return legoItems
        case .boardGames:
            return boardGameItems
        case .activities:
            return activityCollectionItems
        case .miniaturePainting:
            return miniaturePaintingItems
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(gameItems)
        hasher.combine(bookItems)
        hasher.combine(comicsItems)
        hasher.combine(legoItems)
        hasher.combine(boardGameItems)
        hasher.combine(activityCollectionItems)
        hasher.combine(miniaturePaintingItems)
    }

    private static func mergeLegacyGameLists(from container: KeyedDecodingContainer<CodingKeys>) -> BacklogList {
        let legacyLists = [
            try? container.decodeIfPresent(BacklogList.self, forKey: .playstationGameItems),
            try? container.decodeIfPresent(BacklogList.self, forKey: .xboxGameItems),
            try? container.decodeIfPresent(BacklogList.self, forKey: .switchGameItems),
            try? container.decodeIfPresent(BacklogList.self, forKey: .pcGameItems)
        ]
        .compactMap { $0 ?? nil }

        guard !legacyLists.isEmpty else {
            return BacklogList()
        }

        let merged = BacklogList()
        merged.items = legacyLists
            .flatMap(\.items)
            .sorted { $0.task.localizedCaseInsensitiveCompare($1.task) == .orderedAscending }

        if let current = legacyLists
            .map(\.currentItem)
            .first(where: { currentItem in merged.items.contains(where: { $0.id == currentItem.id }) }) {
            merged.currentItem = current
        } else if let firstOpen = merged.items.first(where: { !$0.complete }) {
            merged.currentItem = firstOpen
        }

        return merged
    }
}

struct CollectionSettings: Codable, Hashable {
    var selectedCategories: [Category]
    var hasCompletedOnboarding: Bool

    init(
        selectedCategories: [Category] = [],
        hasCompletedOnboarding: Bool = false,
        preserveOrder: Bool = false
    ) {
        self.selectedCategories = preserveOrder ? Self.validated(selectedCategories) : Self.normalized(selectedCategories)
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }

    func updatedSelection(_ categories: [Category], completedOnboarding: Bool? = nil) -> CollectionSettings {
        CollectionSettings(
            selectedCategories: Self.updatedOrder(
                existing: selectedCategories,
                incoming: categories
            ),
            hasCompletedOnboarding: completedOnboarding ?? hasCompletedOnboarding,
            preserveOrder: true
        )
    }

    func movedSelectedCategories(from source: IndexSet, to destination: Int) -> CollectionSettings {
        var reordered = selectedCategories
        let movingItems = source.map { reordered[$0] }
        for index in source.sorted(by: >) {
            reordered.remove(at: index)
        }

        let insertionIndex = min(destination, reordered.count)
        reordered.insert(contentsOf: movingItems, at: insertionIndex)
        return CollectionSettings(
            selectedCategories: reordered,
            hasCompletedOnboarding: hasCompletedOnboarding,
            preserveOrder: true
        )
    }

    static func loadFromStorage(
        database: SQLiteStorage = .shared,
        legacyStore: UserDefaults = .standard
    ) -> CollectionSettings {
        loadCodableValue(
            forKey: StorageKey.collectionSettings,
            database: database,
            legacyStore: legacyStore,
            defaultValue: CollectionSettings()
        )
    }

    static func saveToStorage(
        settings: CollectionSettings,
        database: SQLiteStorage = .shared
    ) {
        saveCodableValue(settings, forKey: StorageKey.collectionSettings, database: database)
    }

    private static func validated(_ categories: [Category]) -> [Category] {
        var seen = Set<Category>()
        return categories.filter { category in
            guard Category.allCases.contains(category), !seen.contains(category) else {
                return false
            }
            seen.insert(category)
            return true
        }
    }

    private static func normalized(_ categories: [Category]) -> [Category] {
        validated(categories)
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    private static func updatedOrder(existing: [Category], incoming: [Category]) -> [Category] {
        let retained = existing.filter { incoming.contains($0) }
        let newCategories = normalized(incoming.filter { !existing.contains($0) })
        return retained + newCategories
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

enum CompleteCategory: String, CaseIterable, Identifiable, Codable {
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

enum Category: String, CaseIterable, Identifiable, Codable {
    case games
    case books
    case comics
    case lego
    case boardGames
    case activities
    case miniaturePainting

    var id: Self { self }

    var title: String {
        switch self {
        case .games:
            return "Games"
        case .books:
            return "Books"
        case .comics:
            return "Comics"
        case .lego:
            return "LEGO"
        case .boardGames:
            return "Board Games"
        case .activities:
            return "Activities"
        case .miniaturePainting:
            return "Miniature Painting"
        }
    }

    var symbolName: String {
        switch self {
        case .games:
            return "gamecontroller"
        case .books:
            return "books.vertical"
        case .comics:
            return "text.book.closed"
        case .lego:
            return "cube.transparent"
        case .boardGames:
            return "square.grid.3x3.topleft.filled"
        case .activities:
            return "figure.walk"
        case .miniaturePainting:
            return "paintpalette"
        }
    }

    var subtitle: String {
        switch self {
        case .games:
            return "Track what you want to play and what you already finished."
        case .books:
            return "Keep your reading list and mark books as read."
        case .comics:
            return "Follow comic runs and mark issues or volumes as read."
        case .lego:
            return "Track sets you want to build and what is already completed."
        case .boardGames:
            return "Keep board games organized by played and not played."
        case .activities:
            return "Track activities you want to try and the ones you already finished."
        case .miniaturePainting:
            return "Keep miniature painting projects organized from unpainted to finished."
        }
    }

    var addPlaceholder: String {
        switch self {
        case .games:
            return "Add a game"
        case .books:
            return "Add a book"
        case .comics:
            return "Add a comic"
        case .lego:
            return "Add a LEGO set"
        case .boardGames:
            return "Add a board game"
        case .activities:
            return "Add an activity"
        case .miniaturePainting:
            return "Add a miniature project"
        }
    }

    var completedItemLabel: String {
        switch self {
        case .games, .boardGames:
            return "Played"
        case .books, .comics:
            return "Read"
        case .lego:
            return "Built"
        case .activities:
            return "Done"
        case .miniaturePainting:
            return "Painted"
        }
    }

    var openItemLabel: String {
        switch self {
        case .games, .boardGames:
            return "Not played yet"
        case .books, .comics:
            return "Not read yet"
        case .lego:
            return "Not built yet"
        case .activities:
            return "Not done yet"
        case .miniaturePainting:
            return "Not painted yet"
        }
    }

    var completionActionTitle: String {
        switch self {
        case .games, .boardGames:
            return "Mark Played"
        case .books, .comics:
            return "Mark Read"
        case .lego:
            return "Mark Built"
        case .activities:
            return "Mark Done"
        case .miniaturePainting:
            return "Mark Painted"
        }
    }

    var openSectionTitle: String {
        switch self {
        case .games:
            return "To Play"
        case .books, .comics:
            return "To Read"
        case .lego:
            return "To Build"
        case .boardGames:
            return "Not Played Yet"
        case .activities:
            return "To Do"
        case .miniaturePainting:
            return "To Paint"
        }
    }

    var completedSectionTitle: String {
        completedItemLabel
    }

    var mainScreenTitle: String {
        switch self {
        case .games:
            return "Game Collection"
        case .books:
            return "Book Collection"
        case .comics:
            return "Comic Collection"
        case .lego:
            return "LEGO Collection"
        case .boardGames:
            return "Board Games"
        case .activities:
            return "Activities"
        case .miniaturePainting:
            return "Miniature Painting"
        }
    }
}

enum StorageKey {
    static let backlogList = "backlogList"
    static let activityBacklogList = "activityBacklogList"
    static let buyBacklogList = "buyBacklogList"
    static let collectionSettings = "collectionSettings"
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
