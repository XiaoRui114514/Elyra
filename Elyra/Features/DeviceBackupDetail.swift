// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI
import UniformTypeIdentifiers

struct DeviceBackupDetail: View {
    @EnvironmentObject private var app: AppEnvironment
    @EnvironmentObject private var localization: LocalizationStore
    let id: UUID
    @State private var inspection: SystemBackupInspection?
    @State private var export: ExportDocument?
    @State private var exporting = false
    @State private var restoring = false
    @State private var comparison = false
    @State private var localCopy: UUID?
    @State private var failure: String?
    var body: some View {
        List {
            if let inspection {
                Section {
                    Label("Integrity verified", systemImage: "checkmark.shield")
                    Text(inspection.record.date, format: .dateTime)
                    LabeledContent("Source", value: localization.text(inspection.record.reason))
                    LabeledContent("Size", value: localization.bytes(Int64(inspection.data.count)))
                }
                Section {
                    Button("Open local copy", systemImage: "doc.text") {
                        app.run { workspace in localCopy = try await workspace.importDocument(data: inspection.data, name: "Device-backup.plist").record.id }
                    }
                    Button("Export", systemImage: "square.and.arrow.up") { export = ExportDocument(data: inspection.data); exporting = true }
                    Button("Compare with device", systemImage: "arrow.left.arrow.right") { comparison = true }.disabled(app.deviceSnapshot == nil)
                    Button("Restore", systemImage: "arrow.counterclockwise") { restoring = true }.disabled(app.deviceSnapshot?.writable != true || app.busy > 0 || app.systemRecoveryPending)
                }
                Section {
                    DisclosureGroup("Configuration fields") {
                        Text(inspection.record.digest).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                    }
                }
            } else if let failure {
                ContentUnavailableView("Backup unavailable", systemImage: "exclamationmark.triangle", description: Text(localization.text(failure)))
            } else { ProgressView() }
        }.navigationTitle(localization.text("Device backup"))
        .navigationDestination(item: $localCopy) { DocumentEditor(id: $0) }
        .task { do { inspection = try await app.inspectDeviceBackup(id) } catch { failure = error.localizedDescription } }
        .sheet(isPresented: $comparison) {
            NavigationStack {
                List {
                    if let inspection, let snapshot = app.deviceSnapshot {
                        let changes = PlistChange.between(inspection.value, snapshot.value)
                        ForEach(changes) { ChangeRow(change: $0) }
                        if changes.isEmpty { Text("No pending changes") }
                    }
                }.navigationTitle(localization.text("Backup comparison"))
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { comparison = false } } }
            }
        }
        .confirmationDialog(localization.text("Restore device backup?"), isPresented: $restoring, titleVisibility: .visible) {
            Button("Confirm system restore", role: .destructive) {
                if let expected = app.deviceSnapshot { app.performDevice { store in app.deviceSnapshot = try await store.restore(id, expected: expected); app.deviceLinks.removeAll() } }
            }
        }
        .fileExporter(isPresented: $exporting, document: export, contentType: .propertyList, defaultFilename: "Elyra-device-backup.plist") { result in
            if case .failure(let error) = result { app.error = error.localizedDescription }
        }
    }
}
