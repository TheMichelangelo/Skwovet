//
//  AppTheme.swift
//  Backloger
//

import SwiftUI

enum AppTheme {
    static let backgroundTop = Color(red: 0.07, green: 0.11, blue: 0.19)
    static let backgroundBottom = Color(red: 0.89, green: 0.94, blue: 0.98)
    static let accent = Color(red: 0.14, green: 0.48, blue: 0.88)
    static let secondaryAccent = Color(red: 0.10, green: 0.72, blue: 0.63)
    static let warmAccent = Color(red: 0.98, green: 0.56, blue: 0.28)
    static let cardFill = Color.white.opacity(0.72)
    static let stroke = Color.white.opacity(0.35)
    static let shadow = Color.black.opacity(0.12)
}

struct AppGradientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                AppTheme.backgroundTop,
                Color(red: 0.29, green: 0.45, blue: 0.76),
                AppTheme.backgroundBottom
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppTheme.cardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(AppTheme.stroke, lineWidth: 1)
                    )
                    .shadow(color: AppTheme.shadow, radius: 16, y: 10)
            )
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCardModifier())
    }
}

struct MetricPill: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous)
                .fill(tint.opacity(0.14))
        )
    }
}

struct EmptyStateCard: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
            Text(title)
                .font(.headline.weight(.semibold))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .glassCard()
    }
}

struct ScreenTitle: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow.uppercased())
                .font(.caption.weight(.bold))
                .kerning(1.2)
                .foregroundStyle(Color.white.opacity(0.78))
            Text(title)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.78))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
}
