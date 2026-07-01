//
//  MainView.swift
//  Backloger
//

import SwiftUI
import UniformTypeIdentifiers

enum MainDestination: Hashable {
    case day
    case buy
    case collection(Category)
}

struct MainUtilityItem: Identifiable, Hashable {
    let title: String
    let subtitle: String?
    let icon: String
    let tint: Color
    let route: MainDestination

    var id: String { title }

    static let all: [MainUtilityItem] = [
        MainUtilityItem(
            title: "Today",
            subtitle: "Check today activity plans",
            icon: "sun.max.fill",
            tint: AppTheme.warmAccent,
            route: .day
        ),
        MainUtilityItem(
            title: "Wish-\nlist",
            subtitle: nil,
            icon: "bag.fill",
            tint: AppTheme.secondaryAccent,
            route: .buy
        )
    ]
}

struct MainViewPresentation {
    static func collectionSummary(for selectedCount: Int) -> String {
        selectedCount == 0
            ? "Pick at least one category to get started."
            : "\(selectedCount) categories active on your home screen."
    }
}

struct SettingsVersionFormatter {
    static func versionText(shortVersion: String?, buildNumber: String?) -> String {
        let resolvedShortVersion = shortVersion?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedBuildNumber = buildNumber?.trimmingCharacters(in: .whitespacesAndNewlines)

        let short = resolvedShortVersion?.isEmpty == false ? resolvedShortVersion! : "1.0"
        let build = resolvedBuildNumber?.isEmpty == false ? resolvedBuildNumber! : "1"
        return "Version \(short) (\(build))"
    }
}

struct MainView: View {
    @State private var collectionSettings = CollectionSettings.loadFromStorage()
    @State private var isShowingCategoryManager = false
    @State private var isShowingSettings = false
    @State private var isImportingBackup = false
    @State private var isExportingBackup = false
    @State private var backupDocument = BacklogBackupTransfer.makeBackupDocument()
    @State private var transferMessage = ""
    @State private var isShowingTransferAlert = false

    private let utilityItems = MainUtilityItem.all

    private var selectedCategories: [Category] {
        collectionSettings.selectedCategories
    }

    private var needsFirstLaunchSelection: Bool {
        !collectionSettings.hasCompletedOnboarding
    }

    private var collectionSummary: String {
        MainViewPresentation.collectionSummary(for: selectedCategories.count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppGradientBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        MainHeaderView {
                            isShowingSettings = true
                        }

                        MainUtilityGrid(items: utilityItems)
                        CollectionOverviewCard(
                            summary: collectionSummary,
                            selectedCategoryCount: selectedCategories.count,
                            onManageCategories: { isShowingCategoryManager = true }
                        )
                        CollectionsSection(
                            categories: selectedCategories,
                            onMoveCategory: moveCategory,
                            onPersistCategoryOrder: persistCategoryOrder
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .navigationDestination(for: MainDestination.self) { destination in
                switch destination {
                case .day:
                    DayView()
                case .buy:
                    ShopListView()
                case let .collection(category):
                    ContentView(category: category)
                }
            }
            .sheet(isPresented: $isShowingCategoryManager) {
                CategorySelectionView(
                    selectedCategories: collectionSettings.selectedCategories,
                    isFirstLaunch: false,
                    onSave: saveCategories(_:completedOnboarding:)
                )
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView(
                    onExport: startExport,
                    onImport: startImport
                )
            }
            .fullScreenCover(isPresented: onboardingBinding) {
                CategorySelectionView(
                    selectedCategories: collectionSettings.selectedCategories,
                    isFirstLaunch: true,
                    onSave: saveCategories(_:completedOnboarding:)
                )
            }
            .fileImporter(
                isPresented: $isImportingBackup,
                allowedContentTypes: [.json]
            ) { result in
                handleImport(result)
            }
            .fileExporter(
                isPresented: $isExportingBackup,
                document: backupDocument,
                contentType: .json,
                defaultFilename: BacklogBackupTransfer.defaultFilename()
            ) { result in
                handleExport(result)
            }
            .alert("Backup", isPresented: $isShowingTransferAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(transferMessage)
            }
        }
    }

    private var onboardingBinding: Binding<Bool> {
        Binding(
            get: { needsFirstLaunchSelection },
            set: { _ in }
        )
    }

    private func startExport() {
        backupDocument = BacklogBackupTransfer.makeBackupDocument()
        isExportingBackup = true
    }

    private func startImport() {
        isImportingBackup = true
    }

    private func saveCategories(_ categories: [Category], completedOnboarding: Bool) {
        collectionSettings = collectionSettings.updatedSelection(
            categories,
            completedOnboarding: completedOnboarding
        )
        CollectionSettings.saveToStorage(settings: collectionSettings)
        isShowingCategoryManager = false
    }

    private func handleImport(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let data = try Data(contentsOf: url)
            try BacklogBackupTransfer.importBackup(from: data)
            collectionSettings = CollectionSettings.loadFromStorage()
            transferMessage = "Backup imported successfully. Open any collection again to see the restored data."
            isShowingTransferAlert = true
        } catch {
            transferMessage = "Import failed. Please choose a valid BackLogger JSON backup."
            isShowingTransferAlert = true
        }
    }

