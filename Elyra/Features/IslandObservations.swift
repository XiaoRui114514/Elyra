// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI

struct IslandObservationForm: View {
    @EnvironmentObject private var localization: LocalizationStore
    @EnvironmentObject private var app: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    @State private var activity = IslandActivity.idle
    @State private var orientation = IslandOrientation.portrait
    @State private var outcome = IslandOutcome.other
    @State private var playing: Bool?
    @State private var notes = ""
    @State private var documentID: UUID?
    private let device = RuntimeDeviceContext.current
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(device.hardware + " • " + device.build).textSelection(.enabled)
                    Text(device.osVersion).font(.caption)
                    StatusNotice(title: device.simulator ? "Simulator observation" : "User-recorded physical-device observation",
                                 detail: "This log records what you observe. It is not an automated verification that Elyra changed the system.")
                }
                Section("Activity & appearance") {
                    Picker("Activity state", selection: $activity) { ForEach(IslandActivity.allCases) { Text(localization.text($0.rawValue)).tag($0) } }
                    Picker("Orientation", selection: $orientation) { ForEach(IslandOrientation.allCases) { Text(localization.text($0.rawValue)).tag($0) } }
                    if activity.canIncludeMedia {
                        Picker("Media playback", selection: $playing) {
                            Text("Not recorded").tag(Bool?.none)
                            Text("Playing").tag(Optional(true))
                            Text("Paused").tag(Optional(false))
                        }
                    }
                    Picker("Observed appearance", selection: $outcome) { ForEach(IslandOutcome.allCases) { Text(localization.text($0.rawValue)).tag($0) } }
                }
                Section("Related local configuration") {
                    Picker("Configuration document", selection: $documentID) {
                        Text("None").tag(UUID?.none)
                        ForEach(app.state.documents) { Text($0.name).tag(Optional($0.id)) }
                    }
                    Text("Linking a document records its current local revision, not proof of the system configuration.").font(.caption).foregroundStyle(.secondary)
                }
                Section("Notes") {
                    TextEditor(text: $notes).frame(minHeight: 120).accessibilityIdentifier("island.observation.notes")
                    Text("Record shape, corner roundness, position, activity content, display zoom and any keyboard issues. Avoid account details or identifiers.").font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle(localization.text("Record appearance observation"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save observation") {
                        app.run { workspace in
                            let revision: String?
                            if let documentID { revision = try await workspace.snapshot(documentID).revision } else { revision = nil }
                            let observation = IslandObservation(hardware: device.hardware, osVersion: device.osVersion, build: device.build,
                                                                simulator: device.simulator, activity: activity, orientation: orientation,
                                                                playing: activity.canIncludeMedia ? playing : nil, outcome: outcome, notes: notes, documentID: documentID, documentRevision: revision)
                            try await workspace.recordIslandObservation(observation)
                            dismiss()
                        }
                    }.accessibilityIdentifier("island.observation.save").disabled(notes.utf8.count > 16_000 || app.busy > 0)
                }
            }
        }
    }
}
struct IslandObservationDetail: View {
    @EnvironmentObject private var localization: LocalizationStore
    let observation: IslandObservation
    var body: some View {
        List {
            Section {
                Text(localization.text(observation.simulator ? "Simulator observation" : "User-recorded physical-device observation")).font(.headline)
                Text("This log records what you observe. It is not an automated verification that Elyra changed the system.").font(.caption).foregroundStyle(.secondary)
                Text(observation.date, format: .dateTime)
            }
            Section("Device") {
                LabeledContent("Hardware identifier", value: observation.hardware)
                LabeledContent("System build", value: observation.build)
                Text(observation.osVersion)
            }
            Section("Activity & appearance") {
                Text(localization.text(observation.activity.rawValue))
                Text(localization.text(observation.orientation.rawValue))
                if observation.activity.canIncludeMedia, let playing = observation.playing { Text(localization.text(playing ? "Playing" : "Paused")) }
                Text(localization.text(observation.outcome.rawValue))
            }
            if let revision = observation.documentRevision { Section("Local document revision") { Text(revision).font(.caption).textSelection(.enabled) } }
            Section("Notes") { Text(observation.notes.isEmpty ? localization.text("None") : observation.notes).textSelection(.enabled) }
        }.navigationTitle(localization.text("Appearance observation"))
    }
}
