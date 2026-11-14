// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI
import Darwin

struct DiagnosticsView: View {
    private var report: CompatibilityReport { CompatibilityEngine.report(version: ProcessInfo.processInfo.operatingSystemVersion) }
    var body: some View {
        List {
            Section("Device") {
                LabeledContent("Hardware identifier", value: sysctl("hw.machine"))
                LabeledContent("System build", value: sysctl("kern.osversion"))
                Text(ProcessInfo.processInfo.operatingSystemVersionString).textSelection(.enabled)
                LabeledContent("Processors", value: String(ProcessInfo.processInfo.processorCount))
                LabeledContent("Physical memory", value: ByteCountFormatter.string(fromByteCount: Int64(ProcessInfo.processInfo.physicalMemory), countStyle: .memory))
            }
            Section("Compatibility") {
                compatibility("App UI", report.ui)
                compatibility("Local files", report.localFiles)
                compatibility("System read", report.systemRead)
                compatibility("System write", report.systemWrite)
                compatibility("System visual effects", report.visualEffect)
                Text(L(report.reason)).font(.caption).foregroundStyle(.secondary)
            }
            Section("Privacy") { Text("Diagnostics use local public device and process information. No pairing credentials, serial numbers or device identifiers are uploaded.") }
        }.navigationTitle("Device diagnostics")
    }
    private func compatibility(_ name: String, _ status: SupportStatus) -> some View {
        VStack(alignment: .leading, spacing: 4) { Text(L(name)); SupportBadge(status: status) }
    }
    private func sysctl(_ key: String) -> String {
        var size = 0
        guard sysctlbyname(key, nil, &size, nil, 0) == 0, size > 0 else { return L("Unavailable") }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname(key, &buffer, &size, nil, 0) == 0 else { return L("Unavailable") }
        return String(cString: buffer)
    }
}
struct HistoryView: View {
    @EnvironmentObject private var app: AppEnvironment
    @State private var search = ""
    var body: some View {
        List {
            Section { Text("History is an operation log, not a backup. It contains local filenames; review it before sharing.").font(.caption).foregroundStyle(.secondary) }
            ForEach(app.state.history.filter { search.isEmpty || ($0.operation + $0.detail).localizedCaseInsensitiveContains(search) }) { record in
                VStack(alignment: .leading, spacing: 5) {
                    Text(L(record.operation)).font(.headline)
                    Text(record.detail).font(.subheadline)
                    Text(record.date, format: .dateTime).font(.caption).foregroundStyle(.secondary)
                }.textSelection(.enabled)
            }
            if app.state.history.isEmpty { Text("No operations yet") }
        }.navigationTitle("Operation history").searchable(text: $search)
    }
}
struct LicensesView: View {
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
                            Text((try? String(contentsOf: url, encoding: .utf8)) ?? L("License could not be read."))
                                .font(.footnote).textSelection(.enabled).padding().frame(maxWidth: .infinity, alignment: .leading)
                        }.navigationTitle(url.deletingPathExtension().lastPathComponent)
                    }
                }
            }
        }.navigationTitle("About Elyra")
    }
}
