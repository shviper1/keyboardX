import UIKit

/// Root input view. Conforming to `UIInputViewAudioFeedback` is what allows
/// `UIDevice.current.playInputClick()` to produce the standard key click
/// (the user must also have Full Access enabled and Keyboard Clicks turned on).
final class KeyboardInputView: UIInputView, UIInputViewAudioFeedback {
    var enableInputClicksWhenVisible: Bool { true }
}
