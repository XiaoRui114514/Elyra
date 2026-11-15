// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI
import UniformTypeIdentifiers

struct AreaView: View {
    @EnvironmentObject private var localization: LocalizationStore
    let area: Area
    @EnvironmentObject private var app: AppEnvironment
    @SceneStorage("globalSearch") private var search = ""
    @State private var importing = false
    @State private var respringConfirmation = false
    @State private var showRespring = false
    var body: some View {
        Group {
            if area == .system && search.isEmpty { SystemOverview() }
            else { List {
            if !search.isEmpty { searchResults }
            else {
                switch area {
                case .home: home
                case .system: EmptyView()
                case .appearance: appearance
                case .tools: tools
                case .settings: settings
                }
            }
            }.listStyle(.insetGrouped) }
        }
        .searchable(text: $search, prompt: Text(localization.text("Search features and imported fields")))
        .confirmationDialog(localization.text("Restart the system interface?"), isPresented: $respringConfirmation, titleVisibility: .visible) {
            Button("Respring", role: .destructive) { if app.beginRespring() { showRespring = true } }
        } message: { Text("This experimental upstream method restarts the system interface through WebKit resource pressure. Save ongoing work first. It may fail or interrupt apps; it does not sign out of your Apple Account.") }
        .fullScreenCover(isPresented: $showRespring, onDismiss: { app.respringing = false }) { RespringScreen() }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.propertyList, .xml, .data]) { result in
            switch result { case .success(let url): app.importURL(url); case .failure(let error): app.error = error.localizedDescription }
        }
    }
    private var home: some View {
        Group {
            Section {
                FeatureLabel(title: "Elyra", detail: "Device configuration and file tools.", symbol: "circle.hexagongrid")
                Text(UIDevice.current.model + " • " + ProcessInfo.processInfo.operatingSystemVersionString).font(.subheadline).textSelection(.enabled)
                if app.workspace == nil {
                    StatusNotice(title: "Workspace unavailable", detail: "Workspace could not be opened. Export existing files before attempting recovery.", symbol: "exclamationmark.triangle")
                } else { Label("Workspace ready", systemImage: "checkmark.circle").font(.headline) }
            }
            Section("Device actions") {
                Button("Respring", systemImage: "arrow.clockwise") { respringConfirmation = true }.disabled(app.busy > 0 || app.systemRecoveryPending || app.respringing || RuntimeDeviceContext.current.simulator).accessibilityIdentifier("home.respring")
            }
            if !app.state.favorites.isEmpty {
                Section("Favorites") {
                    ForEach(Capability.all.filter { app.state.favorites.contains($0.id) }) { capability in
                        NavigationLink(localization.text(capability.title), value: Screen.capability(capability.id))
                    }
                }
            }
            Section("Recent operations") {
                if app.state.history.isEmpty { Text("No operations yet").foregroundStyle(.secondary) }
                ForEach(app.state.history.prefix(4)) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localization.text(item.operation)); Text(item.detail).font(.caption).foregroundStyle(.secondary)
                        Text(item.date, style: .relative).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    private var documents: some View {
        Section("Configuration documents") {
            Button { importing = true } label: { Label("Import plist", systemImage: "square.and.arrow.down") }
            ForEach(app.state.documents) { document in
                NavigationLink(value: Screen.document(document.id)) {
                    FeatureLabel(title: document.name, detail: "Managed local copy", symbol: "doc.text", localizesTitle: false)
                }
            }
            if app.state.documents.isEmpty { Text("Import a plist to browse, edit and compare actual values.").foregroundStyle(.secondary) }
        }
    }
    private var appearance: some View {
        Group {
            Section {
                NavigationLink(value: Screen.files) { Label("Open asset library", systemImage: "photo.on.rectangle.angled") }
            }
            ForEach(["Wallpapers & .tendies", "Dialer themes", "Notification sounds", "App launch images", "Lock Screen text"], id: \.self) { title in
                Section(localization.text(title)) { Text("Implementation pending").foregroundStyle(.secondary) }
            }
        }
    }
    private var tools: some View {
        Group {
            Section {
                NavigationLink(value: Screen.files) { Label("File Manager", systemImage: "folder") }
                NavigationLink(value: Screen.diagnostics) { Label("Device diagnostics", systemImage: "stethoscope") }
                NavigationLink(value: Screen.displayDiagnostics) { Label("Window & display", systemImage: "display") }.accessibilityIdentifier("tools.display")
                NavigationLink(value: Screen.history) { Label("Operation history", systemImage: "clock.arrow.circlepath") }
            }
            documents
            Section("Advanced tools") {
                LabeledContent("Pairing & device connection", value: localization.text("Implementation pending"))
            }
        }
    }
    private var settings: some View {
        Group {
            Section {
                NavigationLink(value: Screen.backups) { Label("Backups", systemImage: "externaldrive") }
                NavigationLink(value: Screen.history) { Label("Operation history", systemImage: "clock") }
                NavigationLink(value: Screen.licenses) { Label("About Elyra", systemImage: "info.circle") }
            }
            Section("Language & accessibility") {
                NavigationLink(value: Screen.language) { Label("Language", systemImage: "globe") }.accessibilityIdentifier("settings.language")
                Button("Open app settings") { if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) } }
            }
            Section { Text("Elyra 0.4.0 • Development build").foregroundStyle(.secondary) }
        }
    }
    private var searchResults: some View {
        Group {
            Section("Features") {
                ForEach(Capability.all.filter { (localization.text($0.title) + $0.title + localization.text($0.category) + $0.keys.joined()).localizedCaseInsensitiveContains(search) }) { capability in
                    NavigationLink(localization.text(capability.title), value: Screen.capability(capability.id))
                }
                if "Files 文件 素材".localizedCaseInsensitiveContains(search) { NavigationLink("File Manager", value: Screen.files) }
                if "Backups 备份 恢复".localizedCaseInsensitiveContains(search) { NavigationLink("Backups", value: Screen.backups) }
            }
            Section("Imported fields") {
                ForEach(app.fieldIndex.filter { ($0.key + $0.name).localizedCaseInsensitiveContains(search) }) { field in
                    NavigationLink(value: Screen.field(field.document, field.path)) {
                        VStack(alignment: .leading) { Text(field.key); Text(field.name).font(.caption).foregroundStyle(.secondary) }
                    }
                }
            }
        }
    }
}
