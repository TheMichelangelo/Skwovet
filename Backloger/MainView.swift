//
//  MainView.swift
//  Backloger
//

import SwiftUI

private enum Destination: Hashable {
    case day
    case backlog
    case buy
}

struct MainView: View {
    private let destinations: [(title: String, subtitle: String, icon: String, tint: Color, route: Destination)] = [
        ("Today", "Carry unfinished activities into a fresh daily plan.", "sun.max.fill", AppTheme.warmAccent, .day),
        ("Backlog", "Track books, comics, games, and personal goals.", "square.stack.3d.up.fill", AppTheme.accent, .backlog),
        ("Buy List", "Keep a clean shortlist of things worth picking up.", "bag.fill", AppTheme.secondaryAccent, .buy)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppGradientBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        ScreenTitle(
                            eyebrow: "Personal Tracker",
                            title: "BackLogger",
                            subtitle: "A calmer home for your backlog, daily focus, and things to buy."
                        )

                        heroCard

                        VStack(spacing: 14) {
                            ForEach(destinations, id: \.title) { destination in
                                NavigationLink(value: destination.route) {
                                    HomeCard(
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
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .day:
                    DayView()
                case .backlog:
                    ContentView()
                case .buy:
                    ShopListView()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Keep momentum")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("The app is now organized around quick actions, softer hierarchy, and modern SwiftUI navigation.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppTheme.accent)
            }

            HStack(spacing: 10) {
                MetricPill(title: "App", value: "Local-first", tint: AppTheme.accent)
                MetricPill(title: "Focus", value: "Simple routines", tint: AppTheme.secondaryAccent)
            }
        }
        .glassCard()
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

            Spacer()

            Image(systemName: "arrow.up.right")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .glassCard()
    }
}

#Preview {
    MainView()
}
