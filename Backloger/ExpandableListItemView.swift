//
//  ExpandableListItemView.swift
//  Backloger
//

import SwiftUI

struct ExpandableListItemView: View {
    @State private var isExpanded = false

    let title: String
    let items: [ActivityBacklogItem]

    private var progress: Double {
        guard !items.isEmpty else {
            return 0
        }

        let completedItemsCount = items.filter(\.complete).count
        return Double(completedItemsCount) / Double(items.count)
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 14) {
                ProgressView(value: progress)
                    .tint(AppTheme.accent)

                ForEach(items, id: \.self) { item in
                    HStack(spacing: 10) {
                        Image(systemName: item.complete ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.complete ? AppTheme.secondaryAccent : AppTheme.warmAccent)
                        Text(item.task)
                            .foregroundStyle(.primary)
                    }
                    .font(.subheadline)
                }
            }
            .padding(.top, 12)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                    Text(L10n.format("%d activities", items.count))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                MetricPill(
                    title: L10n.tr("Done"),
                    value: "\(Int((progress * 100).rounded()))%",
                    tint: AppTheme.accent
                )
            }
        }
        .glassCard()
    }
}

#Preview {
    ExpandableListItemView(
        title: "Jul 1, 2026",
        items: [
            ActivityBacklogItem(task: "Task 1"),
            ActivityBacklogItem(task: "Task 2")
        ]
    )
}