    private func handleExport(_ result: Result<URL, Error>) {
        switch result {
        case .success:
            transferMessage = "Backup exported successfully."
        case .failure:
            transferMessage = "Export failed. Please try again."
        }

        isShowingTransferAlert = true
    }

    private func moveCategory(from source: IndexSet, to destination: Int) {
        collectionSettings = collectionSettings.movedSelectedCategories(from: source, to: destination)
    }

    private func persistCategoryOrder() {
        CollectionSettings.saveToStorage(settings: collectionSettings)
    }
}

private struct MainHeaderView: View {
    let onOpenSettings: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            Text("My Collections")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Button(action: onOpenSettings) {
                Image(systemName: "gearshape.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.16), in: Circle())
            }
            .accessibilityLabel("Settings")
        }
    }
}

private struct MainUtilityGrid: View {
    let items: [MainUtilityItem]

    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 14),
                GridItem(.flexible(), spacing: 14)
            ],
            spacing: 14
        ) {
            ForEach(items) { item in
                NavigationLink(value: item.route) {
                    UtilityRectangleCard(item: item)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct CollectionOverviewCard: View {
    let summary: String
    let selectedCategoryCount: Int
    let onManageCategories: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your collection setup")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text(summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppTheme.accent)
            }

            HStack(spacing: 10) {
                MetricPill(title: "Categories", value: "\(selectedCategoryCount)", tint: AppTheme.accent)
                MetricPill(title: "Mode", value: "Flexible", tint: AppTheme.secondaryAccent)
            }

            Button(action: onManageCategories) {
                Label("Add or Remove Collection", systemImage: "slider.horizontal.3")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
        }
        .glassCard()
    }
}

private struct CollectionsSection: View {
    let categories: [Category]
    let onMoveCategory: (IndexSet, Int) -> Void
    let onPersistCategoryOrder: () -> Void
    @State private var draggedCategory: Category?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Collections")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            if categories.isEmpty {
                EmptyStateCard(
                    systemImage: "square.stack.3d.up.slash",
                    title: "No categories selected",
                    message: "Add one or more collection types and they will appear here."
                )
            } else {
                ForEach(categories) { category in
                    NavigationLink(value: MainDestination.collection(category)) {
                        HomeCard(
                            title: category.title,
                            icon: category.symbolName,
                            tint: AppTheme.accent
                        )
                    }
                    .buttonStyle(.plain)
                    .opacity(draggedCategory == category ? 0.65 : 1)
                    .onDrag {
                        draggedCategory = category
                        return NSItemProvider(object: NSString(string: category.rawValue))
                    }
                    .onDrop(
                        of: [UTType.plainText],
                        delegate: CollectionOrderDropDelegate(
                            destinationItem: category,
                            items: categories,
                            draggedItem: $draggedCategory,
                            onMove: onMoveCategory,
                            onPersist: onPersistCategoryOrder
                        )
                    )
                }
            }
        }
    }
}

