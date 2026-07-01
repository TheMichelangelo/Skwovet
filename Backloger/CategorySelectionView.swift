//
//  CategorySelectionView.swift
//  Backloger
//

import SwiftUI

struct CategorySelectionView: View {
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
