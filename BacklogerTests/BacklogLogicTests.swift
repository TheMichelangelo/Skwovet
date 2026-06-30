import XCTest
@testable import Backloger

final class BacklogLogicTests: XCTestCase {
    func testCategoryMetadataIsAvailable() {
        XCTAssertEqual(Category.books.title, "Books")
        XCTAssertEqual(Category.games_windows.symbolName, "desktopcomputer")
        XCTAssertEqual(CompleteCategory.uncompleted.title, "Open")
    }

    func testListForCategoryReturnsMatchingStoredList() {
        let allLists = BacklogListAll()
        let books = BacklogItem(task: "Book")
        let comics = BacklogItem(task: "Comic")
        allLists.bookItems.items = [books]
        allLists.comicsItems.items = [comics]

        XCTAssertEqual(allLists.list(for: .books).items.first?.task, "Book")
        XCTAssertEqual(allLists.list(for: .comics).items.first?.task, "Comic")
    }

    func testFilteredItemsAndCompletionRatioReflectCompletionState() {
        let backlog = BacklogList()
        let open = BacklogItem(task: "Open")
        let done = BacklogItem(task: "Done")
        done.complete = true
        backlog.items = [open, done]

        XCTAssertEqual(BacklogLogic.filteredItems(in: backlog, status: .uncompleted).map(\.task), ["Open"])
        XCTAssertEqual(BacklogLogic.filteredItems(in: backlog, status: .completed).map(\.task), ["Done"])
        XCTAssertEqual(BacklogLogic.completionRatio(for: backlog), 0.5, accuracy: 0.0001)
    }

    func testHighlightedItemPrefersCurrentOpenItemThenFallsBackToFirstOpen() {
        let backlog = BacklogList()
        let first = BacklogItem(task: "Alpha")
        let second = BacklogItem(task: "Bravo")
        backlog.items = [first, second]
        backlog.currentItem = second

        XCTAssertEqual(BacklogLogic.highlightedItem(in: backlog)?.id, second.id)

        backlog.currentItem.complete = true
        XCTAssertEqual(BacklogLogic.highlightedItem(in: backlog)?.id, first.id)
    }

    func testAddTaskTrimsSortsAndRejectsBlankInput() {
        let backlog = BacklogList()
        backlog.items = [BacklogItem(task: "Zulu")]

        XCTAssertFalse(BacklogLogic.addTask("   ", to: backlog))
        XCTAssertTrue(BacklogLogic.addTask("  alpha  ", to: backlog))
        XCTAssertEqual(backlog.items.map(\.task), ["alpha", "Zulu"])
    }

    func testSetRandomCurrentItemUsesOnlyOpenItems() {
        let backlog = BacklogList()
        let done = BacklogItem(task: "Done")
        done.complete = true
        let open = BacklogItem(task: "Open")
        backlog.items = [done, open]

        let selected = BacklogLogic.setRandomCurrentItem(in: backlog)

        XCTAssertEqual(selected?.id, open.id)
        XCTAssertEqual(backlog.currentItem.id, open.id)
    }

    func testSetRandomCurrentItemReturnsNilWhenNoOpenItemsExist() {
        let backlog = BacklogList()
        let done = BacklogItem(task: "Done")
        done.complete = true
        backlog.items = [done]

        XCTAssertNil(BacklogLogic.setRandomCurrentItem(in: backlog))
    }

    func testRemoveTaskDeletesItemAndReplacesCurrentWhenPossible() {
        let backlog = BacklogList()
        let current = BacklogItem(task: "Current")
        let replacement = BacklogItem(task: "Replacement")
        backlog.items = [current, replacement]
        backlog.currentItem = current

        BacklogLogic.removeTask(current, from: backlog)

        XCTAssertEqual(backlog.items.map(\.task), ["Replacement"])
        XCTAssertEqual(backlog.currentItem.id, replacement.id)
    }

    func testCompleteTaskMarksDoneSetsDateAndAdvancesCurrentItem() {
        let backlog = BacklogList()
        let current = BacklogItem(task: "Current")
        let replacement = BacklogItem(task: "Replacement")
        backlog.items = [current, replacement]
        backlog.currentItem = current
        let completionDate = Date(timeIntervalSince1970: 123)

        BacklogLogic.completeTask(current, in: backlog, completionDate: completionDate)

        XCTAssertTrue(current.complete)
        XCTAssertEqual(current.dateCompleted, completionDate)
        XCTAssertEqual(backlog.currentItem.id, replacement.id)
    }
}
