import UIKit

/// Light / dark palettes approximating the classic stock keyboard.
struct KeyboardTheme: Equatable {
    /// The system draws the native keyboard backdrop behind custom keyboards, so by default
    /// the keyboard background is transparent. Set to `false` to paint `background` instead.
    static let usesSystemBackdrop = true

    let isDark: Bool
    let background: UIColor
    let letterKey: UIColor
    let functionKey: UIColor
    let pressedFunctionKey: UIColor
    let pressedLetterKey: UIColor
    let keyText: UIColor
    let keyShadow: UIColor
    let shadowOpacity: Float
    let chipBackground: UIColor
    let secondaryText: UIColor
    let accentHighlight: UIColor

    static let light = KeyboardTheme(
        isDark: false,
        background: UIColor(hex: 0xD1D3D9),
        letterKey: .white,
        functionKey: UIColor(hex: 0xABB0BA),
        pressedFunctionKey: .white,
        pressedLetterKey: UIColor(hex: 0xABB0BA),
        keyText: .black,
        keyShadow: UIColor(hex: 0x898A8D),
        shadowOpacity: 1,
        chipBackground: .white,
        secondaryText: UIColor(hex: 0x6D6D72),
        accentHighlight: .systemBlue)

    static let dark = KeyboardTheme(
        isDark: true,
        background: UIColor(hex: 0x2B2B2D),
        letterKey: UIColor(hex: 0x6B6B6D),
        functionKey: UIColor(hex: 0x474749),
        pressedFunctionKey: UIColor(hex: 0xABABAD),
        pressedLetterKey: UIColor(hex: 0x474749),
        keyText: .white,
        keyShadow: .black,
        shadowOpacity: 0.35,
        chipBackground: UIColor(hex: 0x6B6B6D),
        secondaryText: UIColor(hex: 0xA1A1A6),
        accentHighlight: .systemBlue)

    /// A host field asking for a dark keyboard wins; otherwise follow the system appearance.
    static func resolve(appearance: UIKeyboardAppearance?, traits: UITraitCollection) -> KeyboardTheme {
        switch appearance ?? .default {
        case .dark:
            return .dark
        case .light:
            return .light
        default:
            return traits.userInterfaceStyle == .dark ? .dark : .light
        }
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: alpha)
    }
}
