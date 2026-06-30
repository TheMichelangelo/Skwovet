//
//  ContentView.swift
//  Backloger
//

import SwiftUI

struct ContentView: View {
    @State private var backlogList = BacklogListAll.loadFromStorage()
    @State private var selectedCategory: Category = .comics
    @State private var completedCategory: CompleteCategory = .uncompleted
    @State private var newTask = ""
    @State private var refreshTick = 0
    @FocusState private var isInputFocused: Bool

    private var currentBacklog: BacklogList {
        backlogList.list(for: selectedCategory)
    }

    private var filteredItems: [BacklogItem] {
        currentBacklog.items.filter { item in
            completedCategory == .completed ? item.complete : !item.complete
        }
    }

    private var completionRatio: Double {
        guard !currentBacklog.items.isEmpty else {
            return 0
        }

        let completedCount = currentBacklog.items.filter(\.complete).count
        return Double(completedCount) / Double(currentBacklog.items.count)
    }

    private var highlightedItem: BacklogItem? {
        if !currentBacklog.currentItem.complete,
           currentBacklog.items.contains(where: { $0.id == currentBacklog.currentItem.id }) {
            return currentBacklog.currentItem
        }

        return currentBacklog.items.first(where: { !$0.complete })
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
        .navigationTitle("Backlog")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            composerBar
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(Category.allCases) { category in
                            Label(category.title, systemImage: category.symbolName)
                                .tag(category)
                        }
                    }
                } label: {
                    Label(selectedCategory.title, systemImage: selectedCategory.symbolName)
                        .labelStyle(.titleAndIcon)
                }
            }

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
                eyebrow: "Backlog",
                title: selectedCategory.title,
                subtitle: "Sort the list, finish the next thing, or let the app pick one for you."
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
                        Text("\(currentBacklog.items.count) items total, \(currentBacklog.items.filter(\.complete).count) finished.")
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
                        title: "Nothing open here",
                        message: "This category is clear. Add a fresh item when you are ready for the next one."
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
                ForEach(CompleteCategory.allCases) { category in
                    Text(category.title).tag(category)
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
                    title: completedCategory == .completed ? "No completed items yet" : "No open items",
                    message: completedCategory == .completed ? "Completed backlog items will appear here." : "Use the field below to add something worth tracking."
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
            Text(completedCategory == .completed ? "Finished" : "Open Items")
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
                Text(item.complete ? "Completed" : "In progress")
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
                    Label("Done", systemImage: "checkmark")
                }
                .tint(AppTheme.secondaryAccent)
            }
        }
    }

    private var composerBar: some View {
        HStack(spacing: 12) {
            TextField("Add a new backlog item", text: $newTask)
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
        let task = newTask.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !task.isEmpty else {
            return
        }

        let newItem = BacklogItem(task: task)
        currentBacklog.items.append(newItem)
        currentBacklog.items.sort { $0.task.localizedCaseInsensitiveCompare($1.task) == .orderedAscending }

        BacklogListAll.saveToStorage(backlogList: backlogList)
        newTask = ""
        refreshTick += 1
    }

    private func setRandomItem() {
        let openItems = currentBacklog.items.filter { !$0.complete }
        guard let randomItem = openItems.randomElement() else {
            return
        }

        currentBacklog.currentItem = randomItem
        BacklogListAll.saveToStorage(backlogList: backlogList)
        refreshTick += 1
    }

    private func removeTask(_ item: BacklogItem) {
        currentBacklog.items.removeAll { $0.id == item.id }

        if currentBacklog.currentItem.id == item.id, let replacement = currentBacklog.items.first(where: { !$0.complete }) {
            currentBacklog.currentItem = replacement
        }

        BacklogListAll.saveToStorage(backlogList: backlogList)
        refreshTick += 1
    }

    private func completeTask(_ item: BacklogItem) {
        guard let index = currentBacklog.items.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        currentBacklog.items[index].complete = true
        currentBacklog.items[index].dateCompleted = Date()

        if currentBacklog.currentItem.id == item.id {
            if let replacement = currentBacklog.items.first(where: { !$0.complete && $0.id != item.id }) {
                currentBacklog.currentItem = replacement
            }
        }

        BacklogListAll.saveToStorage(backlogList: backlogList)
        refreshTick += 1
    }
}

#Preview {
    NavigationStack {
        ContentView()
    }
}
