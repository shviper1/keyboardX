// Minimal XCTest stand-in so the KeyboardXTests sources can run on a Mac that only has the
// Command Line Tools (no XCTest.framework). Used by scripts/verify.sh only; Xcode uses real XCTest.

import Foundation

var failures = 0
var currentTest = ""

class XCTestCase {
    required init() {}
}

private func report(_ message: String, _ file: StaticString, _ line: UInt) {
    failures += 1
    print("  ✗ \(currentTest) — \(message) (\(file):\(line))")
}

func XCTAssertEqual<T: Equatable>(_ a: @autoclosure () -> T, _ b: @autoclosure () -> T,
                                  file: StaticString = #fileID, line: UInt = #line) {
    let (x, y) = (a(), b())
    if x != y { report("\(x) != \(y)", file, line) }
}

func XCTAssertTrue(_ v: @autoclosure () -> Bool, file: StaticString = #fileID, line: UInt = #line) {
    if !v() { report("expected true", file, line) }
}

func XCTAssertFalse(_ v: @autoclosure () -> Bool, file: StaticString = #fileID, line: UInt = #line) {
    if v() { report("expected false", file, line) }
}

func XCTAssertNil<T>(_ v: @autoclosure () -> T?, file: StaticString = #fileID, line: UInt = #line) {
    if let x = v() { report("expected nil, got \(x)", file, line) }
}

func XCTFail(_ message: String = "", file: StaticString = #fileID, line: UInt = #line) {
    report("XCTFail \(message)", file, line)
}

func run<T: XCTestCase>(_ type: T.Type, _ tests: [(String, (T) -> () -> Void)]) {
    print("\(type)")
    for (name, test) in tests {
        currentTest = name
        let before = failures
        test(T())()
        if failures == before { print("  ✓ \(name)") }
    }
}
