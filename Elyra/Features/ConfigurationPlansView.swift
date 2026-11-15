// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI
import UniformTypeIdentifiers

private struct PlanEditSession: Identifiable {
    let id = UUID()
    let plan: ConfigurationPlan
    let baseline: ConfigurationPlan?
}
struct ConfigurationPlansView: View {
    @EnvironmentObject private var app: AppEnvironment
    @EnvironmentObject private var localization: LocalizationStore
    @State private var editing: PlanEditSession?
    @State private var proposal: SystemConfigurationPlan?
    @State private var deleting: ConfigurationPlan?
    @State private var importing = false
    @State private var exporting = false
    @State private var export: ExportDocument?
    var body: some View {
        SystemPage(identifier: "configuration.plans") {
            DeviceAccessCard()
            if app.configurationPlans.isEmpty { ContentUnavailableView("No saved plans", systemImage: "slider.horizontal.3") }
            ForEach(app.configurationPlans) { plan in
                SystemPanel {
                    HStack {
                        Text(plan.name).font(.headline)
                        Spacer()
                        Menu {
                            Button("Edit") { editing = PlanEditSession(plan: plan, baseline: plan) }
                            Button("Export") { do { export = ExportDocument(data: try plan.encoded()); exporting = true } catch { app.error = error.localizedDescription } }
                            Button("Delete", role: .destructive) { deleting = plan }
                        } label: { Label("Plan actions", systemImage: "ellipsis.circle") }
                    }
                    DisclosureGroup("Configurations") {
                        ForEach(plan.steps, id: \.capabilityID) { step in
                            LabeledContent(localization.text(Capability.all.first { $0.id == step.capabilityID }?.title ?? step.capabilityID), value: localization.text(step.action == .apply ? "Apply preset" : "Restore captured value"))
                        }
                    }
                    Button("Modify", systemImage: "slider.horizontal.3") {
                        if let expected = app.deviceSnapshot { app.performDevice(invalidateOnFailure: false) { store in proposal = try await store.configurationPlan(plan, expected: expected) } }
                    }.buttonStyle(.borderedProminent).disabled(app.deviceSnapshot?.writable != true || app.busy > 0 || app.systemRecoveryPending)
                }
            }
        }.navigationTitle(localization.text("Configuration plans"))
        .task { await app.ensureDeviceConnection() }
        .toolbar {
            Button { importing = true } label: { Label("Import plan", systemImage: "square.and.arrow.down") }
            Button { editing = PlanEditSession(plan: ConfigurationPlan(name: "", steps: []), baseline: nil) } label: { Label("New plan", systemImage: "plus") }.accessibilityIdentifier("plans.new")
        }
        .sheet(item: $editing) { session in ConfigurationPlanEditor(plan: session.plan) { saved in app.run { try await $0.saveConfigurationPlan(saved, replacing: session.baseline) }; editing = nil } }
        .sheet(item: $proposal) { planned in
            NavigationStack {
                List {
                    ForEach(planned.changes) { ChangeRow(change: $0) }
                    if planned.changes.isEmpty { Text("No pending changes") }
                }.navigationTitle(localization.text("Review device changes"))
                    .safeAreaInset(edge: .bottom) {
                        Button("Confirm & apply") {
                            app.performDevice { store in app.deviceSnapshot = try await store.commitConfigurationPlan(planned); app.deviceLinks.removeAll() }
                            proposal = nil
                        }.buttonStyle(.borderedProminent).padding().disabled(planned.changes.isEmpty || app.busy > 0)
                    }
                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { proposal = nil } } }
            }
        }
        .confirmationDialog(localization.text("Delete plan?"), isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }), titleVisibility: .visible) {
            Button("Delete", role: .destructive) { if let deleting { app.run { try await $0.deleteConfigurationPlan(deleting.id) } }; deleting = nil }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                app.run { workspace in
                    let data = try await Task.detached {
                        let scoped = url.startAccessingSecurityScopedResource(); defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                        let file = try FileHandle(forReadingFrom: url); defer { try? file.close() }
                        return try file.read(upToCount: ConfigurationPlan.maximumBytes + 1) ?? Data()
                    }.value
                    try await workspace.saveConfigurationPlan(ConfigurationPlan.imported(data))
                }
            case .failure(let error): app.error = error.localizedDescription
            }
        }
        .fileExporter(isPresented: $exporting, document: export, contentType: .json, defaultFilename: "Elyra-plan.json") { result in
            if case .failure(let error) = result { app.error = error.localizedDescription }
        }
    }
}
private struct ConfigurationPlanEditor: View {
    @EnvironmentObject private var localization: LocalizationStore
    @Environment(\.dismiss) private var dismiss
    let plan: ConfigurationPlan
    let save: (ConfigurationPlan) -> Void
    @State private var name = ""
    @State private var actions: [String: ConfigurationStep.Action] = [:]
    @State private var error: String?
    var body: some View {
        NavigationStack {
            Form {
                TextField("Plan name", text: $name).accessibilityIdentifier("plan.name")
                ForEach(SystemCategory.all) { category in
                    Section(localization.text(category.title)) {
                        ForEach(Capability.all.filter { $0.category == category.id }) { feature in
                            Toggle(localization.text(feature.title), isOn: Binding(get: { actions[feature.id] != nil }, set: { actions[feature.id] = $0 ? (feature.id == "siriOnDevice" ? .restore : .apply) : nil })).accessibilityIdentifier("plan.feature." + feature.id)
                            if actions[feature.id] != nil {
                                Picker("Action", selection: Binding(get: { actions[feature.id] ?? .apply }, set: { actions[feature.id] = $0 })) {
                                    if feature.id != "siriOnDevice" { Text("Apply preset").tag(ConfigurationStep.Action.apply) }
                                    Text("Restore captured value").tag(ConfigurationStep.Action.restore)
                                }
                            }
                        }
                    }
                }
                if let error { Text(localization.text(error)).foregroundStyle(.red) }
            }.navigationTitle(localization.text("Configuration plan"))
                .onAppear { name = plan.name; actions = Dictionary(uniqueKeysWithValues: plan.steps.map { ($0.capabilityID, $0.action) }) }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Save") {
                        let saved = ConfigurationPlan(name: name, steps: actions.sorted { $0.key < $1.key }.map { .init(capabilityID: $0.key, action: $0.value) }, id: plan.id)
                        do { try saved.validate(); save(saved) } catch { self.error = error.localizedDescription }
                    }.accessibilityIdentifier("plan.save") }
                }
        }
    }
}
