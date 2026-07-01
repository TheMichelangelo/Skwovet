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
            ? L10n.tr("Pick at least one category to get started.")
            : L10n.format("%d categories active on your home screen.", selectedCount)
    }
}

struct SettingsVersionFormatter {
    static func versionText(shortVersion: String?, buildNumber: String?) -> String {
        let resolvedShortVersion = shortVersion?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedBuildNumber = buildNumber?.trimmingCharacters(in: .whitespacesAndNewlines)

        let short = resolvedShortVersion?.isEmpty == false ? resolvedShortVersion! : "1.0"
        let build = resolvedBuildNumber?.isEmpty == false ? resolvedBuildNumber! : "1"
        return L10n.format("Version %@ (%@)", short, build)
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
            .alert(L10n.tr("Backup"), isPresented: $isShowingTransferAlert) {
                Button(L10n.tr("OK"), role: .cancel) { }
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
            transferMessage = L10n.tr("Backup imported successfully. Open any collection again to see the restored data.")
            isShowingTransferAlert = true
        } catch {
            transferMessage = L10n.tr("Import failed. Please choose a valid BackLogger JSON backup.")
            isShowingTransferAlert = true
        }
    }

    private func handleExport(_ result: Result<URL, Error>) {
        switch result {
        case .success:
            transferMessage = L10n.tr("Backup exported successfully.")
        case .failure:
            transferMessage = L10n.tr("Export failed. Please try again.")
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
            Text(L10n.tr("My Collections"))
                .textCase(nil)
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
            .accessibilityLabel(L10n.tr("Settings"))
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
                    Text(L10n.tr("Your collection setup"))
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
                Button(action: onManageCategories) {
                    Label(L10n.tr("Add or Remove Collection"), systemImage: "slider.horizontal.3")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
            }
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
            Text(L10n.tr("Collections"))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            if categories.isEmpty {
                EmptyStateCard(
                    systemImage: "square.stack.3d.up.slash",
                    title: L10n.tr("No categories selected"),
                    message: L10n.tr("Add one or more collection types and they will appear here.")
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
        ViewThatFits(in: .horizontal) {
            horizontalLayout
            verticalLayout
        }
        .padding(4)
        .frame(maxWidth: .infinity, minHeight: 150, maxHeight: 150, alignment: .topLeading)
        .contentShape(Rectangle())
        .glassCard()
    }

    private var horizontalLayout: some View {
        VStack(alignment: .center, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                iconBadge

                titleText(lineLimit: 2)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            if let subtitle = item.subtitle {
                subtitleText(subtitle, lineLimit: 3)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var verticalLayout: some View {
        VStack(alignment: .center, spacing: 12) {
            iconBadge

            titleText(lineLimit: 3)

            if let subtitle = item.subtitle {
                subtitleText(subtitle, lineLimit: 3)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var iconBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(item.tint.opacity(0.14))
                .frame(width: 55, height: 55)
            Image(systemName: item.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(item.tint)
        }
    }

    private func titleText(lineLimit: Int) -> some View {
        Text(L10n.tr(item.title))
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundStyle(.primary)
            .lineLimit(lineLimit)
            .minimumScaleFactor(0.88)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .lineSpacing(1)
            .layoutPriority(1)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private func subtitleText(_ text: String, lineLimit: Int) -> some View {
        Text(L10n.tr(text))
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(lineLimit)
            .minimumScaleFactor(0.9)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .center)
            .lineSpacing(1)
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
