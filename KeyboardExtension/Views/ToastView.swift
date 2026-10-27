import UIKit

/// Small pill message ("Copied ‘word’", "Pasted", ...) shown over the clipboard bar.
final class ToastView: UIView {
    private let label = UILabel()
    private var hideWork: DispatchWorkItem?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        alpha = 0
        layer.cornerRadius = 14
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.lineBreakMode = .byTruncatingMiddle
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func apply(theme: KeyboardTheme) {
        backgroundColor = theme.isDark ? UIColor(white: 0.9, alpha: 0.95) : UIColor(white: 0.1, alpha: 0.85)
        label.textColor = theme.isDark ? .black : .white
    }

    func show(_ message: String, duration: TimeInterval = 1.2) {
        label.text = message
        hideWork?.cancel()
        superview?.bringSubviewToFront(self)
        UIView.animate(withDuration: 0.15) { self.alpha = 1 }

        let work = DispatchWorkItem { [weak self] in
            UIView.animate(withDuration: 0.25) { self?.alpha = 0 }
        }
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: work)
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}
