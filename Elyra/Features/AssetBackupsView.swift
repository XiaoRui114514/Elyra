// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI
import UniformTypeIdentifiers

struct AssetBackupsView: View {
    @EnvironmentObject private var localization: LocalizationStore
    @EnvironmentObject private var app: AppEnvironment
    @State private var restoring: AssetBackupRecord?
    @State private var expected: AssetRecord?
    @State private var confirmation = false
    @State private var export: ExportDocument?
    @State private var exporting = false
    @State private var exportName = "Elyra-file-backup"
    var body: some View {
        List {
            Section { StatusNotice(title: "Managed file backups", detail: "Restores update the matching file in Elyra’s library. Current bytes are backed up first; SHA-256 and revision checks must pass.") }
            ForEach(app.state.assetBackups) { backup in
                Section {
                    Text(backup.name).font(.headline)
                    Text(backup.date, format: .dateTime).font(.caption)
                    Text(backup.digest).font(.system(.caption2, design: .monospaced)).textSelection(.enabled)
                    HStack {
                        Button("Restore local file") {
                            guard let current = app.state.assets.first(where: { $0.id == backup.assetID }) else {
                                app.error = "Restore this file from Trash before restoring its backup."; return
                            }
                            restoring = backup; expected = current; confirmation = true
                        }
                        Spacer()
                        Button("Export") { app.run { workspace in export = ExportDocument(data: try await workspace.assetBackupData(backup.id)); exportName = URL(fileURLWithPath: backup.name).lastPathComponent; exporting = true } }
                    }.buttonStyle(.bordered)
                }
            }
            if app.state.assetBackups.isEmpty { Text("No file backups yet") }
        }.navigationTitle(localization.text("Managed file backups"))
        .confirmationDialog(localization.text("Restore local file?"), isPresented: $confirmation, titleVisibility: .visible) {
            Button("Restore local file") {
                if let restoring, let expected { app.run { _ = try await $0.restoreAssetBackup(restoring.id, expected: expected) } }
            }
        } message: { Text("The current file is backed up first. This restores the selected bytes, not a device system file.") }
        .fileExporter(isPresented: $exporting, document: export, contentType: .data, defaultFilename: exportName) { result in
            if case .failure(let error) = result { app.error = error.localizedDescription }
        }
    }
}
