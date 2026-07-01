//
//  SettingsView.swift
//  Backloger
//

import SwiftUI

struct SettingsView: View {
    let onExport: () -> Void
    let onImport: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var versionText: String {
        SettingsVersionFormatter.versionText(
            shortVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            buildNumber: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        )
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
