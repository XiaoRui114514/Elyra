// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI

@main struct ElyraApp: App {
    @StateObject private var environment = AppEnvironment()
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(environment)
                .task { await environment.refresh() }
                .alert("Operation could not be completed", isPresented: Binding(get: { environment.error != nil }, set: { if !$0 { environment.error = nil } })) {
                    Button("OK") { environment.error = nil }
                } message: { Text(environment.error ?? "") }
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Refresh workspace") { Task { await environment.refresh() } }.keyboardShortcut("r")
            }
        }
    }
}
