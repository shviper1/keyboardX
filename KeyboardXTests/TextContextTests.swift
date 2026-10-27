#if canImport(XCTest)
import XCTest
#endif
import Foundation

final class TextContextTests: XCTestCase {
    static let allTests: [(String, (TextContextTests) -> () -> Void)] = [
        ("testSentenceAutocap", testSentenceAutocap),
        ("testWordsAndOtherAutocapModes", testWordsAndOtherAutocapModes),
        ("testDoubleSpace", testDoubleSpace),
        ("testCurrentWord", testCurrentWord),
    ]

    func testSentenceAutocap() {
        let m = AutocapMode.sentences
        XCTAssertTrue(TextContext.shouldAutoCapitalize(before: nil, mode: m))
        XCTAssertTrue(TextContext.shouldAutoCapitalize(before: "", mode: m))
        XCTAssertTrue(TextContext.shouldAutoCapitalize(before: "Hello. ", mode: m))
        XCTAssertTrue(TextContext.shouldAutoCapitalize(before: "Really?  ", mode: m))
        XCTAssertTrue(TextContext.shouldAutoCapitalize(before: "Wow! ", mode: m))
        XCTAssertTrue(TextContext.shouldAutoCapitalize(before: "line\n", mode: m))
        XCTAssertTrue(TextContext.shouldAutoCapitalize(before: "   ", mode: m))
        XCTAssertFalse(TextContext.shouldAutoCapitalize(before: "Hello.", mode: m))
        XCTAssertFalse(TextContext.shouldAutoCapitalize(before: "Hello ", mode: m))
        XCTAssertFalse(TextContext.shouldAutoCapitalize(before: "Hel", mode: m))
    }

    func testWordsAndOtherAutocapModes() {
        XCTAssertTrue(TextContext.shouldAutoCapitalize(before: "John ", mode: .words))
        XCTAssertFalse(TextContext.shouldAutoCapitalize(before: "Jo", mode: .words))
        XCTAssertTrue(TextContext.shouldAutoCapitalize(before: "", mode: .words))
        XCTAssertFalse(TextContext.shouldAutoCapitalize(before: "", mode: .none))
        XCTAssertTrue(TextContext.shouldAutoCapitalize(before: "abc", mode: .allCharacters))
    }

    func testDoubleSpace() {
        XCTAssertTrue(TextContext.shouldConvertDoubleSpace(before: "Hello ", lastSpaceTime: 10, now: 10.3))
        XCTAssertTrue(TextContext.shouldConvertDoubleSpace(before: "Route 66 ", lastSpaceTime: 10, now: 10.3))
        XCTAssertFalse(TextContext.shouldConvertDoubleSpace(before: "Hello ", lastSpaceTime: 10, now: 11))
        XCTAssertFalse(TextContext.shouldConvertDoubleSpace(before: "Hello ", lastSpaceTime: nil, now: 10))
        XCTAssertFalse(TextContext.shouldConvertDoubleSpace(before: "Hello.  ", lastSpaceTime: 10, now: 10.1))
        XCTAssertFalse(TextContext.shouldConvertDoubleSpace(before: "Hello. ", lastSpaceTime: 10, now: 10.1))
        XCTAssertFalse(TextContext.shouldConvertDoubleSpace(before: " ", lastSpaceTime: 10, now: 10.1))
        XCTAssertFalse(TextContext.shouldConvertDoubleSpace(before: "Hello", lastSpaceTime: 10, now: 10.1))
    }

    func testCurrentWord() {
        XCTAssertEqual(TextContext.currentWord(before: "say hel", after: "lo world"), "hello")
        XCTAssertEqual(TextContext.currentWord(before: "say hello", after: nil), "hello")
        XCTAssertEqual(TextContext.currentWord(before: "say hello, ", after: ""), "hello")
        XCTAssertEqual(TextContext.currentWord(before: "(see", after: ")"), "see")
        XCTAssertEqual(TextContext.currentWord(before: "mail me@exa", after: "mple.com."), "me@example.com")
        XCTAssertEqual(TextContext.currentWord(before: "go https://apple.com/iph", after: "one now"),
                       "https://apple.com/iphone")
        XCTAssertEqual(TextContext.currentWord(before: "I ❤️", after: " it"), "❤️")
        XCTAssertEqual(TextContext.currentWord(before: "café", after: nil), "café")
        XCTAssertNil(TextContext.currentWord(before: nil, after: nil))
        XCTAssertNil(TextContext.currentWord(before: "   ", after: "  "))
        XCTAssertNil(TextContext.currentWord(before: "...", after: nil))
    }
}
