import UIKit

/// Expanded clipboard panel that covers the keys: a 2-column grid of every saved clip.
/// Tap to paste; the × button removes an item; "Clear" removes everything.
final class ClipboardPanelView: UIView {
    var onSelect: ((ClipItem) -> Void)?
    var onDelete: ((ClipItem) -> Void)?
    var onClear: (() -> Void)?

    private var items: [ClipItem] = []
    private var theme: KeyboardTheme = .light

    private let titleLabel = UILabel()
    private let clearButton = UIButton(type: .system)
    private let emptyLabel = UILabel()
    private let collectionView: UICollectionView

    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 6
        layout.minimumLineSpacing = 6
        layout.sectionInset = UIEdgeInsets(top: 0, left: 6, bottom: 6, right: 6)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: frame)

        titleLabel.text = "Clipboard"
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        clearButton.setTitle("Clear", for: .normal)
        clearButton.titleLabel?.font = .systemFont(ofSize: 15)
        clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
        emptyLabel.text = "Nothing copied yet"
        emptyLabel.font = .systemFont(ofSize: 15)
        emptyLabel.textAlignment = .center

        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ClipPanelCell.self, forCellWithReuseIdentifier: ClipPanelCell.reuseID)

        [titleLabel, clearButton, collectionView, emptyLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            titleLabel.heightAnchor.constraint(equalToConstant: 28),
            clearButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            clearButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),

            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(items: [ClipItem]) {
        self.items = items
        emptyLabel.isHidden = !items.isEmpty
        clearButton.isEnabled = !items.isEmpty
        collectionView.reloadData()
    }

    func apply(theme: KeyboardTheme) {
        self.theme = theme
        backgroundColor = KeyboardTheme.usesSystemBackdrop
            ? (theme.isDark ? UIColor(hex: 0x2B2B2D) : UIColor(hex: 0xD1D3D9))
            : theme.background
        titleLabel.textColor = theme.keyText
        clearButton.tintColor = theme.accentHighlight
        emptyLabel.textColor = theme.secondaryText
        collectionView.reloadData()
    }

    @objc private func clearTapped() {
        onClear?()
    }
}

extension ClipboardPanelView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ClipPanelCell.reuseID, for: indexPath) as! ClipPanelCell
        let item = items[indexPath.item]
        cell.configure(text: item.text, theme: theme)
        cell.onDelete = { [weak self] in self?.onDelete?(item) }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 6 * 3) / 2
        return CGSize(width: max(width, 50), height: 64)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onSelect?(items[indexPath.item])
    }
}

final class ClipPanelCell: UICollectionViewCell {
    static let reuseID = "ClipPanelCell"

    var onDelete: (() -> Void)?
    private let label = UILabel()
    private let deleteButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 8
        contentView.layer.shadowOffset = CGSize(width: 0, height: 1)
        contentView.layer.shadowRadius = 0

        label.font = .systemFont(ofSize: 13)
        label.numberOfLines = 3
        label.lineBreakMode = .byTruncatingTail
        deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        deleteButton.accessibilityLabel = "Delete"
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)

        [label, deleteButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            label.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: -2),
            label.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -6),
            deleteButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: 30),
            deleteButton.heightAnchor.constraint(equalToConstant: 30),
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
        deleteButton.tintColor = theme.secondaryText
        contentView.backgroundColor = theme.chipBackground
        contentView.layer.shadowColor = theme.keyShadow.cgColor
        contentView.layer.shadowOpacity = theme.shadowOpacity
    }

    @objc private func deleteTapped() {
        onDelete?()
    }
}
