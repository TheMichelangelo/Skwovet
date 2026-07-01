//
//  ContentView.swift
//  Backloger
//

import SwiftUI

struct ContentView: View {
    let category: Category

    @State private var backlogList = BacklogListAll.loadFromStorage()
    @State private var completedCategory: CompleteCategory = .uncompleted
    @State private var newTask = ""
    @State private var refreshTick = 0
    @FocusState private var isInputFocused: Bool

    private var currentBacklog: BacklogList {
        backlogList.list(for: category)
    }

    private var filteredItems: [BacklogItem] {
        BacklogLogic.filteredItems(in: currentBacklog, status: completedCategory)
    }

    private var completionRatio: Double {
        BacklogLogic.completionRatio(for: currentBacklog)
    }

    private var highlightedItem: BacklogItem? {
        BacklogLogic.highlightedItem(in: currentBacklog)
    }

    private var summaryLine: String {
        let completedCount = currentBacklog.items.filter(\.complete).count
        return "\(currentBacklog.items.count) items total, \(completedCount) \(category.completedItemLabel.lowercased())."
    }

    var body: some View {
        ZStack {
            AppGradientBackground()

            List {
                titleSection
                summarySection
                filtersSection
                itemsSection
            }
            .id(refreshTick)
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            composerBar
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isInputFocused = false
                }
            }
        }
    }

    private var titleSection: some View {
        Section {
            ScreenTitle(
                eyebrow: "Collection",
                title: category.title,
                subtitle: category.subtitle
            )
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }

    private var summarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Collection status")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Text(summaryLine)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    MetricPill(
                        title: "Progress",
                        value: "\(Int((completionRatio * 100).rounded()))%",
                        tint: AppTheme.accent
                    )
                }

                ProgressView(value: completionRatio)
                    .tint(AppTheme.accent)

                if let highlightedItem {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Current focus", systemImage: "sparkles")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(highlightedItem.task)
                            .font(.headline)
                        Button {
                            setRandomItem()
                        } label: {
                            Label("Pick Another", systemImage: "shuffle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.secondaryAccent)
                    }
                } else {
                    EmptyStateCard(
                        systemImage: "party.popper.fill",
                        title: "Nothing waiting here",
                        message: "This collection is clear. Add something new whenever you are ready."
                    )
                }
            }
            .glassCard()
            .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
            .listRowBackground(Color.clear)
        }
    }

    private var filtersSection: some View {
        Section {
            Picker("Status", selection: $completedCategory) {
                ForEach(CompleteCategory.allCases) { status in
                    Text(status.title).tag(status)
                }
            }
            .pickerStyle(.segmented)
            .padding(.vertical, 4)
            .listRowBackground(Color.clear)
        }
    }

    private var itemsSection: some View {
        Section {
            if filteredItems.isEmpty {
                EmptyStateCard(
                    systemImage: completedCategory == .completed ? "checkmark.seal.fill" : "square.stack.3d.up.slash",
                    title: completedCategory == .completed ? "Nothing marked \(category.completedItemLabel.lowercased()) yet" : "No open items",
                    message: completedCategory == .completed ? "\(category.completedSectionTitle) items will appear here." : "Use the field below to add something worth tracking."
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                .listRowBackground(Color.clear)
            } else {
                ForEach(filteredItems) { item in
                    itemRow(item)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            }
        } header: {
            Text(completedCategory == .completed ? category.completedSectionTitle : category.openSectionTitle)
        }
    }

    private func itemRow(_ item: BacklogItem) -> some View {
        HStack(spacing: 14) {
            Image(systemName: item.complete ? "checkmark.circle.fill" : "circle.dashed")
                .font(.title3)
                .foregroundStyle(item.complete ? AppTheme.secondaryAccent : AppTheme.accent)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.task)
                    .font(.body.weight(.medium))
                Text(item.complete ? category.completedItemLabel : category.openItemLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.66))
        )
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(role: .destructive) {
                removeTask(item)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if !item.complete {
                Button {
                    completeTask(item)
                } label: {
                    Label(category.completionActionTitle, systemImage: "checkmark")
                }
                .tint(AppTheme.secondaryAccent)
            }
        }
    }

    private var composerBar: some View {
        HStack(spacing: 12) {
            TextField(category.addPlaceholder, text: $newTask)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($isInputFocused)
                .onSubmit(addTask)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial)
                )

            Button(action: addTask) {
                Image(systemName: "plus")
                    .font(.headline.weight(.bold))
                    .frame(width: 50, height: 50)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .disabled(newTask.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
    }

    private func addTask() {
        guard BacklogLogic.addTask(newTask, to: currentBacklog) else {
            return
        }

        BacklogListAll.saveToStorage(backlogList: backlogList)
        newTask = ""
        refreshTick += 1
    }

    private func setRandomItem() {
        guard BacklogLogic.setRandomCurrentItem(in: currentBacklog) != nil else {
            return
        }

        BacklogListAll.saveToStorage(backlogList: backlogList)
        refreshTick += 1
    }

    private func removeTask(_ item: BacklogItem) {
        BacklogLogic.removeTask(item, from: currentBacklog)
        BacklogListAll.saveToStorage(backlogList: backlogList)
        refreshTick += 1
    }

    private func completeTask(_ item: BacklogItem) {
        BacklogLogic.completeTask(item, in: currentBacklog)
        BacklogListAll.saveToStorage(backlogList: backlogList)
        refreshTick += 1
    }
}

#Preview {
    NavigationStack {
        ContentView(category: .games)
    }
}
