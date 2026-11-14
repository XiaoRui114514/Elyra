// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI

struct IslandObservationForm: View {
    @EnvironmentObject private var app: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    @State private var activity = IslandActivity.compact
    @State private var orientation = IslandOrientation.portrait
    @State private var outcome = IslandOutcome.other
    @State private var playing = true
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
                Section("Playback state") {
                    Picker("Activity state", selection: $activity) { ForEach(IslandActivity.allCases) { Text(L($0.rawValue)).tag($0) } }
                    Picker("Orientation", selection: $orientation) { ForEach(IslandOrientation.allCases) { Text(L($0.rawValue)).tag($0) } }
                    Toggle("Playing", isOn: $playing)
                    Picker("Observed appearance", selection: $outcome) { ForEach(IslandOutcome.allCases) { Text(L($0.rawValue)).tag($0) } }
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
                    Text("Record artwork placement, waveform alignment, recording/timer activity, display zoom and any keyboard issues. Avoid account details or identifiers.").font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Record playback observation")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save observation") {
                        app.run { workspace in
                            let revision: String?
                            if let documentID { revision = try await workspace.snapshot(documentID).revision } else { revision = nil }
                            let observation = IslandObservation(hardware: device.hardware, osVersion: device.osVersion, build: device.build,
                                                                simulator: device.simulator, activity: activity, orientation: orientation,
                                                                playing: playing, outcome: outcome, notes: notes, documentID: documentID, documentRevision: revision)
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
    let observation: IslandObservation
    var body: some View {
        List {
            Section {
                Text(observation.simulator ? "Simulator observation" : "User-recorded physical-device observation").font(.headline)
                Text("This log records what you observe. It is not an automated verification that Elyra changed the system.").font(.caption).foregroundStyle(.secondary)
                Text(observation.date, format: .dateTime)
            }
            Section("Device") {
                LabeledContent("Hardware identifier", value: observation.hardware)
                LabeledContent("System build", value: observation.build)
                Text(observation.osVersion)
            }
            Section("Playback state") {
                Text(L(observation.activity.rawValue))
                Text(L(observation.orientation.rawValue))
                Text(observation.playing ? "Playing" : "Paused")
                Text(L(observation.outcome.rawValue))
            }
            if let revision = observation.documentRevision { Section("Local document revision") { Text(revision).font(.caption).textSelection(.enabled) } }
            Section("Notes") { Text(observation.notes.isEmpty ? L("None") : observation.notes).textSelection(.enabled) }
        }.navigationTitle("Playback observation")
    }
}
