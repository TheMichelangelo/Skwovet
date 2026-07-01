import XCTest
@testable import Backloger

final class BacklogLogicTests: XCTestCase {
    func testCategoryMetadataIsAvailable() {
        XCTAssertEqual(Category.books.title, "Books")
        XCTAssertEqual(Category.games.symbolName, "gamecontroller")
        XCTAssertEqual(Category.lego.completionActionTitle, "Mark Built")
        XCTAssertEqual(Category.boardGames.mainScreenTitle, "Board Games")
        XCTAssertEqual(Category.activities.openSectionTitle, "To Do")
        XCTAssertEqual(Category.miniaturePainting.completedItemLabel, "Painted")
        XCTAssertEqual(CompleteCategory.uncompleted.title, "Open")
    }

    func testMainUtilityItemsExposeExpectedHomeConfiguration() {
        XCTAssertEqual(MainUtilityItem.all.count, 2)
        XCTAssertEqual(MainUtilityItem.all[0].title, "Today")
        XCTAssertEqual(MainUtilityItem.all[0].subtitle, "Check today activity plans")
        XCTAssertEqual(MainUtilityItem.all[0].route, .day)
        XCTAssertEqual(MainUtilityItem.all[1].title, "Wish-\nlist")
        XCTAssertNil(MainUtilityItem.all[1].subtitle)
        XCTAssertEqual(MainUtilityItem.all[1].route, .buy)
    }

    func testMainViewPresentationBuildsCollectionSummary() {
        XCTAssertEqual(
            MainViewPresentation.collectionSummary(for: 0),
            "Pick at least one category to get started."
        )
        XCTAssertEqual(
            MainViewPresentation.collectionSummary(for: 3),
            "3 categories active on your home screen."
        )
    }

    func testSettingsVersionFormatterFallsBackWhenValuesAreMissing() {
        XCTAssertEqual(
            SettingsVersionFormatter.versionText(shortVersion: nil, buildNumber: nil),
            "Version 1.0 (1)"
        )
        XCTAssertEqual(
            SettingsVersionFormatter.versionText(shortVersion: " 2.5 ", buildNumber: " 17 "),
            "Version 2.5 (17)"
        )
    }

    func testCollectionSettingsDefaultsToAlphabeticalSelectionOrder() {
        let settings = CollectionSettings(
            selectedCategories: [.miniaturePainting, .books, .activities],
            hasCompletedOnboarding: false
        )

        XCTAssertEqual(settings.selectedCategories, [.activities, .books, .miniaturePainting])
    }

    func testCollectionSettingsPreservesManualOrderWhenAddingNewCategory() {
        let settings = CollectionSettings(
            selectedCategories: [.games, .books, .lego],
            hasCompletedOnboarding: true
        )
        let reordered = settings.movedSelectedCategories(from: IndexSet(integer: 2), to: 0)

        let updated = reordered.updatedSelection([.lego, .games, .books, .activities])

        XCTAssertEqual(updated.selectedCategories, [.lego, .games, .books, .activities])
    }

    func testListForCategoryReturnsMatchingStoredList() {
        let allLists = BacklogListAll()
        let games = BacklogItem(task: "Zelda")
        let comics = BacklogItem(task: "Comic")
        let activity = BacklogItem(task: "Kayaking")
        let miniature = BacklogItem(task: "Space Marine Captain")
        allLists.gameItems.items = [games]
        allLists.comicsItems.items = [comics]
        allLists.activityCollectionItems.items = [activity]
        allLists.miniaturePaintingItems.items = [miniature]

        XCTAssertEqual(allLists.list(for: .games).items.first?.task, "Zelda")
        XCTAssertEqual(allLists.list(for: .comics).items.first?.task, "Comic")
        XCTAssertEqual(allLists.list(for: .activities).items.first?.task, "Kayaking")
        XCTAssertEqual(allLists.list(for: .miniaturePainting).items.first?.task, "Space Marine Captain")
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
