//
//  ShopListView.swift
//  Backloger
//

import SwiftUI

struct ShopListView: View {
    @State private var items = BuyListStorage.load()
    @State private var newTask = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            AppGradientBackground()

            List {
                titleSection
                summarySection
                itemsSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Wishlist")
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
                eyebrow: "Shopping",
                title: "Wishlist",
                subtitle: "A quick place to park purchases before they disappear from your head."
            )
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }

    private var summarySection: some View {
        Section {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ready to pick up")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text(items.isEmpty ? "Your list is empty right now." : "\(items.count) items waiting.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                MetricPill(
                    title: "Count",
                    value: "\(items.count)",
                    tint: AppTheme.secondaryAccent
                )
            }
            .glassCard()
            .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
            .listRowBackground(Color.clear)
        }
    }

    private var itemsSection: some View {
        Section("Items") {
            if items.isEmpty {
                EmptyStateCard(
                    systemImage: "bag.badge.plus",
                    title: "Nothing to buy",
                    message: "Add an item below and it will show up here."
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                .listRowBackground(Color.clear)
            } else {
                ForEach(items) { item in
                    HStack(spacing: 14) {
                        Image(systemName: "bag")
                            .font(.title3)
                            .foregroundStyle(AppTheme.secondaryAccent)
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
                    .swipeActions {
                        Button(role: .destructive) {
                            removeTask(item)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
        }
    }

    private var composerBar: some View {
        HStack(spacing: 12) {
            TextField("Add a new item", text: $newTask)
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
            .tint(AppTheme.secondaryAccent)
            .disabled(newTask.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
    }

    private func addTask() {
        guard BuyListLogic.addTask(newTask, to: &items) else {
            return
        }
        BuyListStorage.save(items)
        newTask = ""
    }

    private func removeTask(_ item: BacklogItem) {
        BuyListLogic.removeTask(item, from: &items)
        BuyListStorage.save(items)
    }
}

#Preview {
    NavigationStack {
        ShopListView()
    }
}
