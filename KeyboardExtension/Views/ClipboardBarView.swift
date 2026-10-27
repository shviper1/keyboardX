import UIKit

/// Gboard-style strip above the keys: a clipboard button (expands the full panel)
/// followed by a horizontally scrolling list of recent clips.
final class ClipboardBarView: UIView {
    var onSelect: ((ClipItem) -> Void)?
    var onDelete: ((ClipItem) -> Void)?
    var onToggleExpanded: (() -> Void)?

    private(set) var items: [ClipItem] = []
    private var theme: KeyboardTheme = .light

    private let toggleButton = UIButton(type: .system)
    private let messageLabel = UILabel()
    private let collectionView: UICollectionView

    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 6
        layout.sectionInset = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 8)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: frame)

        toggleButton.setImage(UIImage(systemName: "doc.on.clipboard",
                                      withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)),
                              for: .normal)
        toggleButton.accessibilityLabel = "Clipboard"
        toggleButton.addTarget(self, action: #selector(toggleTapped), for: .touchUpInside)

        messageLabel.font = .systemFont(ofSize: 13)
        messageLabel.numberOfLines = 2
        messageLabel.adjustsFontSizeToFitWidth = true
        messageLabel.minimumScaleFactor = 0.8

        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ClipChipCell.self, forCellWithReuseIdentifier: ClipChipCell.reuseID)

        [toggleButton, collectionView, messageLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        NSLayoutConstraint.activate([
            toggleButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            toggleButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            toggleButton.widthAnchor.constraint(equalToConstant: 40),
            toggleButton.heightAnchor.constraint(equalTo: heightAnchor),

            collectionView.leadingAnchor.constraint(equalTo: toggleButton.trailingAnchor, constant: 2),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),

            messageLabel.leadingAnchor.constraint(equalTo: toggleButton.trailingAnchor, constant: 6),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            messageLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(items: [ClipItem], hasFullAccess: Bool) {
        self.items = hasFullAccess ? items : []
        collectionView.reloadData()
        if !hasFullAccess {
            messageLabel.text = "Turn on Full Access in Settings › General › Keyboard › Keyboards › KeyboardX to use the clipboard."
        } else if items.isEmpty {
            messageLabel.text = "Copied text will appear here"
        } else {
            messageLabel.text = nil
        }
        messageLabel.isHidden = messageLabel.text == nil
        collectionView.isHidden = !messageLabel.isHidden
        toggleButton.isEnabled = hasFullAccess
    }

    func setExpanded(_ expanded: Bool) {
        let name = expanded ? "keyboard" : "doc.on.clipboard"
        toggleButton.setImage(UIImage(systemName: name,
                                      withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)),
                              for: .normal)
        toggleButton.accessibilityLabel = expanded ? "Show keyboard" : "Clipboard"
        collectionView.alpha = expanded ? 0 : 1
        collectionView.isUserInteractionEnabled = !expanded
    }

    func apply(theme: KeyboardTheme) {
        self.theme = theme
        toggleButton.tintColor = theme.keyText
        messageLabel.textColor = theme.secondaryText
        collectionView.reloadData()
    }

    @objc private func toggleTapped() {
        onToggleExpanded?()
    }
}

extension ClipboardBarView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ClipChipCell.reuseID, for: indexPath) as! ClipChipCell
        cell.configure(text: items[indexPath.item].preview(maxLength: 30), theme: theme)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let text = items[indexPath.item].preview(maxLength: 30) as NSString
        let width = text.size(withAttributes: [.font: ClipChipCell.font]).width + 24
        return CGSize(width: min(max(width, 56), 200), height: collectionView.bounds.height)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onSelect?(items[indexPath.item])
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        let item = items[indexPath.item]
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            UIMenu(children: [
                UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                    self?.onDelete?(item)
                },
            ])
        }
    }
}

final class ClipChipCell: UICollectionViewCell {
    static let reuseID = "ClipChipCell"
    static let font = UIFont.systemFont(ofSize: 14)

    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 8
        contentView.layer.shadowOffset = CGSize(width: 0, height: 1)
        contentView.layer.shadowRadius = 0
        label.font = Self.font
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var isHighlighted: Bool {
        didSet { contentView.alpha = isHighlighted ? 0.6 : 1 }
    }

    func configure(text: String, theme: KeyboardTheme) {
        label.text = text
        label.textColor = theme.keyText
        contentView.backgroundColor = theme.chipBackground
        contentView.layer.shadowColor = theme.keyShadow.cgColor
        contentView.layer.shadowOpacity = theme.shadowOpacity
        accessibilityLabel = "Paste \(text)"
    }
}
