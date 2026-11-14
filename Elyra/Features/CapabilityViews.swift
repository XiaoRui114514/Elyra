// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI

struct CapabilityList: View {
    let category: String
    @EnvironmentObject private var app: AppEnvironment
    private var additionalFeatures: [String] {
        switch category {
        case "device": ["Artwork model name"]
        case "intelligence": ["Region code & sales region", "Hardware identity recovery"]
        case "advanced": ["CacheData / WAPI / FaceTime Audio", "iPadOS UI identity preset"]
        default: []
        }
    }
    var body: some View {
        List {
            Section { StatusNotice(title: "Capability flags are not hardware", detail: "All features remain visible on iPhone and iPad. System effects are unverified, and system writes require an authorized backend.") }
            ForEach(Capability.all.filter { $0.category == category }) { capability in
                NavigationLink(value: Screen.capability(capability.id)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L(capability.title))
                            SupportBadge(status: .needsConditions)
                        }
                        Spacer()
                        if app.state.favorites.contains(capability.id) { Image(systemName: "star.fill").foregroundStyle(.yellow).accessibilityLabel("Favorite") }
                    }.padding(.vertical, 4)
                }
            }
            if ["device", "intelligence", "advanced"].contains(category) {
                Section("Additional audited features") {
                    ForEach(additionalFeatures, id: \.self) { name in
                        StatusNotice(title: name, detail: "Not migrated. Identity recovery requires an independently verified same-device original. Binary cache changes require a verified cache layout; Elyra does not guess offsets.")
                    }
                }
            }
        }.navigationTitle(L(category.capitalized))
    }
}
struct CapabilityView: View {
    let id: String
    @EnvironmentObject private var app: AppEnvironment
    private var capability: Capability? { Capability.all.first { $0.id == id } }
    var body: some View {
        if let capability {
            List {
                Section {
                    Text(L(capability.detail)).fixedSize(horizontal: false, vertical: true)
                    SupportBadge(status: .needsConditions)
                    StatusNotice(title: "System write unavailable", detail: "No authorized, verified system writer is installed. Imported plists remain local documents. OS build and hardware effects require separate real-device validation.", symbol: "lock.shield")
                }
                Section("Dependencies & risk") {
                    LabeledContent("Risk", value: L(capability.caution ? "High" : "Elevated"))
                    Text("A capability flag cannot add hardware or guarantee Apple service access. System changes may require restart or respring; this build performs neither.")
                    Text("iOS / iPadOS 26.x: unverified. 27.x: unverified. Each build requires separate device testing.")
                }
                Section("Affected CacheExtra keys") { ForEach(capability.keys, id: \.self) { Text($0).font(.system(.caption, design: .monospaced)).textSelection(.enabled) } }
                Section("Stage in a local document") {
                    Text("Choose an imported file to preview this preset. Review and confirmation happen in the document editor. No system file is modified.").font(.caption).foregroundStyle(.secondary)
                    ForEach(app.state.documents) { document in
                        NavigationLink(document.name) { DocumentEditor(id: document.id, initialCapability: capability) }
                    }
                    if app.state.documents.isEmpty { Text("Import a MobileGestalt plist in System first.") }
                }
                if id == "dynamicIsland" { Section { NavigationLink("Dynamic Island Lab", value: Screen.island) } }
            }
            .navigationTitle(L(capability.title))
            .toolbar {
                Button { app.run { try await $0.toggleFavorite(id) } } label: {
                    Label("Favorite", systemImage: app.state.favorites.contains(id) ? "star.fill" : "star")
                }
            }
        } else { ContentUnavailableView("Feature not found", systemImage: "questionmark.circle") }
    }
}
