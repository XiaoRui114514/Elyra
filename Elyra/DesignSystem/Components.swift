// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI

struct StatusNotice: View {
    var title: String
    var detail: String
    var symbol = "info.circle"
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(L(title), systemImage: symbol).font(.headline)
            Text(L(detail)).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }
}
struct FeatureLabel: View {
    let title: String
    let detail: String
    let symbol: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol).font(.title3).foregroundStyle(.tint).frame(width: 28).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(L(title)).foregroundStyle(.primary)
                Text(L(detail)).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }.padding(.vertical, 5).frame(minHeight: 44)
    }
}
struct SupportBadge: View {
    let status: SupportStatus
    var body: some View {
        Label(L(status.rawValue), systemImage: status == .supported ? "checkmark.circle" : "info.circle")
            .font(.caption).foregroundStyle(status == .supported ? Color.green : Color.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
