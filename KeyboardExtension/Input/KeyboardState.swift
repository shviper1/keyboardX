import Foundation

enum ShiftState: Equatable {
    case lowercase
    case shifted     // next character only
    case capsLock
}

/// Shift / page state machine (Foundation only, unit-testable).
struct KeyboardState {
    static let doubleTapInterval: TimeInterval = 0.3

    private(set) var shift: ShiftState = .lowercase
    private(set) var page: KeyboardPage = .letters
    private var lastShiftTap: TimeInterval?

    var isUppercase: Bool { shift != .lowercase }

    /// Tap: lowercase <-> shifted. Double-tap within 0.3 s: caps lock. Tap while locked: lowercase.
    mutating func tapShift(at time: TimeInterval) {
        if shift == .capsLock {
            shift = .lowercase
            lastShiftTap = nil
            return
        }
        if let last = lastShiftTap, time - last <= Self.doubleTapInterval {
            shift = .capsLock
            lastShiftTap = nil
            return
        }
        shift = (shift == .lowercase) ? .shifted : .lowercase
        lastShiftTap = time
    }

    mutating func didInsertCharacter(_ character: String) {
        lastShiftTap = nil
        if shift == .shifted { shift = .lowercase }
        // Stock behaviour: typing an apostrophe on the numbers page returns to letters.
        if page == .numbers && character == "'" { page = .letters }
    }

    mutating func didInsertSpace() {
        lastShiftTap = nil
        if page != .letters { page = .letters }
    }

    /// Called after every text change. Never overrides caps lock.
    mutating func applyAutoShift(_ shouldCapitalize: Bool) {
        guard shift != .capsLock else { return }
        shift = shouldCapitalize ? .shifted : .lowercase
    }

    mutating func setPage(_ newPage: KeyboardPage) {
        page = newPage
        lastShiftTap = nil
    }
}
