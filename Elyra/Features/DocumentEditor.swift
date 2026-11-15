// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI
import UniformTypeIdentifiers

struct DocumentEditor: View {
    @EnvironmentObject private var localization: LocalizationStore
    let id: UUID
    var systemMode = false
    var initialCapability: Capability? = nil
    var initialFieldPath: [String]? = nil
    @EnvironmentObject private var app: AppEnvironment
    @Environment(\.elyraWide) private var wide
    @SceneStorage("editorWindowID") private var windowID = UUID().uuidString
    @State private var snapshot: DocumentSnapshot?
    @State private var edited: PlistValue = .dictionary([:])
    @State private var search = ""
    @State private var field: FieldSelection?
    @State private var reviewing = false
    @State private var discardConfirmation = false
    @State private var export: ExportDocument?
    @State private var exporting = false
    @State private var draftConflict = false
    private var changes: [PlistChange] { snapshot.map { PlistChange.between($0.value, edited) } ?? [] }
    var body: some View {
        Group {
            if let snapshot {
                Group {
                    if wide {
                        HStack(spacing: 0) { fields; Divider(); diffList.frame(maxWidth: .infinity) }
                    } else { fields }
                }
                .navigationTitle(snapshot.record.name)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button { reviewing = true } label: { Label("Review changes", systemImage: "checkmark.circle") }.disabled(changes.isEmpty || draftConflict)
                        Menu {
                            Button("Add field", systemImage: "plus") { field = FieldSelection(path: edited.value(at: ["CacheExtra"]) == nil ? [] : ["CacheExtra"], value: nil, adding: true) }
                            Menu(localization.text(systemMode ? "Stage preset" : "Stage local preset")) {
                                ForEach(Capability.all) { capability in
                                    Button(localization.text(capability.title)) {
                                        do { try capability.stage(in: &edited) } catch { app.error = error.localizedDescription }
                                    }
                                }
                            }
                            Button("Export current draft", systemImage: "square.and.arrow.up") {
                                do { export = ExportDocument(data: try edited.encoded()); exporting = true } catch { app.error = error.localizedDescription }
                            }
                            Button("Create backup", systemImage: "externaldrive") {
                                if systemMode, let source = app.deviceLinks[id] { app.performDevice { try await $0.manualBackup(expected: source) } }
                                else { app.run { _ = try await $0.backup(id) } }
                            }
                            Button("Discard draft & reload", role: .destructive) { discardConfirmation = true }
                        } label: { Label("Document actions", systemImage: "ellipsis.circle") }
                    }
                }
            } else { ContentUnavailableView("Open a configuration document", systemImage: "doc.text", description: Text("Import a plist to browse, edit and compare actual values.")) }
        }
        .task(id: id) { await load() }
        .onChange(of: edited) { _, value in
            guard let snapshot, let workspace = app.workspace, let window = UUID(uuidString: windowID) else { return }
            let draft = LocalDraft(revision: snapshot.revision, value: value)
            Task { do { try await workspace.saveDraft(draft, window: window, document: id) } catch { app.error = error.localizedDescription } }
        }
        .sheet(item: $field) { selection in
            FieldEditor(selection: selection) { value, key in
                if selection.adding {
                    let path = selection.path + [key]
                    guard edited.value(at: path) == nil else { throw ElyraError.invalid("A field with this name already exists.") }
                    try edited.set(value, at: path)
                } else if !selection.path.isEmpty, key != selection.path.last {
                    guard case .dictionary = edited.value(at: Array(selection.path.dropLast())) else {
                        throw ElyraError.invalid("Array indexes cannot be renamed.")
                    }
                    let target = Array(selection.path.dropLast()) + [key]
                    guard !key.isEmpty, edited.value(at: target) == nil else { throw ElyraError.invalid("A field with this name already exists.") }
                    // Update a copy so failed validation cannot partially rename the field.
                    var renamed = edited
                    try renamed.set(value, at: target); try renamed.set(nil, at: selection.path)
                    edited = renamed
                } else { try edited.set(value, at: selection.path) }
            }
        }
        .sheet(isPresented: $reviewing) {
            NavigationStack {
                diffList.navigationTitle(localization.text(systemMode ? "Review device changes" : "Review local changes"))
                    .safeAreaInset(edge: .bottom) {
                        Button(localization.text(systemMode ? "Confirm & write to device" : "Confirm & save local copy")) { save(); reviewing = false }
                            .buttonStyle(.borderedProminent).padding()
                            .disabled(changes.isEmpty || draftConflict || app.busy > 0 || (systemMode && (app.systemRecoveryPending || app.deviceSnapshot?.writable != true || app.deviceLinks[id] == nil)))
                    }
                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { reviewing = false } } }
            }
        }
        .confirmationDialog(localization.text("Discard draft & reload?"), isPresented: $discardConfirmation, titleVisibility: .visible) {
            Button("Discard draft & reload", role: .destructive) {
                app.run { workspace in
                    if let window = UUID(uuidString: windowID) { try await workspace.discardDraft(window: window, document: id) }
                    await load(restoreDraft: false)
                }
            }
        }
        .fileExporter(isPresented: $exporting, document: export, contentType: .propertyList, defaultFilename: "Elyra-" + (snapshot?.record.name ?? "Configuration.plist")) { result in
            if case .failure(let error) = result { app.error = error.localizedDescription }
        }
    }
    private var fields: some View {
        List {
            Section {
                Label(localization.text(systemMode ? "Device configuration" : "Managed local copy"), systemImage: "doc.badge.gearshape").font(.headline)
                if systemMode && app.deviceLinks[id] == nil {
                    Button("Reconnect device", systemImage: "arrow.clockwise") {
                        if let base = snapshot { app.reconnectEditor(base, draft: edited, window: UUID(uuidString: windowID)) { base, draft in
                            snapshot = base; edited = draft; draftConflict = false
                        } }
                    }.disabled(app.busy > 0 || RuntimeDeviceContext.current.simulator)
                }
                if draftConflict { StatusNotice(title: "Draft conflict", detail: "This draft was created from an older document revision. Export it before discarding and reloading.", symbol: "exclamationmark.triangle") }
                Text("\(changes.count) " + localization.text("pending changes")).font(.caption).foregroundStyle(.secondary)
            }
            Section("Fields") {
                if edited.children.isEmpty {
                    Button { field = FieldSelection(path: [], value: edited, adding: false) } label: { Text(localization.text(edited.kind) + ": " + edited.summary) }
                } else {
                    ForEach(edited.children.filter { search.isEmpty || $0.0.localizedCaseInsensitiveContains(search) || $0.1.xml.localizedCaseInsensitiveContains(search) }, id: \.0) { key, value in
                        PlistNode(name: key, value: value, path: [key]) { field = $0 }
                    }
                }
            }
        }.listStyle(.insetGrouped).searchable(text: $search, prompt: Text(localization.text("Search fields and values")))
    }
    private var diffList: some View {
        List {
            Section {
                Text("Review changes").font(.headline)
            }
            ForEach(changes) { change in ChangeRow(change: change) }
            if changes.isEmpty { Text("No pending changes").foregroundStyle(.secondary) }
        }.listStyle(.insetGrouped)
    }
    private func load(restoreDraft: Bool = true) async {
        guard let workspace = app.workspace else { return }
        do {
            let current = try await workspace.snapshot(id)
            var value = current.value; draftConflict = false
            if restoreDraft, let window = UUID(uuidString: windowID), let draft = try await workspace.loadDraft(window: window, document: id) {
                value = draft.value
                draftConflict = draft.revision != current.revision && draft.value != current.value
            }
            if let initialCapability, value == current.value { try initialCapability.stage(in: &value) }
            snapshot = current; edited = value
            if let path = initialFieldPath, let selected = value.value(at: path) {
                field = FieldSelection(path: path, value: selected, adding: false)
            }
        } catch { app.error = error.localizedDescription }
    }
    private func save() {
        guard let current = snapshot else { return }
        let value = edited
        if systemMode {
            app.saveToDevice(documentID: id, value: value, expected: current) { saved in snapshot = saved; edited = saved.value }
            return
        }
        app.run { workspace in
            let saved = try await workspace.commit(value, expected: current)
            snapshot = saved; edited = saved.value
            if let window = UUID(uuidString: windowID) { try await workspace.discardDraft(window: window, document: id) }
        }
    }
}
struct FieldSelection: Identifiable {
    let id = UUID()
    let path: [String]
    let value: PlistValue?
    let adding: Bool
}
struct PlistNode: View {
    @EnvironmentObject private var localization: LocalizationStore
    let name: String
    let value: PlistValue
    let path: [String]
    let select: (FieldSelection) -> Void
    var body: some View {
        Group {
            if !value.children.isEmpty {
                DisclosureGroup {
                    ForEach(value.children, id: \.0) { key, child in
                        PlistNode(name: key, value: child, path: path + [key], select: select)
                    }
                    Button("Edit container") { select(FieldSelection(path: path, value: value, adding: false)) }
                } label: { label }
            } else {
                Button { select(FieldSelection(path: path, value: value, adding: false)) } label: { label }
            }
        }.contextMenu { Button("Edit value") { select(FieldSelection(path: path, value: value, adding: false)) } }
    }
    private var label: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name).font(.body).foregroundStyle(.primary).textSelection(.enabled)
            Text(localization.text(value.kind) + " • " + value.summary).font(.caption).foregroundStyle(.secondary).lineLimit(3)
        }.padding(.vertical, 4).frame(minHeight: 44)
    }
}
struct FieldEditor: View {
    @EnvironmentObject private var localization: LocalizationStore
    let selection: FieldSelection
    let apply: (PlistValue?, String) throws -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var key = ""
    @State private var text = ""
    @State private var error: String?
    @State private var deleting = false
    var body: some View {
        NavigationStack {
            Form {
                if selection.adding { TextField("New key", text: $key).autocorrectionDisabled().textInputAutocapitalization(.never) }
                else {
                    Text(selection.path.joined(separator: " / ")).textSelection(.enabled)
                    if !selection.path.isEmpty { TextField("Key name (dictionary only)", text: $key).autocorrectionDisabled().textInputAutocapitalization(.never) }
                }
                Section("Typed XML value") {
                    TextEditor(text: $text).font(.system(.body, design: .monospaced)).frame(minHeight: 240).autocorrectionDisabled().textInputAutocapitalization(.never)
                    Text("Edit a complete XML plist. String, Integer, Real, Boolean, Data, Date, Array and Dictionary are supported.").font(.caption).foregroundStyle(.secondary)
                }
                if let error { Text(localization.text(error)).foregroundStyle(.red).accessibilityLabel(localization.text(error)) }
                if !selection.adding && !selection.path.isEmpty { Button("Remove field", role: .destructive) { deleting = true } }
            }
            .navigationTitle(localization.text(selection.adding ? "Add field" : "Edit value"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Stage change") {
                        do {
                            guard !selection.adding || !key.isEmpty else { throw ElyraError.invalid("Enter a key name.") }
                            let value = text == selection.value?.xml ? selection.value! : try PlistValue.parseXML(text)
                            try apply(value, key); dismiss()
                        } catch { self.error = error.localizedDescription }
                    }
                }
            }
            .onAppear { text = (selection.value ?? .string("")).xml; key = selection.path.last ?? "" }
            .confirmationDialog(localization.text("Remove field?"), isPresented: $deleting, titleVisibility: .visible) {
                Button("Remove field", role: .destructive) {
                    do { try apply(nil, selection.path.last ?? ""); dismiss() } catch { self.error = error.localizedDescription }
                }
            }
        }
    }
}
struct ChangeRow: View {
    @EnvironmentObject private var localization: LocalizationStore
    let change: PlistChange
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(change.displayPath.isEmpty ? "/" : change.displayPath).font(.headline).textSelection(.enabled)
            Text(localization.text("Before") + ": " + (change.before.map { localization.text($0.kind) + " • " + $0.summary } ?? localization.text("Absent"))).foregroundStyle(.secondary)
            Text(localization.text("After") + ": " + (change.after.map { localization.text($0.kind) + " • " + $0.summary } ?? localization.text("Absent")))
            DisclosureGroup("Exact typed values") {
                if let before = change.before { Text(localization.text("Before") + "\n" + before.xml).font(.system(.caption, design: .monospaced)) }
                if let after = change.after { Text(localization.text("After") + "\n" + after.xml).font(.system(.caption, design: .monospaced)) }
            }
        }.font(.subheadline).padding(.vertical, 5).textSelection(.enabled)
    }
}
