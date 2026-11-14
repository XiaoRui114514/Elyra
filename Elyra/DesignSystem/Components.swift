// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI

struct StatusNotice: View {
    @EnvironmentObject private var localization: LocalizationStore
    var title: String
    var detail: String
    var symbol = "info.circle"
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(localization.text(title), systemImage: symbol).font(.headline)
            Text(localization.text(detail)).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }
}
struct FeatureLabel: View {
    @EnvironmentObject private var localization: LocalizationStore
    @ScaledMetric(relativeTo: .title3) private var scaledSymbolSize: CGFloat = 22
    let title: String
    let detail: String
    let symbol: String
    var localizesTitle = true
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol).font(.system(size: min(scaledSymbolSize, 36))).foregroundStyle(.tint).frame(width: min(scaledSymbolSize, 36) + 6).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(localizesTitle ? localization.text(title) : title).foregroundStyle(.primary)
                Text(localization.text(detail)).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }.padding(.vertical, 5).frame(minHeight: 44)
    }
}
struct SupportBadge: View {
    @EnvironmentObject private var localization: LocalizationStore
    let status: SupportStatus
    var body: some View {
        Label(localization.text(status.rawValue), systemImage: status == .supported ? "checkmark.circle" : "info.circle")
            .font(.caption).foregroundStyle(status == .supported ? Color.green : Color.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
