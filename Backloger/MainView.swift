//
//  MainView.swift
//  Backloger
//

import SwiftUI
import UniformTypeIdentifiers

private enum Destination: Hashable {
    case day
    case backlog
    case buy
}

struct MainView: View {
    @State private var isImportingBackup = false
    @State private var isExportingBackup = false
    @State private var backupDocument = BacklogBackupTransfer.makeBackupDocument()
    @State private var transferMessage = ""
    @State private var isShowingTransferAlert = false

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
                        backupCard

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

    private var backupCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Backup your data")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("Export everything to one JSON file or import a backup to restore the app on a new install.")
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
                    backupDocument = BacklogBackupTransfer.makeBackupDocument()
                    isExportingBackup = true
                } label: {
                    Label("Export JSON", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.secondaryAccent)

                Button {
                    isImportingBackup = true
                } label: {
                    Label("Import JSON", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.accent)
            }
        }
        .glassCard()
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
            transferMessage = "Backup imported successfully. Open any section again to see the restored data."
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
