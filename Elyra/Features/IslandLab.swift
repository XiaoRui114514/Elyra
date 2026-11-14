// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI
import UniformTypeIdentifiers

struct IslandLab: View {
    @EnvironmentObject private var app: AppEnvironment
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var state = "Compact music"
    @State private var playing = true
    @State private var observing = false
    @State private var importing = false
    @State private var exporting = false
    @State private var export: ExportDocument?
    private let states = ["Idle", "Compact music", "Expanded music", "Multiple activities"]
    private let device = RuntimeDeviceContext.current
    var body: some View {
        List {
            Section {
                StatusNotice(title: "iPad music playback investigation", detail: "iPad capability overrides can show a tall media region at the screen edge during playback. Inspect configuration and record each activity and orientation separately.", symbol: "waveform")
                SupportBadge(status: .unverified)
            }
            Section("Device & access") {
                LabeledContent("Hardware identifier", value: device.hardware)
                Text(device.osVersion).textSelection(.enabled)
                LabeledContent("System build", value: device.build)
                if device.simulator { Text("Simulator records are not evidence of system modification.").foregroundStyle(.secondary) }
                StatusNotice(title: "System write unavailable", detail: "No authorized, verified system writer is installed. Elyra cannot change the system capsule geometry with public APIs.")
            }
            Section("Inspect actual configuration") {
                Button("Import plist", systemImage: "square.and.arrow.down") { importing = true }
                ForEach(app.state.documents) { document in
                    NavigationLink(value: Screen.islandDocument(document.id)) {
                        FeatureLabel(title: document.name, detail: "Inspect flag, artwork identity and recorded local baseline", symbol: "doc.text.magnifyingglass")
                    }
                }
                if app.state.documents.isEmpty { Text("No imported Dynamic Island configuration").foregroundStyle(.secondary) }
            }
            Section("Playback observation log") {
                Button("Record playback observation", systemImage: "plus") { observing = true }.accessibilityIdentifier("island.record")
                Button("Export research log", systemImage: "square.and.arrow.up") {
                    app.run { workspace in export = ExportDocument(data: try await workspace.exportResearchReport()); exporting = true }
                }.disabled(app.state.islandObservations.isEmpty)
                ForEach(app.state.islandObservations) { observation in
                    NavigationLink {
                        IslandObservationDetail(observation: observation)
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(L(observation.activity.rawValue) + " • " + L(observation.orientation.rawValue))
                            Text(L(observation.outcome.rawValue)).font(.caption)
                            Text(observation.hardware + " • " + observation.build).font(.caption).foregroundStyle(.secondary)
                            Text(observation.simulator ? "Simulator observation" : "User-recorded physical-device observation").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Section("Source-confirmed controls") {
                Text("DeviceSupportsDynamicIsland changes a capability flag. ArtworkDeviceSubType selects a device artwork/layout identity. Neither exposes independent music capsule radius, album art spacing, waveform alignment or animation controls.")
                Text("Subtype is not a pixel size. Upstream presets differ; no subtype is validated as an iPad music-layout repair.").foregroundStyle(.secondary)
                NavigationLink("Dynamic Island capability", value: Screen.capability("dynamicIsland"))
            }
            Section("Visual study — not a system modification") {
                Picker("Activity state", selection: $state) { ForEach(states, id: \.self) { Text(L($0)).tag($0) } }
                IslandStudy(state: state, playing: playing).padding(.vertical)
                Toggle("Playing", isOn: $playing)
                Text("Illustrative layout only. This preview does not read Now Playing, implement a system overlay or demonstrate a successful iPad fix.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Research findings") {
                Text("Orientation or artwork identity mismatch is a hypothesis, not a confirmed cause. We need the physical iPad model, exact build, current subtype, a trusted original and controlled portrait/landscape playback tests.")
                Text("Compact, expanded and multiple-activity states have separate layout behavior. Improving one state does not establish the others.")
                NavigationLink("Backup center", value: Screen.backups)
                Text("Backups here restore imported local files only. Elyra cannot restore your system Dynamic Island without authorized access and a verified same-device original.").font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Dynamic Island Lab")
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
        .accessibilityLabel(L("Illustrative layout only") + ": " + L(state))
    }
    private var art: some View { Image(systemName: state == "Idle" ? "circle.fill" : "music.note").font(.title3).frame(width: 32, height: 32).background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 8)) }
    private var waveform: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(0..<5) { index in Capsule().fill(playing ? Color.mint : Color.gray).frame(width: 3, height: state == "Idle" ? 3 : playing ? CGFloat([12,22,16,26,10][index]) : 4) }
        }.frame(minWidth: 30)
    }
}
