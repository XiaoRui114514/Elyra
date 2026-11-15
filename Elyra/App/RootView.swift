// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var localization: LocalizationStore
    @EnvironmentObject private var app: AppEnvironment
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.scenePhase) private var phase
    @SceneStorage("area") private var area = Area.home.rawValue
    @SceneStorage("navigation") private var savedPath = ""
    @SceneStorage("navigationByArea") private var savedNavigation = ""
    @State private var navigation = SceneNavigation()
    @State private var restored = false
    var body: some View {
        GeometryReader { geometry in
            let layout = WindowLayout.resolve(width: geometry.size.width, height: geometry.size.height, accessibilityText: typeSize.isAccessibilitySize)
            Group {
                if layout == .compact {
                    TabView(selection: $area) {
                        ForEach(Area.allCases, id: \.rawValue) { item in
                            NavigationStack(path: pathBinding(for: item)) {
                                AreaView(area: item)
                                    .navigationDestination(for: Screen.self, destination: destination)
                                    .navigationTitle(item == .home ? "Elyra" : localization.text(item.rawValue))
                            }
                            .tabItem { Label(localization.text(item.rawValue), systemImage: item.symbol) }
                            .tag(item.rawValue)
                        }
                    }
                } else {
                    NavigationSplitView {
                        List(selection: Binding<String?>(get: { area }, set: { value in
                            if let value { area = value }
                        })) {
                            ForEach(Area.allCases, id: \.rawValue) { item in
                                Label(localization.text(item.rawValue), systemImage: item.symbol).tag(item.rawValue).accessibilityIdentifier("area." + item.rawValue.lowercased())
                            }
                        }
                        .listStyle(.sidebar)
                        .navigationTitle("Elyra")
                        .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
                    } detail: {
                        NavigationStack(path: pathBinding(for: Area(rawValue: area) ?? .home)) {
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
            navigation = SceneNavigation.restored(savedNavigation.data(using: .utf8), legacy: savedPath.data(using: .utf8), area: Area(rawValue: area) ?? .home)
        }
        .onChange(of: navigation) { _, value in
            if let data = try? JSONEncoder().encode(value) { savedNavigation = String(decoding: data, as: UTF8.self) }
        }
        .onChange(of: phase) { _, value in if value == .active { Task { await app.refresh() } } }
    }
    private func pathBinding(for item: Area) -> Binding<[Screen]> {
        Binding(get: { navigation.path(for: item) }, set: { navigation.setPath($0, for: item) })
    }
    @ViewBuilder private func destination(_ screen: Screen) -> some View {
        switch screen {
        case .document(let id): DocumentEditor(id: id)
        case .field(let id, let path): DocumentEditor(id: id, initialFieldPath: path)
        case .capability(let id): CapabilityView(id: id)
        case .category(let category): SystemCategoryView(category: category)
        case .island: IslandLab()
        case .islandDocument(let id): IslandConfigurationView(id: id)
        case .files: FilesView()
        case .textAsset(let id): TextAssetEditor(id: id)
        case .archive(let id): ArchiveInspector(id: id)
        case .backups: BackupsView()
        case .diagnostics: DiagnosticsView()
        case .history: HistoryView()
        case .licenses: AboutView()
        case .language: LanguageSettingsView()
        case .device: DeviceConfigurationView()
        case .systemEditor(let id): DocumentEditor(id: id, systemMode: true)
        case .openSource: OpenSourceLicensesView()
        case .deviceBackup(let id): DeviceBackupDetail(id: id)
        case .plans: ConfigurationPlansView()
        case .displayDiagnostics: DisplayDiagnosticsView()
        }
    }
}
private struct WideKey: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues {
    var elyraWide: Bool { get { self[WideKey.self] } set { self[WideKey.self] = newValue } }
}
