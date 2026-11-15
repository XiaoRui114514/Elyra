// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI

/// Reports this scene's window, including live resizing. Keyboard avoidance is
/// left to SwiftUI; keyboard height is not a window-layout breakpoint.
struct SceneWindowProbe: UIViewRepresentable {
    var changed: @MainActor (UIWindow, CGSize) -> Void
    func makeUIView(context: Context) -> Probe {
        let view = Probe()
        view.changed = changed
        view.isUserInteractionEnabled = false
        return view
    }
    func updateUIView(_ view: Probe, context: Context) {
        view.changed = changed
        view.report()
    }
    final class Probe: UIView {
        var changed: (@MainActor (UIWindow, CGSize) -> Void)?
        override func didMoveToWindow() { super.didMoveToWindow(); report() }
        override func layoutSubviews() { super.layoutSubviews(); report() }
        override func safeAreaInsetsDidChange() { super.safeAreaInsetsDidChange(); report() }
        func report() {
            guard let window else { return }
            let content = bounds.size
            DispatchQueue.main.async { [weak self, weak window] in
                if let window { self?.changed?(window, content) }
            }
        }
    }
}
