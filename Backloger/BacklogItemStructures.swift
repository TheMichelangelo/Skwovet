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
    
    static func loadFromStorage() -> BacklogListAll {
        if let data = UserDefaults.standard.data(forKey: StorageKey.backlogList) {
            let decoder = JSONDecoder()
            if let decodedTasks = try? decoder.decode(BacklogListAll.self, from: data) {
                return decodedTasks
            }
            return BacklogListAll()
        }
        return BacklogListAll()
    }
    
    static func saveToStorage(backlogList: BacklogListAll) {
        if let encoded = try? JSONEncoder().encode(backlogList) {
            UserDefaults.standard.set(encoded, forKey: StorageKey.backlogList)
        }
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
    
    static func loadFromStorage() -> ActivityBacklogListAll {
        if let data = UserDefaults.standard.data(forKey: StorageKey.activityBacklogList) {
            let decoder = JSONDecoder()
            if let decodedTasks = try? decoder.decode(ActivityBacklogListAll.self, from: data) {
                return decodedTasks
            }
            return ActivityBacklogListAll()
        }
        return ActivityBacklogListAll()
    }
    
    static func saveToStorage(backlogList: ActivityBacklogListAll) {
        if let encoded = try? JSONEncoder().encode(backlogList) {
            UserDefaults.standard.set(encoded, forKey: StorageKey.activityBacklogList)
        }
    }

    static func preparedForToday(calendar: Calendar = .current) -> ActivityBacklogListAll {
        let backlogList = loadFromStorage()

        guard !backlogList.days.isEmpty else {
            backlogList.days = [DayActivityBacklogList()]
            return backlogList
        }

        let today = Date()
        if backlogList.days.contains(where: { calendar.isDate($0.currentDate, inSameDayAs: today) }) {
            backlogList.days.sort { $0.currentDate > $1.currentDate }
            return backlogList
        }

        let unfinishedItems = backlogList.days[0].items.filter { !$0.complete }
        let newDay = DayActivityBacklogList(items: unfinishedItems)
        backlogList.days.append(newDay)
        backlogList.days.sort { $0.currentDate > $1.currentDate }
        saveToStorage(backlogList: backlogList)
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
    static func load() -> [BacklogItem] {
        guard let data = UserDefaults.standard.data(forKey: StorageKey.buyBacklogList) else {
            return []
        }

        let decoder = JSONDecoder()
        return (try? decoder.decode([BacklogItem].self, from: data)) ?? []
    }
    
    static func save(_ items: [BacklogItem]) {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: StorageKey.buyBacklogList)
        }
    }
}
