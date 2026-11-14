// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI

struct SystemOverview: View {
    @EnvironmentObject private var localization: LocalizationStore
    @EnvironmentObject private var app: AppEnvironment
    private let categories = [("display","Display","sun.max"),("device","Device","iphone"),("ipad","iPad","ipad.landscape"),("intelligence","Intelligence","sparkle"),("advanced","Advanced","gearshape.2")]
    var body: some View {
        Section {
            NavigationLink(value: Screen.device) {
                HStack(spacing: 14) {
                    Image(systemName: "cpu").font(.title).foregroundStyle(.tint).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Device configuration").font(.headline)
                        Text(localization.text(app.deviceSnapshot?.writable == true ? "Device write access ready" : "Connect, review and apply system changes")).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }.padding(.vertical, 8)
            }.accessibilityIdentifier("system.device")
        }
        Section("System features") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), alignment: .top)], alignment: .leading, spacing: 16) {
                ForEach(categories, id: \.0) { category in
                    NavigationLink(value: Screen.category(category.0)) {
                        VStack(alignment: .leading, spacing: 12) {
                            Image(systemName: category.2).font(.title2).foregroundStyle(.tint).accessibilityHidden(true)
                            Text(localization.text(category.1)).font(.headline).foregroundStyle(.primary)
                            Text(Capability.all.filter { $0.category == category.0 }.count, format: .number).font(.caption).foregroundStyle(.secondary)
                        }.frame(maxWidth: .infinity, minHeight: 80, alignment: .leading).padding(16)
                            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
                    }.buttonStyle(.plain)
                }
            }.padding(.vertical, 4).listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0)).listRowBackground(Color.clear)
        }
        Section("Configuration tools") {
            NavigationLink(value: Screen.island) { Label("Dynamic Island", systemImage: "capsule") }.accessibilityIdentifier("system.island")
            NavigationLink(value: Screen.diagnostics) { Label("Device diagnostics", systemImage: "stethoscope") }
        }
    }
}
