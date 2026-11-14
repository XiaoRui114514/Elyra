// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI
import UniformTypeIdentifiers

struct BackupsView: View {
    @EnvironmentObject private var app: AppEnvironment
    @State private var offer: RestoreOffer?
    @State private var export: ExportDocument?
    @State private var exporting = false
    var body: some View {
        List {
            Section { StatusNotice(title: "Local document backups", detail: "Imported baselines and pre-save snapshots are byte-for-byte copies with SHA-256 integrity checks. They are not verified factory device originals. Restoring here updates only the matching managed local document.", symbol: "externaldrive.badge.checkmark") }
            Section { NavigationLink("Managed file backups") { AssetBackupsView() } }
            ForEach(app.state.backups) { record in
                Section {
                    Text(record.name).font(.headline)
                    Text(L(record.reason)).font(.subheadline)
                    Text(record.date, format: .dateTime).font(.caption)
                    Text(record.digest).font(.system(.caption2, design: .monospaced)).textSelection(.enabled)
                    HStack {
                        Button("Compare & restore") {
                            app.run { workspace in
                                let data = try await workspace.backupData(record.id)
                                let current = try await workspace.snapshot(record.documentID)
                                offer = RestoreOffer(backup: record, current: current, value: try PlistValue.decode(data))
                            }
                        }
                        Spacer()
                        Button("Export") {
                            app.run { workspace in export = ExportDocument(data: try await workspace.backupData(record.id)); exporting = true }
                        }
                    }.buttonStyle(.bordered)
                }
            }
            if app.state.backups.isEmpty { Text("No backups yet").foregroundStyle(.secondary) }
        }.navigationTitle("Backup center")
        .sheet(item: $offer) { offer in
            NavigationStack {
                List {
                    StatusNotice(title: "Restore local document", detail: "The current local file is backed up first. The selected backup must match this document and pass size and SHA-256 checks. The device system is not modified.")
                    ForEach(PlistChange.between(offer.current.value, offer.value)) { ChangeRow(change: $0) }
                }.navigationTitle("Restore preview")
                    .safeAreaInset(edge: .bottom) {
                        Button("Confirm local restore") {
                            app.run { workspace in _ = try await workspace.restore(offer.backup.id, expected: offer.current) }
                            self.offer = nil
                        }.buttonStyle(.borderedProminent).padding()
                    }
                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { self.offer = nil } } }
            }
        }
        .fileExporter(isPresented: $exporting, document: export, contentType: .propertyList, defaultFilename: "Elyra-backup.plist") { result in
            if case .failure(let error) = result { app.error = error.localizedDescription }
        }
    }
}
private struct RestoreOffer: Identifiable {
    let id = UUID()
    let backup: BackupRecord
    let current: DocumentSnapshot
    let value: PlistValue
}
