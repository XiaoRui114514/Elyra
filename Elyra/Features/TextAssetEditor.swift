// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI

struct TextAssetEditor: View {
    @EnvironmentObject private var localization: LocalizationStore
    let id: UUID
    @EnvironmentObject private var app: AppEnvironment
    @State private var original: TextAssetSnapshot?
    @State private var text = ""
    @State private var confirming = false
    @State private var failed = false
    var body: some View {
        VStack(spacing: 0) {
            if let original {
                Text("Editing a managed UTF-8 copy. A verified file backup is saved before each change.")
                    .font(.caption).foregroundStyle(.secondary).padding().frame(maxWidth: .infinity, alignment: .leading)
                TextEditor(text: $text).font(.system(.body, design: .monospaced)).autocorrectionDisabled().textInputAutocapitalization(.never)
                    .accessibilityIdentifier("textAsset.editor")
                HStack {
                    Text("UTF-8 • " + localization.bytes(Int64(text.utf8.count))).font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    if text != original.text { Text("Unsaved text").font(.caption).foregroundStyle(.secondary) }
                }.padding()
            } else if failed {
                ContentUnavailableView("Unable to edit this file", systemImage: "doc.badge.ellipsis", description: Text("The text editor supports UTF-8 files up to 1 MB. Binary files are not editable here."))
            } else { ProgressView() }
        }
        .navigationTitle(original?.asset.name ?? localization.text("Text editor"))
        .toolbar {
            Button("Review & save") { confirming = true }
                .disabled(original == nil || text == original?.text || text.utf8.count > TextAssetSnapshot.maximumBytes || app.busy > 0)
        }
        .task(id: id) {
            guard let workspace = app.workspace else { return }
            do { let value = try await workspace.textSnapshot(id); original = value; text = value.text }
            catch { failed = true; app.error = error.localizedDescription }
        }
        .sheet(isPresented: $confirming) {
            NavigationStack {
                List {
                    StatusNotice(title: "Before saving", detail: "This updates only the managed file. The previous bytes are backed up, and a changed revision in another window rejects the save.")
                    Section("Before") { Text(original?.text ?? "").font(.system(.caption, design: .monospaced)).textSelection(.enabled) }
                    Section("After") { Text(text).font(.system(.caption, design: .monospaced)).textSelection(.enabled) }
                }
                .navigationTitle("Review text changes")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { confirming = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save local file") {
                            guard let expected = original else { return }
                            let output = text
                            app.run { workspace in original = try await workspace.saveText(output, expected: expected) }
                            confirming = false
                        }.accessibilityIdentifier("textAsset.save")
                    }
                }
            }
        }
    }
}
