// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI

struct SystemCategoryView: View {
    @EnvironmentObject private var localization: LocalizationStore
    @EnvironmentObject private var app: AppEnvironment
    @Environment(\.dynamicTypeSize) private var typeSize
    let category: String
    private var features: [Capability] {
        Capability.all.filter { $0.category == category }.sorted { localization.text($0.title).localizedStandardCompare(localization.text($1.title)) == .orderedAscending }
    }
    var body: some View {
        SystemPage(identifier: "system.category.page") {
            LazyVGrid(columns: typeSize.isAccessibilitySize ? [GridItem(.flexible())] : [GridItem(.adaptive(minimum: 220), spacing: 16)], alignment: .leading, spacing: 16) {
                ForEach(features) { feature in
                    NavigationLink(value: Screen.capability(feature.id)) {
                        SystemTile(title: localization.text(feature.title), detail: localization.text(feature.currentLabel(in: app.deviceSnapshot?.value)), symbol: feature.systemSymbol)
                    }.buttonStyle(.plain).accessibilityIdentifier("system.feature." + feature.id)
                }
            }
        }
        .navigationTitle(localization.text(SystemCategory.find(category).title))
        .task { await app.ensureDeviceConnection() }
    }
}
struct CapabilityView: View {
    @EnvironmentObject private var localization: LocalizationStore
    @EnvironmentObject private var app: AppEnvironment
    let id: String
    @State private var modification = false
    @State private var plan: SystemCapabilityPlan?
    @State private var deviceEditor: UUID?
    private var capability: Capability? { Capability.all.first { $0.id == id } }
    var body: some View {
        if let capability {
            SystemPage(identifier: "system.feature.page") {
                SystemPanel {
                    Label(localization.text(capability.title), systemImage: capability.systemSymbol).font(.title2.bold()).fixedSize(horizontal: false, vertical: true)
                    LabeledContent("Current configuration", value: localization.text(capability.currentLabel(in: app.deviceSnapshot?.value)))
                    Button("Modify", systemImage: "slider.horizontal.3") { modification = true }
                        .buttonStyle(.borderedProminent).controlSize(.large)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .disabled(app.deviceSnapshot?.writable != true || app.busy > 0 || app.systemRecoveryPending)
                        .accessibilityIdentifier("feature.modify")
                }
                DeviceAccessCard()
                if id == "dynamicIsland" {
                    NavigationLink(value: Screen.island) {
                        SystemTile(title: localization.text("Appearance & configuration"), detail: localization.text("Configuration inspection and appearance observations"), symbol: "capsule")
                    }.buttonStyle(.plain).accessibilityIdentifier("dynamicIsland.lab")
                }
                SystemPanel {
                    DisclosureGroup("Configuration fields") {
                        Text(localization.text(capability.detail)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                        ForEach(capability.keys, id: \.self) { key in Text(key).font(.system(.caption, design: .monospaced)).textSelection(.enabled) }
                        Button("Open device editor", systemImage: "doc.text") { app.openDeviceEditor { deviceEditor = $0 } }.disabled(app.deviceSnapshot == nil || app.busy > 0)
                    }
                    DisclosureGroup("Local documents") {
                        ForEach(app.state.documents) { document in
                            NavigationLink(document.name) { DocumentEditor(id: document.id, initialCapability: capability) }
                        }
                        if app.state.documents.isEmpty { Text("Import a MobileGestalt plist in Tools first.").foregroundStyle(.secondary) }
                    }
                }
            }
            .navigationTitle(localization.text(capability.title))
            .task { await app.ensureDeviceConnection() }
            .confirmationDialog(localization.text("Modify configuration"), isPresented: $modification, titleVisibility: .visible) {
                if id != "siriOnDevice" { Button("Apply preset") { prepare(restoring: false) } }
                Button("Restore captured value") { prepare(restoring: true) }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(item: $plan) { proposal in
                NavigationStack {
                    List {
                        ForEach(proposal.changes) { ChangeRow(change: $0) }
                        if proposal.changes.isEmpty { Text("No pending changes") }
                    }
                    .navigationTitle(localization.text("Review device changes"))
                    .safeAreaInset(edge: .bottom) {
                        Button("Confirm & apply", systemImage: "checkmark") {
                            app.performDevice { store in
                                app.deviceSnapshot = try await store.commitCapability(proposal)
                                app.deviceLinks.removeAll()
                            }
                            plan = nil
                        }.buttonStyle(.borderedProminent).controlSize(.large).padding()
                            .disabled(proposal.changes.isEmpty || app.busy > 0 || app.systemRecoveryPending)
                    }
                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { plan = nil } } }
                }
            }
            .navigationDestination(item: $deviceEditor) { document in DocumentEditor(id: document, systemMode: true) }
            .toolbar {
                Button { app.run { try await $0.toggleFavorite(id) } } label: {
                    Label("Favorite", systemImage: app.state.favorites.contains(id) ? "star.fill" : "star")
                }
            }
        } else { ContentUnavailableView("Feature not found", systemImage: "questionmark.circle") }
    }
    private func prepare(restoring: Bool) {
        guard let snapshot = app.deviceSnapshot else { return }
        app.performDevice(invalidateOnFailure: false) { store in plan = try await store.capabilityPlan(id, restoring: restoring, expected: snapshot) }
    }
}
