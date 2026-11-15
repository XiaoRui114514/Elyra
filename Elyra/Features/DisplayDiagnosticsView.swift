// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI
import QuartzCore

private struct WindowDisplaySnapshot: Equatable {
    var window = CGSize.zero
    var content = CGSize.zero
    var safeArea = UIEdgeInsets.zero
    var pixels = CGSize.zero
    var scale: CGFloat = 0
    var maximumFPS = 0
    var currentEDR: CGFloat = 0
    var potentialEDR: CGFloat = 0
}
@MainActor private final class DisplayDiagnosticsModel: ObservableObject {
    @Published var snapshot = WindowDisplaySnapshot()
    @Published var callbacks: Double?
    @Published var measuring = false
    private var link: CADisplayLink?
    private var start: CFTimeInterval?
    private var count = 0
    private let target = DisplayCallbackTarget()
    func update(window: UIWindow, content: CGSize) {
        let screen = window.windowScene?.screen ?? window.screen
        let next = WindowDisplaySnapshot(window: window.bounds.size, content: content, safeArea: window.safeAreaInsets,
            pixels: screen.nativeBounds.size, scale: screen.scale, maximumFPS: screen.maximumFramesPerSecond,
            currentEDR: screen.currentEDRHeadroom, potentialEDR: screen.potentialEDRHeadroom)
        if snapshot != next { snapshot = next }
    }
    func begin() {
        guard !measuring else { return }; measuring = true; callbacks = nil; start = nil; count = 0; target.owner = self
        let displayLink = CADisplayLink(target: target, selector: #selector(DisplayCallbackTarget.tick(_:)))
        link = displayLink; displayLink.add(to: .main, forMode: .common)
    }
    func tick(_ displayLink: CADisplayLink) {
        guard let start else { self.start = displayLink.timestamp; return }
        count += 1
        let elapsed = displayLink.timestamp - start
        if elapsed >= 1 { callbacks = Double(count) / elapsed; self.start = displayLink.timestamp; count = 0 }
    }
    func stop() { link?.invalidate(); link = nil; measuring = false; start = nil; count = 0 }
    deinit { link?.invalidate() }
}
@MainActor private final class DisplayCallbackTarget: NSObject {
    weak var owner: DisplayDiagnosticsModel?
    @objc func tick(_ link: CADisplayLink) { owner?.tick(link) }
}
private struct WindowDisplayProbe: UIViewRepresentable {
    var changed: @MainActor (UIWindow, CGSize) -> Void
    func makeUIView(context: Context) -> Probe { let view = Probe(); view.changed = changed; view.isUserInteractionEnabled = false; return view }
    func updateUIView(_ view: Probe, context: Context) { view.changed = changed; view.report() }
    final class Probe: UIView {
        var changed: (@MainActor (UIWindow, CGSize) -> Void)?
        override func didMoveToWindow() { super.didMoveToWindow(); report() }
        override func layoutSubviews() { super.layoutSubviews(); report() }
        func report() {
            guard let window else { return }; let content = bounds.size
            DispatchQueue.main.async { [weak self, weak window] in if let window { self?.changed?(window, content) } }
        }
    }
}
struct DisplayDiagnosticsView: View {
    @EnvironmentObject private var localization: LocalizationStore
    @Environment(\.scenePhase) private var phase
    @StateObject private var model = DisplayDiagnosticsModel()
    private func size(_ value: CGSize) -> String { value.width.formatted(.number.precision(.fractionLength(0))) + " × " + value.height.formatted(.number.precision(.fractionLength(0))) }
    var body: some View {
        List {
            Section("Window") {
                LabeledContent("Window size", value: size(model.snapshot.window))
                LabeledContent("Content size", value: size(model.snapshot.content))
                LabeledContent("Display scale", value: model.snapshot.scale.formatted())
                LabeledContent("Safe area", value: [model.snapshot.safeArea.top, model.snapshot.safeArea.left, model.snapshot.safeArea.bottom, model.snapshot.safeArea.right].map { $0.formatted(.number.precision(.fractionLength(0))) }.joined(separator: " / "))
            }
            Section("Display") {
                LabeledContent("Pixel dimensions", value: size(model.snapshot.pixels))
                LabeledContent("Maximum frame rate", value: String(model.snapshot.maximumFPS) + " Hz")
                LabeledContent("Current EDR headroom", value: model.snapshot.currentEDR.formatted(.number.precision(.fractionLength(2))) + "×")
                LabeledContent("Potential EDR headroom", value: model.snapshot.potentialEDR.formatted(.number.precision(.fractionLength(2))) + "×")
            }
            Section("App callback rate") {
                LabeledContent("Callbacks per second", value: model.callbacks.map { $0.formatted(.number.precision(.fractionLength(1))) } ?? "—")
                Button(model.measuring ? localization.text("Stop measurement") : localization.text("Start measurement")) { if model.measuring { model.stop() } else { model.begin() } }.accessibilityIdentifier("display.measure")
            }
        }.navigationTitle(localization.text("Window & display"))
            .background { WindowDisplayProbe { window, content in model.update(window: window, content: content) } }
            .onDisappear { model.stop() }
            .onChange(of: phase) { _, value in if value != .active { model.stop() } }
    }
}
