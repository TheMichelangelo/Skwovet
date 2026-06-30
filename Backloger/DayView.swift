//
//  DayView.swift
//  Backloger
//

import SwiftUI

struct DayView: View {
    @State private var backlogList = ActivityBacklogListAll.preparedForToday()
    @State private var newTask = ""
    @State private var refreshTick = 0
    @FocusState private var isInputFocused: Bool

    private let calendar = Calendar.current

    private var todayIndex: Int {
        DayLogic.todayIndex(in: backlogList, calendar: calendar)
    }

    private var todayBacklog: DayActivityBacklogList {
        backlogList.days[todayIndex]
    }

    private var openItems: [ActivityBacklogItem] {
        DayLogic.openItems(in: todayBacklog)
    }

    private var progress: Double {
        DayLogic.completionRatio(for: todayBacklog)
    }

    private var previousDays: [DayActivityBacklogList] {
        DayLogic.previousDays(in: backlogList, calendar: calendar)
    }

    var body: some View {
        ZStack {
            AppGradientBackground()

            List {
                titleSection
                todaySection
                historySection
            }
            .id(refreshTick)
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Today")
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
                eyebrow: "Daily Focus",
                title: "Today",
                subtitle: "Unfinished activities roll forward so the plan stays realistic."
            )
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }

    private var todaySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Today's rhythm")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Text("\(openItems.count) open activities left for today.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    MetricPill(
                        title: "Progress",
                        value: "\(Int((progress * 100).rounded()))%",
                        tint: AppTheme.warmAccent
                    )
                }

                ProgressView(value: progress)
                    .tint(AppTheme.warmAccent)

                if openItems.isEmpty {
                    EmptyStateCard(
                        systemImage: "sun.max.fill",
                        title: "Today is clear",
                        message: "Everything scheduled for today is done. Add another activity if you want to keep the streak going."
                    )
                } else {
                    VStack(spacing: 12) {
                        ForEach(openItems) { item in
                            activityRow(item)
                        }
                    }
                }
            }
            .glassCard()
            .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
            .listRowBackground(Color.clear)
        }
    }

    private var historySection: some View {
        Section("History") {
            if previousDays.isEmpty {
                EmptyStateCard(
                    systemImage: "clock.arrow.circlepath",
                    title: "No history yet",
                    message: "Older daily lists will appear here as you use the app."
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                .listRowBackground(Color.clear)
            } else {
                ForEach(previousDays, id: \.currentDate) { day in
                    ExpandableListItemView(
                        title: day.currentDate.formatted(date: .abbreviated, time: .omitted),
                        items: day.items
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                    .listRowBackground(Color.clear)
                }
            }
        }
    }

    private func activityRow(_ item: ActivityBacklogItem) -> some View {
        HStack(spacing: 14) {
            Image(systemName: item.complete ? "checkmark.circle.fill" : "circle.dashed")
                .font(.title3)
                .foregroundStyle(item.complete ? AppTheme.secondaryAccent : AppTheme.warmAccent)

            Text(item.task)
                .font(.body.weight(.medium))

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
            Button {
                completeTask(item)
            } label: {
                Label("Done", systemImage: "checkmark")
            }
            .tint(AppTheme.secondaryAccent)
        }
    }

    private var composerBar: some View {
        HStack(spacing: 12) {
            TextField("Add a new activity", text: $newTask)
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
            .tint(AppTheme.warmAccent)
            .disabled(newTask.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
    }

    private func addTask() {
        guard DayLogic.addTask(newTask, to: todayBacklog) else {
            return
        }

        ActivityBacklogListAll.saveToStorage(backlogList: backlogList)
        newTask = ""
        refreshTick += 1
    }

    private func removeTask(_ item: ActivityBacklogItem) {
        DayLogic.removeTask(item, from: todayBacklog)
        ActivityBacklogListAll.saveToStorage(backlogList: backlogList)
        refreshTick += 1
    }

    private func completeTask(_ item: ActivityBacklogItem) {
        DayLogic.completeTask(item, in: todayBacklog)
        ActivityBacklogListAll.saveToStorage(backlogList: backlogList)
        refreshTick += 1
    }
}

#Preview {
    NavigationStack {
        DayView()
    }
}
