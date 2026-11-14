// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI

struct IslandLab: View {
    @EnvironmentObject private var app: AppEnvironment
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var state = "Compact music"
    @State private var playing = true
    @State private var configuration: [String] = []
    private let states = ["Idle", "Compact music", "Expanded music", "Multiple activities", "Landscape", "Portrait"]
    var body: some View {
        List {
            Section {
                StatusNotice(title: "iPad music playback investigation", detail: "Your screenshots show a tall media region on the left edge, with album art above the waveform. A separate recording activity is also visible. Notification banners at the top are separate system UI.", symbol: "waveform")
                SupportBadge(status: .unverified)
            }
            Section("Device & access") {
                Text(UIDevice.current.model)
                Text(ProcessInfo.processInfo.operatingSystemVersionString).textSelection(.enabled)
                StatusNotice(title: "System write unavailable", detail: "No authorized, verified system writer is installed. Elyra cannot change the system capsule geometry with public APIs.")
            }
            Section("Imported configuration") {
                if configuration.isEmpty { Text("No imported Dynamic Island configuration").foregroundStyle(.secondary) }
                ForEach(configuration, id: \.self) { Text($0).font(.caption).textSelection(.enabled) }
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
        .task(id: app.state.documents) {
            guard let workspace = app.workspace else { return }
            var lines: [String] = []
            for record in app.state.documents {
                do {
                    let doc = try await workspace.snapshot(record.id)
                    let flag = doc.value.value(at: ["CacheExtra", "YlEtTtHlNesRBMal1CqRaA"])?.summary ?? L("Absent")
                    let subtype = doc.value.value(at: ["CacheExtra", "oPeik/9e8lQWMszEjbPzng", "ArtworkDeviceSubType"])?.summary ?? L("Absent")
                    lines.append(record.name + "\nDynamic Island: " + flag + "\nArtworkDeviceSubType: " + subtype + "\n" + L("Managed local copy"))
                } catch { app.error = error.localizedDescription }
            }
            configuration = lines
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
