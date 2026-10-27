import Foundation

run(KeyboardStateTests.self, KeyboardStateTests.allTests)
run(TextContextTests.self, TextContextTests.allTests)
run(ClipboardStoreTests.self, ClipboardStoreTests.allTests)

if failures > 0 {
    print("\n\(failures) assertion(s) failed")
    exit(1)
}
print("\nAll logic tests passed")
