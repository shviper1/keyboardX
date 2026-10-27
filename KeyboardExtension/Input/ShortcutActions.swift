import UIKit

enum ShortcutResult: Equatable {
    case pasted
    case copied(String)
    case empty
    case needsFullAccess
}

/// Implements the long-press V (paste) and long-press C (copy) shortcuts.
struct ShortcutActions {
    let proxy: UITextDocumentProxy
    let store: ClipboardStore
    let hasFullAccess: Bool

    /// Inserts `UIPasteboard.general.string` at the cursor.
    func paste() -> ShortcutResult {
        guard hasFullAccess else { return .needsFullAccess }
        let pasteboard = UIPasteboard.general
        guard pasteboard.hasStrings, let text = pasteboard.string, !text.isEmpty else { return .empty }
        proxy.insertText(text)
        return .pasted
    }

    /// Copies the selection if there is one, otherwise the word at the cursor.
    /// A keyboard cannot create a selection in the host app, so nothing is visibly selected.
    func copy() -> ShortcutResult {
        guard hasFullAccess else { return .needsFullAccess }
        let selection = proxy.selectedText.flatMap { $0.isEmpty ? nil : $0 }
        let text = selection ?? TextContext.currentWord(before: proxy.documentContextBeforeInput,
                                                        after: proxy.documentContextAfterInput)
        guard let text, !text.isEmpty else { return .empty }
        UIPasteboard.general.string = text
        store.add(text)
        return .copied(text)
    }
}