private struct UtilityRectangleCard: View {
    let item: MainUtilityItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(item.tint.opacity(0.14))
                        .frame(width: 55, height: 55)
                    Image(systemName: item.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(item.tint)
                }

                Text(item.title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let subtitle = item.subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineSpacing(1)
            }
        }
        .padding(4)
        .frame(maxWidth: .infinity, minHeight: 115, alignment: .topLeading)
        .contentShape(Rectangle())
        .glassCard()
    }
}

private struct HomeCard: View {
    let title: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(tint.opacity(0.14))
                    .frame(width: 58, height: 58)
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}

private struct CategorySelectionView: View {
    let selectedCategories: [Category]
    let isFirstLaunch: Bool
    let onSave: ([Category], Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var workingSelection: [Category]

    init(
        selectedCategories: [Category],
        isFirstLaunch: Bool,
        onSave: @escaping ([Category], Bool) -> Void
    ) {
        self.selectedCategories = selectedCategories
        self.isFirstLaunch = isFirstLaunch
        self.onSave = onSave
        _workingSelection = State(initialValue: selectedCategories)
    }

    private var isSaveDisabled: Bool {
        isFirstLaunch && workingSelection.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppGradientBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        ScreenTitle(
                            eyebrow: isFirstLaunch ? "First Launch" : "Manage Categories",
                            title: "Choose Collections",
                            subtitle: isFirstLaunch ? "Select everything you collect. You can choose more than one." : "Add or remove collection categories whenever your interests change."
                        )

                        orderNote

                        VStack(spacing: 14) {
                            ForEach(Category.allCases) { category in
                                categoryButton(for: category)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 24)
                }
            }
            .interactiveDismissDisabled(isFirstLaunch)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if !isFirstLaunch {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isFirstLaunch ? "Continue" : "Save") {
                        onSave(workingSelection, true)
                    }
                    .disabled(isSaveDisabled)
                }
            }
        }
    }

    private var orderNote: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Order")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Selected collections can be reordered later from the main screen by holding an item and moving your finger up or down.")
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.78))
        }
        .padding(.horizontal, 20)
    }

    private func categoryButton(for category: Category) -> some View {
        let isSelected = workingSelection.contains(category)

        return Button {
            toggle(category)
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill((isSelected ? AppTheme.secondaryAccent : AppTheme.accent).opacity(0.14))
                        .frame(width: 56, height: 56)
                    Image(systemName: category.symbolName)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(isSelected ? AppTheme.secondaryAccent : AppTheme.accent)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(category.title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(category.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? AppTheme.secondaryAccent : .secondary)
            }
            .glassCard()
            .padding(.horizontal, 20)
        }
        .buttonStyle(.plain)
    }

    private func toggle(_ category: Category) {
        if workingSelection.contains(category) {
            workingSelection.removeAll { $0 == category }
        } else {
            let currentSettings = CollectionSettings(
                selectedCategories: workingSelection,
                hasCompletedOnboarding: isFirstLaunch
            )
            workingSelection = currentSettings.updatedSelection(workingSelection + [category]).selectedCategories
            return
        }

        let currentSettings = CollectionSettings(
            selectedCategories: workingSelection,
            hasCompletedOnboarding: isFirstLaunch
        )
        workingSelection = currentSettings.updatedSelection(workingSelection).selectedCategories
    }
}

private struct CollectionOrderDropDelegate: DropDelegate {
    let destinationItem: Category
    let items: [Category]
    @Binding var draggedItem: Category?
    let onMove: (IndexSet, Int) -> Void
    let onPersist: () -> Void

    func dropEntered(info: DropInfo) {
        guard let draggedItem,
              draggedItem != destinationItem,
              let fromIndex = items.firstIndex(of: draggedItem),
              let toIndex = items.firstIndex(of: destinationItem) else {
            return
        }

        withAnimation {
            onMove(IndexSet(integer: fromIndex), toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        onPersist()
        return true
    }
}

#Preview {
    MainView()
}
