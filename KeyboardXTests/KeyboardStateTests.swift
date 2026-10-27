#if canImport(XCTest)
import XCTest
#endif
import Foundation

final class KeyboardStateTests: XCTestCase {
    static let allTests: [(String, (KeyboardStateTests) -> () -> Void)] = [
        ("testSingleTapShiftsAndCharacterResets", testSingleTapShiftsAndCharacterResets),
        ("testDoubleTapEnablesCapsLock", testDoubleTapEnablesCapsLock),
        ("testSlowSecondTapTogglesOff", testSlowSecondTapTogglesOff),
        ("testTapInCapsLockReturnsToLowercase", testTapInCapsLockReturnsToLowercase),
        ("testCapsLockSurvivesTypingAndAutoShift", testCapsLockSurvivesTypingAndAutoShift),
        ("testAutoShift", testAutoShift),
        ("testDoubleTapFromAutoShiftedState", testDoubleTapFromAutoShiftedState),
        ("testSpaceAndApostropheReturnToLetters", testSpaceAndApostropheReturnToLetters),
    ]

    func testSingleTapShiftsAndCharacterResets() {
        var s = KeyboardState()
        s.tapShift(at: 0)
        XCTAssertEqual(s.shift, .shifted)
        s.didInsertCharacter("A")
        XCTAssertEqual(s.shift, .lowercase)
    }

    func testDoubleTapEnablesCapsLock() {
        var s = KeyboardState()
        s.tapShift(at: 0)
        s.tapShift(at: 0.2)
        XCTAssertEqual(s.shift, .capsLock)
    }

    func testSlowSecondTapTogglesOff() {
        var s = KeyboardState()
        s.tapShift(at: 0)
        s.tapShift(at: 1.0)
        XCTAssertEqual(s.shift, .lowercase)
    }

    func testTapInCapsLockReturnsToLowercase() {
        var s = KeyboardState()
        s.tapShift(at: 0)
        s.tapShift(at: 0.1)
        s.tapShift(at: 0.2)
        XCTAssertEqual(s.shift, .lowercase)
    }

    func testCapsLockSurvivesTypingAndAutoShift() {
        var s = KeyboardState()
        s.tapShift(at: 0)
        s.tapShift(at: 0.1)
        s.didInsertCharacter("A")
        s.applyAutoShift(false)
        XCTAssertEqual(s.shift, .capsLock)
        XCTAssertTrue(s.isUppercase)
    }

    func testAutoShift() {
        var s = KeyboardState()
        s.applyAutoShift(true)
        XCTAssertEqual(s.shift, .shifted)
        s.applyAutoShift(false)
        XCTAssertEqual(s.shift, .lowercase)
    }

    func testDoubleTapFromAutoShiftedState() {
        var s = KeyboardState()
        s.applyAutoShift(true)
        s.tapShift(at: 0)      // shifted -> lowercase
        XCTAssertEqual(s.shift, .lowercase)
        s.tapShift(at: 0.15)   // quick second tap -> caps lock
        XCTAssertEqual(s.shift, .capsLock)
    }

    func testSpaceAndApostropheReturnToLetters() {
        var s = KeyboardState()
        s.setPage(.numbers)
        s.didInsertCharacter("5")
        XCTAssertEqual(s.page, .numbers)
        s.didInsertSpace()
        XCTAssertEqual(s.page, .letters)

        s.setPage(.numbers)
        s.didInsertCharacter("'")
        XCTAssertEqual(s.page, .letters)

        s.setPage(.symbols)
        s.didInsertCharacter("'")
        XCTAssertEqual(s.page, .symbols)
    }
}
