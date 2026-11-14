// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI

@main struct ElyraApp: App {
    @StateObject private var environment = AppEnvironment()
    @StateObject private var localization = LocalizationStore()
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(environment)
                .environmentObject(localization)
                .environment(\.locale, localization.locale)
                .task { await environment.refresh() }
                .alert(localization.text("Operation could not be completed"), isPresented: Binding(get: { environment.error != nil }, set: { if !$0 { environment.error = nil } })) {
                    Button(localization.text("OK")) { environment.error = nil }
                } message: { Text(localization.text(environment.error ?? "")) }
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button(localization.text("Refresh workspace")) { Task { await environment.refresh() } }.keyboardShortcut("r")
            }
        }
    }
}
