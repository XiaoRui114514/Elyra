// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI
import UniformTypeIdentifiers
import QuickLook

struct FilesView: View {
    @EnvironmentObject private var app: AppEnvironment
    @State private var importing = false
    @State private var category = "Files"
    @SceneStorage("fileSearch") private var search = ""
    @State private var previewURL: URL?
    @State private var deleting: AssetRecord?
    @State private var showDelete = false
    var body: some View {
        List {
            Section {
                StatusNotice(title: "Files & assets", detail: "Browse imported files in Elyra’s sandbox. Drag files here or use Import. System directories and other app containers are not accessible.", symbol: "folder")
                Picker("Import category", selection: $category) {
                    ForEach(["Files", "Wallpapers", "Dialer themes", "Notification sounds", "App launch images"], id: \.self) { Text(L($0)).tag($0) }
                }
                Button("Import file", systemImage: "square.and.arrow.down") { importing = true }.keyboardShortcut("i", modifiers: [.command])
            }
            Section("Library") {
                ForEach(app.state.assets.filter { search.isEmpty || ($0.name + L($0.category)).localizedCaseInsensitiveContains(search) }) { asset in
                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            app.run { workspace in previewURL = try await workspace.assetURL(asset.id) }
                        } label: { FeatureLabel(title: asset.name, detail: L(asset.category) + " • " + ByteCountFormatter.string(fromByteCount: Int64(asset.byteCount), countStyle: .file), symbol: "doc") }
                        Text(asset.date, style: .date).font(.caption).foregroundStyle(.secondary)
                        Text("SHA-256: " + asset.digest).font(.system(.caption2, design: .monospaced)).textSelection(.enabled)
                        HStack {
                            Button("Export") { app.run { workspace in previewURL = try await workspace.assetURL(asset.id) } }
                            Spacer()
                            Button("Move to Trash", role: .destructive) { deleting = asset; showDelete = true }
                        }.buttonStyle(.bordered)
                    }
                    .contextMenu { Button("Preview & share") { app.run { workspace in previewURL = try await workspace.assetURL(asset.id) } } }
                }
                if app.state.assets.isEmpty { Text("No imported assets").foregroundStyle(.secondary) }
            }
            if !app.state.trash.isEmpty {
                Section("Trash") {
                    ForEach(app.state.trash) { asset in
                        HStack {
                            Text(asset.name)
                            Spacer()
                            Button("Restore") { app.run { try await $0.restoreAsset(asset.id) } }
                        }
                    }
                }
            }
        }
        .navigationTitle("Files & assets").searchable(text: $search)
        .quickLookPreview($previewURL)
        .fileImporter(isPresented: $importing, allowedContentTypes: [.item]) { result in
            switch result { case .success(let url): app.importURL(url, category: category); case .failure(let error): app.error = error.localizedDescription }
        }
        .dropDestination(for: URL.self) { urls, _ in
            for url in urls { app.importURL(url, category: category) }
            return !urls.isEmpty
        }
        .confirmationDialog("Move asset to Trash?", isPresented: $showDelete, titleVisibility: .visible) {
            Button("Move to Trash", role: .destructive) { if let deleting { app.run { try await $0.deleteAsset(deleting.id) } } }
        }
    }
}
