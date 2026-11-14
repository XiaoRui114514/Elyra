// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI

enum Screen: Hashable, Codable {
    case document(UUID), field(UUID, [String]), islandDocument(UUID), textAsset(UUID), archive(UUID), capability(String), island, category(String), files, backups, diagnostics, history, licenses, language
}
enum Area: String, CaseIterable {
    case home = "Home", appearance = "Appearance", system = "System", tools = "Tools", settings = "Settings"
    var symbol: String {
        switch self {
        case .home: "house"
        case .appearance: "paintpalette"
        case .system: "switch.2"
        case .tools: "wrench.and.screwdriver"
        case .settings: "gearshape"
        }
    }
}
struct RootView: View {
    @EnvironmentObject private var localization: LocalizationStore
    @EnvironmentObject private var app: AppEnvironment
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.scenePhase) private var phase
    @SceneStorage("area") private var area = Area.home.rawValue
    @SceneStorage("navigation") private var savedPath = ""
    @State private var path: [Screen] = []
    @State private var restored = false
    var body: some View {
        GeometryReader { geometry in
            let layout = WindowLayout.resolve(width: geometry.size.width, height: geometry.size.height, accessibilityText: typeSize.isAccessibilitySize)
            Group {
                if layout == .compact {
                    NavigationStack(path: $path) {
                        TabView(selection: $area) {
                            ForEach(Area.allCases, id: \.rawValue) { item in
                                AreaView(area: item).tabItem { Label(localization.text(item.rawValue), systemImage: item.symbol) }.tag(item.rawValue)
                            }
                        }
                        .navigationDestination(for: Screen.self, destination: destination)
                        .navigationTitle(area == "Home" ? "Elyra" : localization.text(area))
                    }
                } else {
                    NavigationSplitView {
                        List(selection: Binding<String?>(get: { area }, set: { value in
                            if let value { area = value; path.removeAll() }
                        })) {
                            ForEach(Area.allCases, id: \.rawValue) { item in
                                Label(localization.text(item.rawValue), systemImage: item.symbol).tag(item.rawValue).accessibilityIdentifier("area." + item.rawValue.lowercased())
                            }
                        }
                        .listStyle(.sidebar)
                        .navigationTitle("Elyra")
                        .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
                    } detail: {
                        NavigationStack(path: $path) {
                            AreaView(area: Area(rawValue: area) ?? .home)
                                .navigationTitle(area == "Home" ? "Elyra" : localization.text(area))
                                .navigationDestination(for: Screen.self, destination: destination)
                        }
                    }.navigationSplitViewStyle(.balanced)
                }
            }
            .environment(\.elyraWide, layout == .wide)
            .overlay(alignment: .top) {
                if app.busy > 0 { ProgressView().padding(12).background(.regularMaterial, in: Capsule()).accessibilityLabel("Working") }
            }
        }
        .onAppear {
            guard !restored else { return }; restored = true
            if let data = savedPath.data(using: .utf8), let saved = try? JSONDecoder().decode([Screen].self, from: data) { path = saved }
        }
        .onChange(of: path) { _, value in
            if let data = try? JSONEncoder().encode(value) { savedPath = String(decoding: data, as: UTF8.self) }
        }
        .onChange(of: phase) { _, value in if value == .active { Task { await app.refresh() } } }
    }
    @ViewBuilder private func destination(_ screen: Screen) -> some View {
        switch screen {
        case .document(let id): DocumentEditor(id: id)
        case .field(let id, let path): DocumentEditor(id: id, initialFieldPath: path)
        case .capability(let id): CapabilityView(id: id)
        case .category(let category): CapabilityList(category: category)
        case .island: IslandLab()
        case .islandDocument(let id): IslandConfigurationView(id: id)
        case .files: FilesView()
        case .textAsset(let id): TextAssetEditor(id: id)
        case .archive(let id): ArchiveInspector(id: id)
        case .backups: BackupsView()
        case .diagnostics: DiagnosticsView()
        case .history: HistoryView()
        case .licenses: LicensesView()
        case .language: LanguageSettingsView()
        }
    }
}
private struct WideKey: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues {
    var elyraWide: Bool { get { self[WideKey.self] } set { self[WideKey.self] = newValue } }
}
