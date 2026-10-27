import Foundation

/// A single clipboard history entry.
struct ClipItem: Codable, Hashable, Identifiable {
    let id: UUID
    let text: String
    let date: Date

    init(id: UUID = UUID(), text: String, date: Date = Date()) {
        self.id = id
        self.text = text
        self.date = date
    }

    /// Single-line snippet suitable for a chip in the clipboard bar.
    func preview(maxLength: Int = 40) -> String {
        let firstLine = text
            .split(whereSeparator: \.isNewline)
            .first
            .map(String.init)?
            .trimmingCharacters(in: .whitespaces) ?? ""
        let base = firstLine.isEmpty ? text.trimmingCharacters(in: .whitespacesAndNewlines) : firstLine
        guard base.count > maxLength else { return base }
        return String(base.prefix(maxLength)) + "…"
    }
}

/// Persists clipboard history in (App Group) `UserDefaults` so that the keyboard
/// extension and the container app see the same list.
///
/// Always reads fresh from defaults because two processes write to it.
final class ClipboardStore {
    static let maxItems = 15
    static let maxLength = 10_000

    static let shared = ClipboardStore(defaults: AppGroup.defaults)

    private let defaults: UserDefaults
    private let itemsKey = "kbx.clipboard.items"
    private let changeCountKey = "kbx.clipboard.lastChangeCount"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    /// Most recent first.
    var items: [ClipItem] {
        guard let data = defaults.data(forKey: itemsKey),
              let decoded = try? decoder.decode([ClipItem].self, from: data) else { return [] }
        return decoded
    }

    /// Last `UIPasteboard.changeCount` processed by the keyboard's pasteboard monitor.
    var lastSeenChangeCount: Int {
        get { defaults.integer(forKey: changeCountKey) }
        set { defaults.set(newValue, forKey: changeCountKey) }
    }

    /// Adds text to the front of the history.
    /// - Returns: `true` if the history changed.
    @discardableResult
    func add(_ raw: String, date: Date = Date()) -> Bool {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return false }
        if text.count > Self.maxLength {
            text = String(text.prefix(Self.maxLength))
        }

        var current = items
        if current.first?.text == text { return false }   // already newest
        current.removeAll { $0.text == text }              // de-duplicate, move to front
        current.insert(ClipItem(text: text, date: date), at: 0)
        if current.count > Self.maxItems {
            current = Array(current.prefix(Self.maxItems))
        }
        save(current)
        return true
    }

    func remove(id: UUID) {
        var current = items
        current.removeAll { $0.id == id }
        save(current)
    }

    func clear() {
        save([])
    }

    private func save(_ items: [ClipItem]) {
        guard let data = try? encoder.encode(items) else { return }
        defaults.set(data, forKey: itemsKey)
    }
}
