// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI
import UniformTypeIdentifiers

struct DiagnosticsView: View {
    @EnvironmentObject private var app: AppEnvironment
    @EnvironmentObject private var localization: LocalizationStore
    private let device = RuntimeDeviceContext.current
    private var report: CompatibilityReport { CompatibilityEngine.report(version: ProcessInfo.processInfo.operatingSystemVersion, deviceReadable: app.deviceSnapshot != nil, deviceWritable: app.deviceSnapshot?.writable == true, accessChecked: app.deviceAccessChecked) }
    var body: some View {
        List {
            Section("Device") {
                LabeledContent("Hardware identifier", value: device.hardware)
                LabeledContent("System build", value: device.build)
                Text(ProcessInfo.processInfo.operatingSystemVersionString).textSelection(.enabled)
                LabeledContent("Processors", value: String(ProcessInfo.processInfo.processorCount))
                LabeledContent("Physical memory", value: localization.bytes(Int64(ProcessInfo.processInfo.physicalMemory), memory: true))
            }
            Section("Compatibility") {
                compatibility("App UI", report.ui)
                compatibility("Local files", report.localFiles)
                compatibility("System read", report.systemRead)
                compatibility("System write", report.systemWrite)
                compatibility("System visual effects", report.visualEffect)
                Text(localization.text(report.reason)).font(.caption).foregroundStyle(.secondary)
            }
            Section("Privacy") { Text("Diagnostics use local public device and process information. No pairing credentials, serial numbers or device identifiers are uploaded.") }
        }.navigationTitle(localization.text("Device diagnostics"))
    }
    private func compatibility(_ name: String, _ status: SupportStatus) -> some View {
        VStack(alignment: .leading, spacing: 4) { Text(localization.text(name)); SupportBadge(status: status) }
    }

}
struct HistoryView: View {
    @EnvironmentObject private var localization: LocalizationStore
    @EnvironmentObject private var app: AppEnvironment
    @State private var search = ""
    @State private var export: ExportDocument?
    @State private var exporting = false
    var body: some View {
        List {
            Section { Text("History is an operation log, not a backup. It contains local filenames; review it before sharing.").font(.caption).foregroundStyle(.secondary) }
            ForEach(app.state.history.filter { search.isEmpty || ($0.operation + $0.detail).localizedCaseInsensitiveContains(search) }) { record in
                VStack(alignment: .leading, spacing: 5) {
                    Text(localization.text(record.operation)).font(.headline)
                    Text(record.detail).font(.subheadline)
                    Text(record.date, format: .dateTime).font(.caption).foregroundStyle(.secondary)
                }.textSelection(.enabled)
            }
            if app.state.history.isEmpty { Text("No operations yet") }
        }.navigationTitle(localization.text("Operation history")).searchable(text: $search)
        .toolbar {
            Button("Export history", systemImage: "square.and.arrow.up") {
                app.run { workspace in export = ExportDocument(data: try await workspace.exportOperationHistory()); exporting = true }
            }
        }
        .fileExporter(isPresented: $exporting, document: export, contentType: .json, defaultFilename: "Elyra-history.json") { result in
            if case .failure(let error) = result { app.error = error.localizedDescription }
        }
    }
}
struct OpenSourceLicensesView: View {
    @EnvironmentObject private var localization: LocalizationStore
    private var licenses: [URL] { Bundle.main.urls(forResourcesWithExtension: "txt", subdirectory: "Licenses")?.sorted { $0.lastPathComponent < $1.lastPathComponent } ?? [] }
    var body: some View {
        List {
            Section {
                Text("Elyra").font(.largeTitle.bold())
                Text("A universal iOS / iPadOS configuration workspace.")
                Text("GPL-3.0-only • No warranty").foregroundStyle(.secondary)
                Text("Capability catalog adapted from GestaltX. Copyright © 2026 huamidev. Source research: Erosion, lunginspector / jailbreak.party and contributors. Elyra adaptations © 2026 Elyra contributors.")
            }
            Section("Licenses & attribution") {
                ForEach(licenses, id: \.self) { url in
                    NavigationLink(url.deletingPathExtension().lastPathComponent) {
                        ScrollView {
                            Text((try? String(contentsOf: url, encoding: .utf8)) ?? localization.text("License could not be read."))
                                .font(.footnote).textSelection(.enabled).padding().frame(maxWidth: .infinity, alignment: .leading)
                        }.navigationTitle(url.deletingPathExtension().lastPathComponent)
                    }
                }
            }
        }.navigationTitle(localization.text("Open-source licenses"))
    }
}
