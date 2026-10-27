import UIKit

/// Container app screen explaining how to enable KeyboardX and Full Access,
/// with an "Open Settings" button and a live text field to test shortcuts.
final class SetupViewController: UIViewController {
    private let textView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "KeyboardX"
        view.backgroundColor = .systemGroupedBackground

        let scroll = UIScrollView()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        scroll.addSubview(stack)

        let stepsCard = makeCard(title: "Enable KeyboardX", body: """
        1. Tap "Open Keyboard Settings" below (or open Settings › General › Keyboard › Keyboards).
        2. Tap Add New Keyboard… and choose KeyboardX.
        3. Tap KeyboardX in the list and turn on Allow Full Access (required for Paste/Copy shortcuts, the Clipboard bar, and key click sounds).
        """)

        let shortcutsCard = makeCard(title: "Power-User Shortcuts", body: """
        • Hold V (0.5 s): Paste from clipboard into the active field.
        • Hold C (0.5 s): Copy selected text or the word under the cursor.
        • Hold a vowel (A, E, I, O, U): Slide to pick an accented character.
        • Clipboard bar: Tap any snippet to insert it, or tap 📋 to expand the full grid.
        """)

        let settingsButton = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = "Open Settings"
        config.image = UIImage(systemName: "gear")
        config.imagePadding = 8
        config.cornerStyle = .medium
        settingsButton.configuration = config
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)

        let testHeader = UILabel()
        testHeader.text = "Try It Out"
        testHeader.font = .preferredFont(forTextStyle: .headline)

        textView.font = .systemFont(ofSize: 16)
        textView.layer.cornerRadius = 12
        textView.backgroundColor = .secondarySystemGroupedBackground
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        textView.text = "Switch to KeyboardX with the 🌐 key, then try holding C on a word or holding V to paste."
        textView.heightAnchor.constraint(equalToConstant: 150).isActive = true

        [stepsCard, settingsButton, shortcutsCard, testHeader, textView].forEach {
            stack.addArrangedSubview($0)
        }

        let g = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: g.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: g.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: g.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: g.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),
        ])
    }

    private func makeCard(title: String, body: String) -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 12

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .preferredFont(forTextStyle: .headline)

        let bodyLabel = UILabel()
        bodyLabel.text = body
        bodyLabel.font = .preferredFont(forTextStyle: .subheadline)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 0

        let v = UIStackView(arrangedSubviews: [titleLabel, bodyLabel])
        v.axis = .vertical
        v.spacing = 8
        v.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(v)
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            v.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            v.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            v.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
        ])
        return card
    }

    @objc private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
