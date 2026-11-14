// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI
import UniformTypeIdentifiers

struct IslandLab: View {
    @EnvironmentObject private var localization: LocalizationStore
    @EnvironmentObject private var app: AppEnvironment
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var state = "Idle"
    @State private var playing = true
    @State private var observing = false
    @State private var importing = false
    @State private var exporting = false
    @State private var export: ExportDocument?
    private let states = ["Idle", "Compact music", "Expanded music", "Multiple activities"]
    private let device = RuntimeDeviceContext.current
    var body: some View {
        List {
            Section("Device & access") {
                LabeledContent("Hardware identifier", value: device.hardware)
                Text(device.osVersion).textSelection(.enabled)
                LabeledContent("System build", value: device.build)
                if device.simulator { Text("Simulator records are not evidence of system modification.").foregroundStyle(.secondary) }
                NavigationLink("Device configuration", value: Screen.device)
                Text("Capability editing and system capsule geometry are different controls. No verified radius parameter is available.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Inspect actual configuration") {
                Button("Import plist", systemImage: "square.and.arrow.down") { importing = true }
                ForEach(app.state.documents) { document in
                    NavigationLink(value: Screen.islandDocument(document.id)) {
                        FeatureLabel(title: document.name, detail: "Inspect flag, artwork identity and recorded local baseline", symbol: "doc.text.magnifyingglass", localizesTitle: false)
                    }
                }
                if app.state.documents.isEmpty { Text("No imported Dynamic Island configuration").foregroundStyle(.secondary) }
            }
            Section("Appearance observation log") {
                Button("Record appearance observation", systemImage: "plus") { observing = true }.accessibilityIdentifier("island.record")
                Button("Export research log", systemImage: "square.and.arrow.up") {
                    app.run { workspace in export = ExportDocument(data: try await workspace.exportResearchReport()); exporting = true }
                }.disabled(app.state.islandObservations.isEmpty)
                ForEach(app.state.islandObservations) { observation in
                    NavigationLink {
                        IslandObservationDetail(observation: observation)
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(localization.text(observation.activity.rawValue) + " • " + localization.text(observation.orientation.rawValue))
                            Text(localization.text(observation.outcome.rawValue)).font(.caption)
                            Text(observation.hardware + " • " + observation.build).font(.caption).foregroundStyle(.secondary)
                            Text(localization.text(observation.simulator ? "Simulator observation" : "User-recorded physical-device observation")).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Section("Source-confirmed controls") {
                Text("DeviceSupportsDynamicIsland changes a capability flag. ArtworkDeviceSubType selects a device artwork/layout identity. Neither exposes verified controls for system capsule roundness, proportions, activity content placement or animations.")
                Text("Subtype is not a pixel size. Upstream presets differ; no subtype is validated as an iPad Dynamic Island appearance repair.").foregroundStyle(.secondary)
                NavigationLink("Dynamic Island capability", value: Screen.capability("dynamicIsland"))
            }
            Section("Appearance preview") {
                Picker("Activity state", selection: $state) { ForEach(states, id: \.self) { Text(localization.text($0)).tag($0) } }
                IslandStudy(state: state, playing: playing).padding(.vertical)
                if state == "Compact music" || state == "Expanded music" { Toggle("Playing", isOn: $playing) }
                Text("Illustrative layout only. This preview does not read Now Playing, implement a system overlay or demonstrate a successful iPad fix.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Research findings") {
                Text("Orientation or artwork identity mismatch is a hypothesis, not a confirmed cause. Compare shape and corners across idle, recording, timers, calls, media and multiple activities in both orientations. Exact build, current subtype and a trusted original are still needed.")
                Text("Compact, expanded and multiple-activity states have separate layout behavior. Improving one state does not establish the others.")
                NavigationLink("Backups", value: Screen.backups)
                Text("Backups here restore imported local files only. Elyra cannot restore your system Dynamic Island without authorized access and a verified same-device original.").font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle(localization.text("Dynamic Island"))
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: state)
        .sheet(isPresented: $observing) { IslandObservationForm() }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.propertyList, .xml, .data]) { result in
            switch result { case .success(let url): app.importURL(url); case .failure(let error): app.error = error.localizedDescription }
        }
        .fileExporter(isPresented: $exporting, document: export, contentType: .json, defaultFilename: "Elyra-DI-observations.json") { result in
            if case .failure(let error) = result { app.error = error.localizedDescription }
        }
    }
}

private struct IslandStudy: View {
    @EnvironmentObject private var localization: LocalizationStore
    let state: String
    let playing: Bool
    var body: some View {
        VStack(spacing: 14) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { art; Spacer(minLength: 28); waveform }
                HStack(spacing: 8) { art; waveform }
            }
            if state == "Expanded music" {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Music playback study").font(.headline)
                    Text("Album art • track information • controls").font(.caption).foregroundStyle(.gray)
                    ProgressView(value: 0.35).tint(.white).accessibilityLabel("Illustrative playback progress")
                    HStack { Image(systemName: "backward.fill"); Spacer(); Image(systemName: playing ? "pause.fill" : "play.fill"); Spacer(); Image(systemName: "forward.fill") }.font(.title2)
                }
            }
            if state == "Multiple activities" { Label("Separate activity", systemImage: "record.circle.fill").font(.caption).foregroundStyle(.red) }
        }
        .foregroundStyle(.white).padding(state == "Expanded music" ? 24 : 16)
        .frame(maxWidth: state == "Expanded music" ? 440 : 280)
        .background(.black, in: RoundedRectangle(cornerRadius: state == "Expanded music" ? 36 : 32, style: .continuous))
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(localization.text("Illustrative layout only") + ": " + localization.text(state))
    }
    private var art: some View { Image(systemName: state == "Idle" ? "circle.fill" : "music.note").font(.title3).frame(width: 32, height: 32).background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 8)) }
    private var waveform: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(0..<5) { index in Capsule().fill(playing ? Color.mint : Color.gray).frame(width: 3, height: state == "Idle" ? 3 : playing ? CGFloat([12,22,16,26,10][index]) : 4) }
        }.frame(minWidth: 30)
    }
}
