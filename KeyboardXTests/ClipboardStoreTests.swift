#if canImport(XCTest)
import XCTest
#endif
import Foundation

final class ClipboardStoreTests: XCTestCase {
    static let allTests: [(String, (ClipboardStoreTests) -> () -> Void)] = [
        ("testAddAndOrder", testAddAndOrder),
        ("testIgnoresEmptyAndTrims", testIgnoresEmptyAndTrims),
        ("testDeduplicatesAndMovesToFront", testDeduplicatesAndMovesToFront),
        ("testCapsAtMaxItems", testCapsAtMaxItems),
        ("testTruncatesLongText", testTruncatesLongText),
        ("testRemoveClearAndPersistence", testRemoveClearAndPersistence),
        ("testPreview", testPreview),
        ("testLayoutShortcuts", testLayoutShortcuts),
    ]

    private func makeStore() -> (ClipboardStore, UserDefaults) {
        let suite = "kbx.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return (ClipboardStore(defaults: defaults), defaults)
    }

    func testAddAndOrder() {
        let (store, _) = makeStore()
        XCTAssertTrue(store.add("one"))
        XCTAssertTrue(store.add("two"))
        XCTAssertEqual(store.items.map(\.text), ["two", "one"])
    }

    func testIgnoresEmptyAndTrims() {
        let (store, _) = makeStore()
        XCTAssertFalse(store.add("   \n "))
        XCTAssertTrue(store.add("  hi \n"))
        XCTAssertEqual(store.items.map(\.text), ["hi"])
    }

    func testDeduplicatesAndMovesToFront() {
        let (store, _) = makeStore()
        store.add("a"); store.add("b"); store.add("c")
        XCTAssertFalse(store.add("c"))               // already newest
        XCTAssertTrue(store.add("a"))
        XCTAssertEqual(store.items.map(\.text), ["a", "c", "b"])
    }

    func testCapsAtMaxItems() {
        let (store, _) = makeStore()
        for i in 0..<(ClipboardStore.maxItems + 5) { store.add("item \(i)") }
        XCTAssertEqual(store.items.count, ClipboardStore.maxItems)
        XCTAssertEqual(store.items.first?.text, "item \(ClipboardStore.maxItems + 4)")
    }

    func testTruncatesLongText() {
        let (store, _) = makeStore()
        store.add(String(repeating: "x", count: ClipboardStore.maxLength + 50))
        XCTAssertEqual(store.items.first?.text.count, ClipboardStore.maxLength)
    }

    func testRemoveClearAndPersistence() {
        let (store, defaults) = makeStore()
        store.add("keep"); store.add("drop")
        let dropID = store.items[0].id
        store.remove(id: dropID)
        store.lastSeenChangeCount = 42

        let reopened = ClipboardStore(defaults: defaults)
        XCTAssertEqual(reopened.items.map(\.text), ["keep"])
        XCTAssertEqual(reopened.lastSeenChangeCount, 42)

        reopened.clear()
        XCTAssertTrue(store.items.isEmpty)
    }

    func testPreview() {
        XCTAssertEqual(ClipItem(text: "first line\nsecond").preview(), "first line")
        XCTAssertEqual(ClipItem(text: "abcdef").preview(maxLength: 3), "abc…")
        XCTAssertEqual(ClipItem(text: "\n\nhello").preview(), "hello")
    }

    func testLayoutShortcuts() {
        XCTAssertEqual(KeyboardLayout.longPress(forLetter: "v"), .shortcut(.paste))
        XCTAssertEqual(KeyboardLayout.longPress(forLetter: "c"), .shortcut(.copy))
        XCTAssertEqual(KeyboardLayout.longPress(forLetter: "z"), LongPressBehavior.none)
        if case .accents(let list) = KeyboardLayout.longPress(forLetter: "e") {
            XCTAssertTrue(list.contains("é"))
        } else {
            XCTFail("e should have accents")
        }
        let rows = KeyboardLayout.rows(for: .letters, showsGlobe: true)
        XCTAssertEqual(rows.count, 4)
        XCTAssertEqual(rows[0].center.count, 10)
        XCTAssertEqual(rows[1].center.count, 9)
        XCTAssertEqual(rows[2].center.count, 7)
        XCTAssertTrue(rows[3].leading.contains { $0.kind == .globe })
        XCTAssertFalse(KeyboardLayout.rows(for: .letters, showsGlobe: false)[3].leading.contains { $0.kind == .globe })
        for page in [KeyboardPage.numbers, .symbols] {
            let r = KeyboardLayout.rows(for: page, showsGlobe: false)
            XCTAssertEqual(r[0].center.count, 10)
            XCTAssertEqual(r[1].center.count, 10)
            XCTAssertEqual(r[2].center.count, 5)
        }
    }
}
