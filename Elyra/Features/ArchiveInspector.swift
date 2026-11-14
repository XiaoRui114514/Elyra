// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI
import UniformTypeIdentifiers
import ImageIO

struct ArchiveInspector: View {
    let id: UUID
    @EnvironmentObject private var app: AppEnvironment
    @State private var summary: ArchiveSummary?
    @State private var error: String?
    @State private var retry = UUID()
    @State private var preview: ArchivePreviewItem?
    @State private var search = ""
    var body: some View {
        List {
            Section {
                StatusNotice(title: "Offline archive inspection", detail: "Entries are checked for safe paths, links, encryption, CRC and expansion limits. This does not install a wallpaper or theme into the system.")
            }
            if let summary {
                Section {
                    LabeledContent("Entries", value: String(summary.items.count))
                    LabeledContent("Expanded size", value: ByteCountFormatter.string(fromByteCount: Int64(summary.expandedByteCount), countStyle: .file))
                    if summary.hasWallpaperDescriptors { Text("Wallpaper descriptor filenames were found. Provider installation is not verified.").font(.caption).foregroundStyle(.secondary) }
                }
                Section("Archive contents") {
                    ForEach(summary.items.filter { search.isEmpty || $0.path.localizedCaseInsensitiveContains(search) }) { item in
                        Button {
                            app.run { workspace in
                                let data = try await workspace.assetData(id)
                                let bytes = try await Task.detached(priority: .userInitiated) { try ArchiveInspection.readEntry(item.path, from: data) }.value
                                preview = ArchivePreviewItem(path: item.path, data: bytes)
                            }
                        } label: {
                            FeatureLabel(title: item.path, detail: ByteCountFormatter.string(fromByteCount: Int64(item.byteCount), countStyle: .file), symbol: item.directory ? "folder" : "doc")
                        }.disabled(item.directory || item.byteCount > 8 * 1024 * 1024)
                    }
                }
            } else if let error {
                Section {
                    Text(L(error)).foregroundStyle(.secondary)
                    Button("Try again") { self.error = nil; retry = UUID() }
                }
            } else { Section { ProgressView("Checking archive…") } }
        }
        .navigationTitle("Archive inspector").searchable(text: $search)
        .task(id: retry) {
            guard let workspace = app.workspace else { return }
            do {
                let bytes = try await workspace.assetData(id)
                let task = Task.detached(priority: .userInitiated) { try ArchiveInspection.inspect(bytes) }
                let result = try await withTaskCancellationHandler { try await task.value } onCancel: { task.cancel() }
                try Task.checkCancellation()
                summary = result
            } catch is CancellationError { }
            catch { self.error = error.localizedDescription }
        }
        .sheet(item: $preview) { ArchiveEntryPreview(item: $0) }
    }
}
private struct ArchivePreviewItem: Identifiable {
    let id = UUID()
    let path: String
    let data: Data
}
private struct ArchiveEntryPreview: View {
    let item: ArchivePreviewItem
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var app: AppEnvironment
    @State private var exporting = false
    private var thumbnail: UIImage? {
        guard let source = CGImageSourceCreateWithData(item.data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceThumbnailMaxPixelSize: 1800,
                                       kCGImageSourceCreateThumbnailWithTransform: true, kCGImageSourceShouldCacheImmediately: true]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return UIImage(cgImage: image)
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                if let thumbnail {
                    Image(uiImage: thumbnail).resizable().scaledToFit().padding().accessibilityLabel(item.path)
                } else if item.data.count <= TextAssetSnapshot.maximumBytes, !item.data.contains(0), let text = String(data: item.data, encoding: .utf8) {
                    Text(text).font(.system(.body, design: .monospaced)).textSelection(.enabled).padding().frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ContentUnavailableView("Binary entry", systemImage: "doc", description: Text("Export this entry to open it in a compatible app."))
                }
            }
            .navigationTitle((item.path as NSString).lastPathComponent)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .primaryAction) { Button("Export") { exporting = true } }
            }
            .fileExporter(isPresented: $exporting, document: ExportDocument(data: item.data), contentType: .data, defaultFilename: (item.path as NSString).lastPathComponent) { result in
                if case .failure(let error) = result { app.error = error.localizedDescription }
            }
        }
    }
}
