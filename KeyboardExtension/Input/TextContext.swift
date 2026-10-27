import Foundation

/// Mirrors `UITextAutocapitalizationType` without depending on UIKit.
enum AutocapMode: Equatable {
    case none, words, sentences, allCharacters
}

/// Pure text-context helpers (Foundation only, unit-testable).
enum TextContext {
    static let doubleSpaceInterval: TimeInterval = 0.5

    private static let sentenceTerminators: Set<Character> = [".", "!", "?"]
    private static let tokenEdgePunctuation: Set<Character> = [
        ".", ",", ";", ":", "!", "?", "(", ")", "[", "]", "{", "}",
        "\"", "'", "“", "”", "‘", "’", "<", ">", "«", "»",
    ]

    // MARK: Auto-capitalization

    static func shouldAutoCapitalize(before: String?, mode: AutocapMode) -> Bool {
        switch mode {
        case .none:
            return false
        case .allCharacters:
            return true
        case .words:
            guard let last = before?.last else { return true }
            return last.isWhitespace || last.isNewline
        case .sentences:
            guard let before, let last = before.last else { return true }
            if last.isNewline { return true }
            guard last == " " || last == "\t" else { return false }
            let trimmed = before.trimmingTrailing { $0 == " " || $0 == "\t" }
            guard let previous = trimmed.last else { return true }
            return sentenceTerminators.contains(previous) || previous.isNewline
        }
    }

    // MARK: Double-space -> ". "

    /// `before` is the text before the cursor **before** inserting the second space.
    static func shouldConvertDoubleSpace(before: String?, lastSpaceTime: TimeInterval?, now: TimeInterval) -> Bool {
        guard let lastSpaceTime, now - lastSpaceTime <= doubleSpaceInterval else { return false }
        guard let before, before.last == " " else { return false }
        let withoutSpace = before.dropLast()
        guard let previous = withoutSpace.last else { return false }
        return previous.isLetter || previous.isNumber || previous == ")" || previous == "\"" || previous == "”"
    }

    // MARK: Current word (for Copy)

    /// The whitespace-delimited token touching the cursor, trimmed of surrounding punctuation,
    /// so URLs and e-mail addresses are copied whole. If the cursor follows whitespace and no
    /// token touches it, falls back to the previous token.
    static func currentWord(before: String?, after: String?) -> String? {
        let before = before ?? ""
        let after = after ?? ""

        let head = before.suffixWhile { !$0.isWhitespace }
        let tail = after.prefixWhile { !$0.isWhitespace }
        var token = String(head) + String(tail)

        if token.isEmpty {
            let trimmedBefore = before.trimmingTrailing { $0.isWhitespace }
            token = String(trimmedBefore.suffixWhile { !$0.isWhitespace })
        }

        let cleaned = token
            .trimmingLeading { tokenEdgePunctuation.contains($0) }
            .trimmingTrailing { tokenEdgePunctuation.contains($0) }
        return cleaned.isEmpty ? nil : String(cleaned)
    }
}

// MARK: - Small string helpers

extension StringProtocol {
    func suffixWhile(_ predicate: (Character) -> Bool) -> SubSequence {
        var start = endIndex
        while start > startIndex {
            let previous = index(before: start)
            guard predicate(self[previous]) else { break }
            start = previous
        }
        return self[start..<endIndex]
    }

    func prefixWhile(_ predicate: (Character) -> Bool) -> SubSequence {
        prefix(while: predicate)
    }

    func trimmingTrailing(_ predicate: (Character) -> Bool) -> SubSequence {
        var end = endIndex
        while end > startIndex {
            let previous = index(before: end)
            guard predicate(self[previous]) else { break }
            end = previous
        }
        return self[startIndex..<end]
    }

    func trimmingLeading(_ predicate: (Character) -> Bool) -> SubSequence {
        drop(while: predicate)
    }
}
