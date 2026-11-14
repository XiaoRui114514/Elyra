// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI
import UniformTypeIdentifiers

struct IslandConfigurationView: View {
    @EnvironmentObject private var localization: LocalizationStore
    let id: UUID
    @EnvironmentObject private var app: AppEnvironment
    @State private var snapshot: DocumentSnapshot?
    @State private var inspection: IslandInspection?
    @State private var plan: IslandPlan?
    @State private var export: ExportDocument?
    @State private var exporting = false
    var body: some View {
        List {
            if let snapshot, let inspection {
                Section {
                    Text(snapshot.record.name).font(.headline)
                    StatusNotice(title: "Managed local copy", detail: "This inspection reads your imported file. It does not prove the device currently uses these values.")
                    LabeledContent("Dynamic Island", value: localization.text(inspection.flag.rawValue))
                    LabeledContent("ArtworkDeviceSubType", value: inspection.rawSubtype?.summary ?? localization.text("Absent"))
                    Text("SHA-256: " + snapshot.revision).font(.system(.caption2, design: .monospaced)).textSelection(.enabled)
                }
                Section("Diagnosis") {
                    if !inspection.artworkIsValid || inspection.flag == .invalid {
                        StatusNotice(title: "Unexpected field type", detail: "Review the typed fields. Elyra will not guess how to repair a malformed artwork dictionary.", symbol: "exclamationmark.triangle")
                    }
                    if inspection.isIPad && inspection.usesPhoneArtwork {
                        StatusNotice(title: "iPhone artwork identity on iPad", detail: "A phone subtype was found in the imported configuration. It can affect safe areas, display scaling and keyboard layout. This is a risk indicator, not proof of the appearance issue's cause.", symbol: "exclamationmark.triangle")
                    }
                    StatusNotice(title: "System geometry is not configurable here", detail: "No verified field controls system Dynamic Island roundness, proportions or orientation. Enabling a capability flag does not establish correct iPad appearance in any activity.")
                }
                Section("Local configuration actions") {
                    ForEach(IslandAction.allCases) { action in
                        Button(localization.text(action.rawValue)) { app.run { workspace in plan = try await workspace.islandPlan(documentID: id, action: action) } }
                    }
                    Text("Recorded baseline means the bytes originally imported into this document. It may already contain tweaks and is not a verified factory original. Restore changes only the DI flag and artwork subtype, preserving other edits.").font(.caption).foregroundStyle(.secondary)
                    NavigationLink("Open full editor", value: Screen.document(id))
                }
            } else { ProgressView() }
        }
        .navigationTitle("Configuration inspection")
        .task(id: app.state.history.first?.id) { await reload() }
        .sheet(item: $plan) { proposal in
            NavigationStack {
                List {
                    StatusNotice(title: "Review local changes", detail: "These changes apply to the managed local document only. No system write or device repair will be performed.")
                    if let baseline = proposal.baseline {
                        Text(localization.text("Imported baseline") + " • " + baseline.date.formatted(.dateTime.locale(localization.locale))).font(.caption)
                    }
                    ForEach(proposal.changes) { ChangeRow(change: $0) }
                    if proposal.changes.isEmpty { Text("No pending changes") }
                }
                .navigationTitle(localization.text(proposal.action.rawValue))
                .safeAreaInset(edge: .bottom) {
                    VStack(spacing: 8) {
                        Button("Confirm & save local copy") {
                            app.run { workspace in
                                _ = try await workspace.commit(proposal.target, expected: proposal.snapshot, reason: "Save DI fields (local)")
                                await reload()
                            }
                            plan = nil
                        }.buttonStyle(.borderedProminent).disabled(proposal.changes.isEmpty)
                        Button("Export proposed local plist") {
                            do { export = ExportDocument(data: try proposal.target.encoded()); exporting = true }
                            catch { app.error = error.localizedDescription }
                        }
                    }.padding()
                }
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { plan = nil } } }
                .fileExporter(isPresented: $exporting, document: export, contentType: .propertyList, defaultFilename: "Elyra-DI-local.plist") { result in
                    if case .failure(let error) = result { app.error = error.localizedDescription }
                }
            }
        }
    }
    private func reload() async {
        guard let workspace = app.workspace else { return }
        do {
            let current = try await workspace.snapshot(id)
            snapshot = current
            inspection = try DynamicIslandEngine.inspect(current.value, physicalHardware: RuntimeDeviceContext.current.hardware)
        } catch { app.error = error.localizedDescription }
    }
}
