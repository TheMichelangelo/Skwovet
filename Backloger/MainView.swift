//
//  MainView.swift
//  Backloger
//

import SwiftUI
import UniformTypeIdentifiers

private enum Destination: Hashable {
    case day
    case buy
    case collection(Category)
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

    private let utilityDestinations: [(title: String, subtitle: String?, icon: String, tint: Color, route: Destination)] = [
        ("Today", "Check today activity plans", "sun.max.fill", AppTheme.warmAccent, .day),
        ("Wish-\nlist", nil, "bag.fill", AppTheme.secondaryAccent, .buy)
    ]

    private var selectedCategories: [Category] {
        collectionSettings.selectedCategories
    }

    private var needsFirstLaunchSelection: Bool {
        !collectionSettings.hasCompletedOnboarding
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppGradientBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        headerSection

                        utilitySection
                        collectionOverviewCard
                        collectionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .navigationDestination(for: Destination.self) { destination in
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
                    onExport: {
                        backupDocument = BacklogBackupTransfer.makeBackupDocument()
                        isExportingBackup = true
                    },
                    onImport: {
                        isImportingBackup = true
                    }
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

    private var headerSection: some View {
        HStack(alignment: .top) {
            Text("My Collections")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Button {
                isShowingSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.16), in: Circle())
            }
            .accessibilityLabel("Settings")
        }
    }

    private var collectionOverviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your collection setup")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text(selectedCategories.isEmpty ? "Pick at least one category to get started." : "\(selectedCategories.count) categories active on your home screen.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppTheme.accent)
            }

            HStack(spacing: 10) {
                MetricPill(title: "Categories", value: "\(selectedCategories.count)", tint: AppTheme.accent)
                MetricPill(title: "Mode", value: "Flexible", tint: AppTheme.secondaryAccent)
            }

            Button {
                isShowingCategoryManager = true
            } label: {
                Label("Add or Remove Collection", systemImage: "slider.horizontal.3")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
        }
        .glassCard()
    }

    private var collectionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Collections")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            if selectedCategories.isEmpty {
                EmptyStateCard(
                    systemImage: "square.stack.3d.up.slash",
                    title: "No categories selected",
                    message: "Add one or more collection types and they will appear here."
                )
            } else {
                ForEach(selectedCategories) { category in
                    NavigationLink(value: Destination.collection(category)) {
                        HomeCard(
                            title: category.mainScreenTitle,
                            subtitle: category.subtitle,
                            icon: category.symbolName,
                            tint: AppTheme.accent
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var utilitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 14),
                GridItem(.flexible(), spacing: 14)
            ], spacing: 14) {
                ForEach(utilityDestinations, id: \.title) { destination in
                    NavigationLink(value: destination.route) {
                        UtilitySquareCard(
                            title: destination.title,
                            subtitle: destination.subtitle,
                            icon: destination.icon,
                            tint: destination.tint
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
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
}

private struct UtilitySquareCard: View {
    let title: String
    let subtitle: String?
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(tint.opacity(0.14))
                        .frame(width: 55, height: 55)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(tint)
                }

                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

            }

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineSpacing(1)
            }
        }
        .padding(4)
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
        .contentShape(Rectangle())
        .glassCard()
    }
}

private struct SettingsView: View {
    let onExport: () -> Void
    let onImport: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var versionText: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "Version \(shortVersion) (\(buildNumber))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppGradientBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        ScreenTitle(
                            eyebrow: "Settings",
                            title: "Data",
                            subtitle: "Export everything to one JSON backup or import data from an existing backup."
                        )

                        VStack(alignment: .leading, spacing: 16) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Backup your data")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                    Text("Keep your collections safe and restore them on a new install whenever you need.")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "externaldrive.badge.icloud")
                                    .font(.system(size: 28))
                                    .foregroundStyle(AppTheme.secondaryAccent)
                            }

                            HStack(spacing: 12) {
                                Button {
                                    dismiss()
                                    onExport()
                                } label: {
                                    Label("Export JSON", systemImage: "square.and.arrow.up")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(AppTheme.secondaryAccent)

                                Button {
                                    dismiss()
                                    onImport()
                                } label: {
                                    Label("Import JSON", systemImage: "square.and.arrow.down")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .tint(AppTheme.accent)
                            }
                        }
                        .glassCard()
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 24)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Text(versionText)
                    .font(.footnote)
                    .foregroundStyle(Color.white.opacity(0.72))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.black.opacity(0.08))
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct HomeCard: View {
    let title: String
    let subtitle: String
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
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
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
            workingSelection.append(category)
        }

        workingSelection = Category.allCases.filter { workingSelection.contains($0) }
    }
}

#Preview {
    MainView()
}
