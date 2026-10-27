import Foundation

// Foundation-only layout model (no UIKit) so it can be unit-tested on any platform.

enum KeyboardPage: Equatable {
    case letters, numbers, symbols
}

enum ShortcutAction: Equatable {
    case paste, copy
}

enum LongPressBehavior: Equatable {
    case none
    case accents([String])
    case shortcut(ShortcutAction)
    case autoRepeat
}

enum KeyKind: Equatable {
    /// For letters this is the lowercase form. Casing is applied at render/insert time.
    case character(String)
    case shift
    case backspace
    case pageSwitch(KeyboardPage, label: String)
    case globe
    case space
    case returnKey
}

struct KeyModel: Equatable {
    let kind: KeyKind
    /// Width relative to a standard letter key. Ignored for keys in a filling center group.
    let widthUnits: Double
    let longPress: LongPressBehavior

    init(_ kind: KeyKind, width: Double = 1, longPress: LongPressBehavior = .none) {
        self.kind = kind
        self.widthUnits = width
        self.longPress = longPress
    }

    var isCharacter: Bool {
        if case .character = kind { return true }
        return false
    }
}

/// A row is split into three groups:
/// - `leading`: pinned to the left edge with fixed widths
/// - `trailing`: pinned to the right edge with fixed widths
/// - `center`: either fixed-width keys centered in the full row (`centerFills == false`)
///   or keys that share the remaining space equally (`centerFills == true`).
struct KeyRow: Equatable {
    var leading: [KeyModel] = []
    var center: [KeyModel]
    var trailing: [KeyModel] = []
    var centerFills: Bool = false

    var allKeys: [KeyModel] { leading + center + trailing }
}

enum KeyboardLayout {
    static let shiftWidth = 1.36
    static let pageKeyWidth = 1.27
    static let returnWidth = 2.6

    /// Vowel accents (C accents intentionally dropped: long-press C = Copy).
    static let accents: [String: [String]] = [
        "a": ["à", "á", "â", "ä", "æ", "ã", "å", "ā"],
        "e": ["è", "é", "ê", "ë", "ē", "ė", "ę"],
        "i": ["ì", "į", "ī", "í", "ï", "î"],
        "o": ["õ", "ō", "ø", "œ", "ó", "ò", "ö", "ô"],
        "u": ["ū", "ú", "ù", "ü", "û"],
    ]

    static func longPress(forLetter letter: String) -> LongPressBehavior {
        switch letter {
        case "v": return .shortcut(.paste)
        case "c": return .shortcut(.copy)
        default:
            if let list = accents[letter] { return .accents(list) }
            return .none
        }
    }

    static func rows(for page: KeyboardPage, showsGlobe: Bool) -> [KeyRow] {
        switch page {
        case .letters:
            func letters(_ s: String) -> [KeyModel] {
                s.map { ch in
                    let l = String(ch)
                    return KeyModel(.character(l), longPress: longPress(forLetter: l))
                }
            }
            return [
                KeyRow(center: letters("qwertyuiop")),
                KeyRow(center: letters("asdfghjkl")),
                KeyRow(leading: [KeyModel(.shift, width: shiftWidth)],
                       center: letters("zxcvbnm"),
                       trailing: [KeyModel(.backspace, width: shiftWidth, longPress: .autoRepeat)]),
                bottomRow(pageTarget: .numbers, label: "123", showsGlobe: showsGlobe),
            ]
        case .numbers:
            return [
                KeyRow(center: chars("1234567890")),
                KeyRow(center: chars("-/:;()$&@\"")),
                KeyRow(leading: [KeyModel(.pageSwitch(.symbols, label: "#+="), width: shiftWidth)],
                       center: chars(".,?!'"),
                       trailing: [KeyModel(.backspace, width: shiftWidth, longPress: .autoRepeat)],
                       centerFills: true),
                bottomRow(pageTarget: .letters, label: "ABC", showsGlobe: showsGlobe),
            ]
        case .symbols:
            return [
                KeyRow(center: chars("[]{}#%^*+=")),
                KeyRow(center: chars("_\\|~<>€£¥•")),
                KeyRow(leading: [KeyModel(.pageSwitch(.numbers, label: "123"), width: shiftWidth)],
                       center: chars(".,?!'"),
                       trailing: [KeyModel(.backspace, width: shiftWidth, longPress: .autoRepeat)],
                       centerFills: true),
                bottomRow(pageTarget: .letters, label: "ABC", showsGlobe: showsGlobe),
            ]
        }
    }

    private static func chars(_ s: String) -> [KeyModel] {
        s.map { KeyModel(.character(String($0))) }
    }

    private static func bottomRow(pageTarget: KeyboardPage, label: String, showsGlobe: Bool) -> KeyRow {
        var leading = [KeyModel(.pageSwitch(pageTarget, label: label),
                                width: showsGlobe ? pageKeyWidth : returnWidth)]
        if showsGlobe {
            leading.append(KeyModel(.globe, width: pageKeyWidth))
        }
        return KeyRow(leading: leading,
                      center: [KeyModel(.space)],
                      trailing: [KeyModel(.returnKey, width: returnWidth)],
                      centerFills: true)
    }
}
