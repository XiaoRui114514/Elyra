// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI
struct RespringScreen: View {
    @EnvironmentObject private var app: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack {
            RespringView().allowsHitTesting(false)
            VStack(spacing: 20) {
                ProgressView()
                Text("Restarting system interface…").font(.headline)
                Text("If the system interface does not restart, cancel and restart the device manually.").foregroundStyle(.secondary).multilineTextAlignment(.center)
                Button("Cancel") { app.respringing = false; dismiss() }
            }.padding(24).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24)).padding()
        }
    }
}
