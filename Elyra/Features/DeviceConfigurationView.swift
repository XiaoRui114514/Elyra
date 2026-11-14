// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI

struct DeviceConfigurationView: View {
    @EnvironmentObject private var app: AppEnvironment
    @EnvironmentObject private var localization: LocalizationStore
    @State private var editor: UUID?
    @State private var restore: SystemBackup?
    @State private var recover = false
    var body: some View {
        List {
            Section {
                Label(localization.text(app.deviceAccessState.rawValue), systemImage: "iphone.and.arrow.forward").font(.headline)
                Button(localization.text(app.deviceSnapshot == nil ? "Connect to device" : "Read device again")) { app.connectDevice() }.disabled(app.busy > 0 || RuntimeDeviceContext.current.simulator).accessibilityIdentifier("device.connect")
                if RuntimeDeviceContext.current.simulator { Text("Device system access is unavailable in the Simulator.").font(.caption).foregroundStyle(.secondary) }
            }
            if let snapshot = app.deviceSnapshot {
                Section("Live configuration") {
                    LabeledContent("Access", value: localization.text(snapshot.writable ? "Read and write" : "Read only"))
                    if let error = snapshot.accessError { Text(localization.text(error)).font(.caption).foregroundStyle(.secondary) }
                    DisclosureGroup("Configuration fields") {
                        Text("SHA-256: " + snapshot.revision).font(.system(.caption2, design: .monospaced)).textSelection(.enabled)
                    }
                    Button("Edit device configuration", systemImage: "slider.horizontal.3") { app.openDeviceEditor { editor = $0 } }.disabled(app.busy > 0)
                }
            }
            Section {
                DisclosureGroup("Signing configuration") {
                LabeledContent("Embedded App Groups", value: DeviceBackend.declaredAppGroups().count.formatted())
                LabeledContent("Accessible App Groups", value: GXEntitlementsReader.usableAppGroups().count.formatted())
                }
            }
            if let error = app.systemError { Section("Connection details") { Text(localization.text(error)).textSelection(.enabled) } }
            Section("Device backups") {
                ForEach(app.deviceBackups) { backup in
                    Button { restore = backup } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(backup.date, format: .dateTime).foregroundStyle(.primary)
                            Text(localization.text(backup.reason)).font(.caption).foregroundStyle(.secondary)
                        }
                    }.disabled(app.deviceSnapshot?.writable != true || app.busy > 0)
                }
                if app.deviceBackups.isEmpty { Text("No device backups yet") }
            }
            if app.systemRecoveryPending { Section("Recovery") {
                Button("Recover interrupted system write", role: .destructive) { recover = true }.disabled(app.busy > 0 || RuntimeDeviceContext.current.simulator)
            } }
        }
        .navigationTitle(localization.text("Device configuration"))
        .task { await app.ensureDeviceConnection() }
        .navigationDestination(item: $editor) { id in DocumentEditor(id: id, systemMode: true) }
        .confirmationDialog(localization.text("Restore device backup?"), isPresented: Binding(get: { restore != nil }, set: { if !$0 { restore = nil } }), titleVisibility: .visible) {
            Button("Confirm system restore", role: .destructive) {
                if let backup = restore, let expected = app.deviceSnapshot { app.performDevice { store in app.deviceSnapshot = try await store.restore(backup.id, expected: expected) } }
                restore = nil
            }
        }
        .confirmationDialog(localization.text("Recover system configuration?"), isPresented: $recover, titleVisibility: .visible) {
            Button("Confirm recovery", role: .destructive) { app.performDevice { store in try await store.recoverInterruptedWrite(); app.deviceSnapshot = try await store.connect() } }
        }
    }
}
