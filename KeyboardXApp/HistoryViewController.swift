import UIKit

/// Shows the App Group clipboard history inside the container app,
/// allowing the user to copy an entry back to the system pasteboard, delete entries, or clear all.
final class HistoryViewController: UITableViewController {
    private static let cellID = "HistoryCell"
    private let store = ClipboardStore.shared
    private var items: [ClipItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Clipboard History"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellID)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Clear All",
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(clearAll))
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadItems),
                                               name: .clipboardHistoryDidUpdate,
                                               object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadItems()
    }

    @objc private func reloadItems() {
        items = store.items
        navigationItem.rightBarButtonItem?.isEnabled = !items.isEmpty
        tableView.reloadData()
    }

    @objc private func clearAll() {
        store.clear()
        reloadItems()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellID, for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = items[indexPath.row].text
        content.textProperties.numberOfLines = 3
        cell.contentConfiguration = content
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        UIPasteboard.general.string = items[indexPath.row].text
        store.lastSeenChangeCount = UIPasteboard.general.changeCount
    }

    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            store.remove(id: items[indexPath.row].id)
            reloadItems()
        }
    }
}
