// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI

struct DevicePreferencesView: View {
    enum Mode { case intelligence, modelName }
    let mode: Mode
    @EnvironmentObject private var app: AppEnvironment
    @EnvironmentObject private var localization: LocalizationStore
    @State private var name = ""
    @State private var editedName = false
    @State private var proposal: DevicePreferencePlan?
    private var writable: Bool { app.deviceSnapshot?.writable == true && app.busy == 0 && !app.systemRecoveryPending }
    var body: some View {
        SystemPage(identifier: "device.preferences") {
            SystemPanel {
                if mode == .intelligence {
                    Button("One-tap enable", systemImage: "apple.intelligence") { prepare(.intelligenceMainland) }
                        .buttonStyle(.borderedProminent).controlSize(.large).disabled(!writable).accessibilityIdentifier("intelligence.enable")
                    Text("Configures device flags. Apple service availability is checked by the system.").font(.caption).foregroundStyle(.secondary)
                } else {
                    TextField("Model name", text: Binding(get: { name }, set: { name = $0; editedName = true }))
                        .textFieldStyle(.roundedBorder).accessibilityIdentifier("device.modelName.input")
                    Button("Modify", systemImage: "checkmark") { prepare(.modelName(name)) }
                        .buttonStyle(.borderedProminent).disabled(!writable || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityIdentifier("device.modelName.apply")
                }
                Button("Restore captured value", systemImage: "arrow.counterclockwise") { prepare(mode == .intelligence ? .restoreIntelligence : .restoreModelName) }.disabled(!writable)
            }
            DeviceAccessCard()
            if mode == .intelligence {
                SystemPanel {
                    ForEach(DevicePreferences.intelligence) { feature in
                        LabeledContent(localization.text(feature.title), value: localization.text(feature.state(in: app.deviceSnapshot?.value).rawValue))
                    }
                    LabeledContent("On-Device Siri", value: localization.text("Preserve device-specific value"))
                    DisclosureGroup("Region configuration") {
                        LabeledContent("Region code", value: "LL")
                        Text("Sales region, device identity and Siri data type are preserved.").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(localization.text(mode == .intelligence ? "Apple Intelligence for China Mainland" : "Change Model Name"))
        .task { await app.ensureDeviceConnection(); updateName() }
        .onChange(of: app.deviceSnapshot?.id) { _, _ in updateName() }
        .sheet(item: $proposal) { plan in
            NavigationStack {
                List {
                    ForEach(plan.changes) { ChangeRow(change: $0) }
                    if plan.changes.isEmpty { Text("No pending changes") }
                    if mode == .intelligence { LabeledContent("On-Device Siri", value: localization.text("Preserve device-specific value")) }
                }.navigationTitle(localization.text("Review device changes"))
                    .safeAreaInset(edge: .bottom) {
                        Button("Confirm & apply", systemImage: "checkmark") {
                            app.performDevice { store in app.deviceSnapshot = try await store.commitPreference(plan); app.deviceLinks.removeAll() }
                            proposal = nil
                        }.buttonStyle(.borderedProminent).controlSize(.large).padding().disabled(!writable || plan.changes.isEmpty)
                    }
                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { proposal = nil } } }
            }
        }
    }
    private func updateName() {
        guard !editedName else { return }
        name = app.deviceSnapshot.flatMap { DevicePreferences.modelName(in: $0.value) } ?? ""
    }
    private func prepare(_ recipe: DevicePreferenceRecipe) {
        guard let snapshot = app.deviceSnapshot else { return }
        app.performDevice(invalidateOnFailure: false) { store in proposal = try await store.preferencePlan(recipe, expected: snapshot) }
    }
}
