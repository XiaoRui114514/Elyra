// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI
import UniformTypeIdentifiers

struct AreaView: View {
    let area: Area
    @EnvironmentObject private var app: AppEnvironment
    @SceneStorage("globalSearch") private var search = ""
    @State private var importing = false
    var body: some View {
        List {
            if !search.isEmpty { searchResults }
            else {
                switch area {
                case .home: home
                case .system: system
                case .appearance: appearance
                case .tools: tools
                case .settings: settings
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $search, prompt: "Search features and imported fields")
        .fileImporter(isPresented: $importing, allowedContentTypes: [.propertyList, .xml, .data]) { result in
            switch result { case .success(let url): app.importURL(url); case .failure(let error): app.error = error.localizedDescription }
        }
    }
    private var home: some View {
        Group {
            Section {
                FeatureLabel(title: "Elyra", detail: "Your device. A considered workspace.", symbol: "circle.hexagongrid")
                Text(UIDevice.current.model + " • " + ProcessInfo.processInfo.operatingSystemVersionString).font(.subheadline).textSelection(.enabled)
                StatusNotice(title: app.workspace == nil ? "Workspace unavailable" : "Local workspace is ready",
                             detail: app.workspace == nil ? "Workspace could not be opened. Export existing files before attempting recovery." : "System modification is unavailable in this build. All imported files and presets are edited as local copies.", symbol: "lock.shield")
            }
            Section("Quick access") {
                NavigationLink(value: Screen.island) { FeatureLabel(title: "Dynamic Island Lab", detail: "Media states, capability flags and research", symbol: "capsule") }.accessibilityIdentifier("home.island")
                Button { importing = true } label: { Label("Import plist", systemImage: "square.and.arrow.down") }
                NavigationLink(value: Screen.backups) { Label("Backup center", systemImage: "externaldrive.badge.timemachine") }
            }
            if !app.state.favorites.isEmpty {
                Section("Favorites") {
                    ForEach(Capability.all.filter { app.state.favorites.contains($0.id) }) { capability in
                        NavigationLink(L(capability.title), value: Screen.capability(capability.id))
                    }
                }
            }
            Section("Recent operations") {
                if app.state.history.isEmpty { Text("No operations yet").foregroundStyle(.secondary) }
                ForEach(app.state.history.prefix(4)) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L(item.operation)); Text(item.detail).font(.caption).foregroundStyle(.secondary)
                        Text(item.date, style: .relative).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    private var system: some View {
        Group {
            Section { NavigationLink(value: Screen.island) { Label("Dynamic Island Lab", systemImage: "capsule") } }
            Section("Capability center") {
                ForEach(["display", "device", "ipad", "intelligence", "advanced"], id: \.self) { category in
                    NavigationLink(value: Screen.category(category)) {
                        FeatureLabel(title: category.capitalized, detail: "Shared on iPhone and iPad • local preset editing", symbol: category == "ipad" ? "ipad" : "slider.horizontal.3")
                    }
                }
            }
            documents
        }
    }
    private var documents: some View {
        Section("Configuration documents") {
            Button { importing = true } label: { Label("Import plist", systemImage: "square.and.arrow.down") }
            ForEach(app.state.documents) { document in
                NavigationLink(value: Screen.document(document.id)) {
                    FeatureLabel(title: document.name, detail: "Managed local copy", symbol: "doc.text")
                }
            }
            if app.state.documents.isEmpty { Text("Import a plist to browse, edit and compare actual values.").foregroundStyle(.secondary) }
        }
    }
    private var appearance: some View {
        Group {
            Section {
                StatusNotice(title: "Asset library", detail: "Import, preview and export your assets. Applying assets to other apps or system containers is unavailable; importing does not change system appearance.")
                NavigationLink(value: Screen.files) { Label("Open asset library", systemImage: "photo.on.rectangle.angled") }
            }
            ForEach(["Wallpapers & .tendies", "Dialer themes", "Notification sounds", "App launch images", "Lock Screen text"], id: \.self) { title in
                Section(L(title)) { StatusNotice(title: "Additional conditions required", detail: "System application requires an authorized, verified backend. Original system files are not accessible in this build.", symbol: "lock") }
            }
        }
    }
    private var tools: some View {
        Group {
            Section {
                NavigationLink(value: Screen.files) { Label("Files & assets", systemImage: "folder") }
                NavigationLink(value: Screen.diagnostics) { Label("Device diagnostics", systemImage: "stethoscope") }
                NavigationLink(value: Screen.history) { Label("Operation history", systemImage: "clock.arrow.circlepath") }
            }
            documents
            Section("Advanced tools") {
                StatusNotice(title: "Pairing & device connection", detail: "Not migrated. Upstream uses a Rust idevice console, tunnel, pairing record and signed entitlements. This build does not start a pairing service.")
                StatusNotice(title: "Respring", detail: "No supported public respring API is available. Upstream WebKit resource-exhaustion techniques are not included.")
            }
        }
    }
    private var settings: some View {
        Group {
            Section {
                NavigationLink(value: Screen.backups) { Label("Backup center", systemImage: "externaldrive") }
                NavigationLink(value: Screen.history) { Label("Operation history", systemImage: "clock") }
                NavigationLink(value: Screen.licenses) { Label("About & open-source licenses", systemImage: "info.circle") }
            }
            Section("Language & accessibility") {
                Text("Elyra follows the system language, appearance, text size and Reduce Motion preferences.")
                Button("Open app settings") { if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) } }
            }
            Section { Text("Elyra 0.2.0 • Development build").foregroundStyle(.secondary) }
        }
    }
    private var searchResults: some View {
        Group {
            Section("Features") {
                ForEach(Capability.all.filter { (L($0.title) + $0.title + L($0.category) + $0.keys.joined()).localizedCaseInsensitiveContains(search) }) { capability in
                    NavigationLink(L(capability.title), value: Screen.capability(capability.id))
                }
                if "Dynamic Island Lab 灵动岛".localizedCaseInsensitiveContains(search) { NavigationLink("Dynamic Island Lab", value: Screen.island) }
                if "Files 文件 素材".localizedCaseInsensitiveContains(search) { NavigationLink("Files & assets", value: Screen.files) }
                if "Backups 备份 恢复".localizedCaseInsensitiveContains(search) { NavigationLink("Backup center", value: Screen.backups) }
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
