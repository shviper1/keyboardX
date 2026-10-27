import UIKit

/// Key click and haptic feedback.
final class FeedbackManager {
    /// Haptics in keyboard extensions require Full Access.
    var hasFullAccess = false

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)

    /// Standard system key click. Audible only when the input view adopts
    /// `UIInputViewAudioFeedback`, Full Access is on, and Keyboard Clicks are enabled in Settings.
    func keyClick() {
        UIDevice.current.playInputClick()
    }

    func prepare() {
        guard hasFullAccess else { return }
        lightImpact.prepare()
        mediumImpact.prepare()
    }

    func lightTap() {
        guard hasFullAccess else { return }
        lightImpact.impactOccurred()
    }

    func shortcutFired() {
        guard hasFullAccess else { return }
        mediumImpact.impactOccurred()
    }
}
