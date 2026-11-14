// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI

struct SystemCategory: Identifiable {
    let id: String
    let title: String
    let symbol: String
    static let all = [Self(id: "display", title: "Display", symbol: "sun.max"), Self(id: "device", title: "Device", symbol: "iphone"), Self(id: "ipad", title: "iPad", symbol: "ipad.landscape"), Self(id: "intelligence", title: "Intelligence", symbol: "sparkle"), Self(id: "advanced", title: "Advanced", symbol: "gearshape.2")]
    static func find(_ id: String) -> Self { all.first { $0.id == id } ?? all[0] }
}
struct SystemPage<Content: View>: View {
    let identifier: String
    let content: Content
    init(identifier: String, @ViewBuilder content: () -> Content) { self.identifier = identifier; self.content = content() }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) { content }
                .frame(maxWidth: .infinity, alignment: .leading).padding(20)
        }.background(Color(uiColor: .systemGroupedBackground)).accessibilityIdentifier(identifier)
    }
}
struct SystemPanel<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) { content }
            .frame(maxWidth: .infinity, alignment: .leading).padding(20)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
struct SystemTile: View {
    let title: String
    let detail: String
    let symbol: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: symbol).font(.title2).foregroundStyle(.tint).accessibilityHidden(true)
            Text(title).font(.headline).foregroundStyle(.primary).fixedSize(horizontal: false, vertical: true)
            Text(detail).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }.frame(maxWidth: .infinity, minHeight: 100, alignment: .leading).padding(20)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 20))
    }
}
struct DeviceAccessCard: View {
    @EnvironmentObject private var app: AppEnvironment
    @EnvironmentObject private var localization: LocalizationStore
    var body: some View {
        SystemPanel {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: app.deviceAccessState == .readWrite ? "checkmark.circle.fill" : "cpu").font(.title2).foregroundStyle(.tint).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Device access").font(.headline)
                    Text(localization.text(app.deviceAccessState.rawValue)).foregroundStyle(.secondary).accessibilityIdentifier("device.access.status")
                }
                Spacer(minLength: 0)
                if app.connectingDevice { ProgressView() }
            }
            if let error = app.systemError ?? app.deviceSnapshot?.accessError {
                Text(localization.text(error)).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            ViewThatFits(in: .horizontal) {
                HStack { actions }
                VStack(alignment: .leading, spacing: 12) { actions }
            }
        }
    }
    @ViewBuilder private var actions: some View {
        Button("Check access again", systemImage: "arrow.clockwise") { app.connectDevice() }
            .disabled(app.busy > 0 || RuntimeDeviceContext.current.simulator).accessibilityIdentifier("device.retry")
        NavigationLink("Connection details", value: Screen.device).buttonStyle(.plain).accessibilityIdentifier("system.device")
    }
}
struct SystemOverview: View {
    @EnvironmentObject private var localization: LocalizationStore
    @EnvironmentObject private var app: AppEnvironment
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        SystemPage(identifier: "system.dashboard") {
            DeviceAccessCard()
            Text("System features").font(.title2.bold()).accessibilityAddTraits(.isHeader)
            LazyVGrid(columns: typeSize.isAccessibilitySize ? [GridItem(.flexible())] : [GridItem(.adaptive(minimum: 200), spacing: 16)], alignment: .leading, spacing: 16) {
                ForEach(SystemCategory.all) { category in
                    NavigationLink(value: Screen.category(category.id)) {
                        SystemTile(title: localization.text(category.title), detail: localization.text("Configurations") + " · " + String(Capability.all.filter { $0.category == category.id }.count), symbol: category.symbol)
                    }.buttonStyle(.plain).accessibilityIdentifier("system.category." + category.id)
                }
            }
            NavigationLink(value: Screen.diagnostics) {
                SystemTile(title: localization.text("Device diagnostics"), detail: localization.text("Access, signing and system information"), symbol: "stethoscope")
            }.buttonStyle(.plain)
        }.task { await app.ensureDeviceConnection() }
    }
}
extension Capability {
    var systemSymbol: String {
        switch id {
        case "dynamicIsland": "capsule"
        case "aod", "aodVibrancy", "aodHighLuminance", "aodFlipbook", "aodFlipbookCount": "sun.horizon"
        case "chargeLimit": "battery.75percent"
        case "cameraControl": "camera"
        case "actionButton": "button.programmable"
        case "bootChime": "speaker.wave.2"
        case "stageManager": "rectangle.3.group"
        case "pencil": "pencil.tip"
        default: SystemCategory.find(category).symbol
        }
    }
    func currentLabel(in value: PlistValue?) -> String {
        guard let value else { return "Not read yet" }
        let current = keys.map { value.value(at: ["CacheExtra", $0]) }
        if current.allSatisfy({ $0 == nil }) { return "Not set" }
        var preset = value
        if (try? stage(in: &preset)) != nil, keys.allSatisfy({ value.value(at: ["CacheExtra", $0]) == preset.value(at: ["CacheExtra", $0]) }) { return "Matches preset" }
        return "Custom value"
    }
}
