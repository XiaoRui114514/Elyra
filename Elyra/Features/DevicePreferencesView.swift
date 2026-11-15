// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI

struct DevicePreferencesView: View {
    enum Mode { case intelligence, modelName, regionCode }
    let mode: Mode
    @EnvironmentObject private var app: AppEnvironment
    @EnvironmentObject private var localization: LocalizationStore
    @SceneStorage("device.modelName.draft") private var name = ""
    @SceneStorage("device.modelName.edited") private var editedName = false
    @SceneStorage("device.regionCode.draft") private var region = "LL"
    @FocusState private var nameFocused: Bool
    @State private var proposal: DevicePreferencePlan?
    private var writable: Bool { app.deviceSnapshot?.writable == true && app.busy == 0 && !app.systemRecoveryPending }
    private var title: String {
        switch mode {
        case .intelligence: "Apple Intelligence"
        case .modelName: "Change Model Name"
        case .regionCode: "Region code"
        }
    }
    private var restoration: DevicePreferenceRecipe {
        switch mode {
        case .intelligence: .restoreIntelligence
        case .modelName: .restoreModelName
        case .regionCode: .restoreRegionCode
        }
    }
    var body: some View {
        SystemPage(identifier: "device.preferences") {
            SystemPanel {
                switch mode {
                case .intelligence:
                    Button("One-tap enable", systemImage: "apple.intelligence") { prepare(.intelligenceMainland) }
                        .buttonStyle(.borderedProminent).controlSize(.large).disabled(!writable).accessibilityIdentifier("intelligence.enable")
                    Text("Configures device flags. Apple service availability is checked by the system.").font(.caption).foregroundStyle(.secondary)
                case .modelName:
                    TextField("Model name", text: Binding(get: { name }, set: { name = $0; editedName = true }))
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .focused($nameFocused).submitLabel(.done).onSubmit { nameFocused = false }
                        .accessibilityIdentifier("device.modelName.input")
                    Button("Modify", systemImage: "checkmark") { prepare(.modelName(name)) }
                        .buttonStyle(.borderedProminent).disabled(!writable || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityIdentifier("device.modelName.apply")
                case .regionCode:
                    LabeledContent("Current configuration", value: DevicePreferences.currentRegionCode(in: app.deviceSnapshot?.value) ?? localization.text("Not read yet"))
                    Picker("Region code", selection: $region) {
                        ForEach(DevicePreferences.regionCodes, id: \.self) { code in Text(verbatim: code).tag(code) }
                    }.accessibilityIdentifier("device.regionCode.picker")
                    Button("Modify", systemImage: "checkmark") { prepare(.regionCode(region)) }
                        .buttonStyle(.borderedProminent).disabled(!writable).accessibilityIdentifier("device.regionCode.apply")
                }
                Button("Restore captured value", systemImage: "arrow.counterclockwise") { prepare(restoration) }.disabled(!writable)
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
        .navigationTitle(localization.text(title))
        .toolbar {
            if mode == .modelName {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit", systemImage: "pencil") { nameFocused = true }.accessibilityIdentifier("device.modelName.edit")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { nameFocused = false }.accessibilityIdentifier("device.modelName.done")
                }
            }
        }
        .task {
            if mode == .modelName { nameFocused = true }
            await app.ensureDeviceConnection()
            updateName()
        }
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
                            app.performDevice { store in
                                app.deviceSnapshot = try await store.commitPreference(plan)
                                app.deviceLinks.removeAll()
                                if mode == .modelName { editedName = false; updateName() }
                            }
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
        nameFocused = false
        guard let snapshot = app.deviceSnapshot else { return }
        app.performDevice(invalidateOnFailure: false) { store in proposal = try await store.preferencePlan(recipe, expected: snapshot) }
    }
}
