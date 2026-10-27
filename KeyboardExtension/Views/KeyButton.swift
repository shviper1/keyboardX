import UIKit

/// Visual representation of a single key.
///
/// Subclasses `UIControl` only so the globe key can receive `handleInputModeList(from:with:)`
/// touch events directly. Every other key has user interaction disabled; their touches are
/// handled centrally by `KeyboardView`.
final class KeyButton: UIControl {
    enum Style {
        case letter       // white / gray character keys, space
        case function     // shift, backspace, 123, globe, return
        case primary      // blue return key (Go, Search, Send, ...)
    }

    let model: KeyModel
    var style: Style { didSet { applyColors() } }
    var theme: KeyboardTheme = .light { didSet { applyColors() } }
    var isPressed = false { didSet { if oldValue != isPressed { applyColors() } } }
    /// Shift "active" look (white background) when shifted / caps locked.
    var isActive = false { didSet { if oldValue != isActive { applyColors() } } }

    private let label = UILabel()
    private let imageView = UIImageView()

    init(model: KeyModel, style: Style) {
        self.model = model
        self.style = style
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        isAccessibilityElement = true
        accessibilityTraits = .keyboardKey

        layer.masksToBounds = false
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 0

        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        label.baselineAdjustment = .alignCenters
        imageView.contentMode = .center
        addSubview(label)
        addSubview(imageView)
        applyColors()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setTitle(_ title: String?, font: UIFont) {
        label.text = title
        label.font = font
        label.isHidden = title == nil
        imageView.isHidden = true
        accessibilityLabel = title
    }

    func setSymbol(_ name: String, configuration: UIImage.SymbolConfiguration, accessibilityLabel: String) {
        imageView.image = UIImage(systemName: name, withConfiguration: configuration)
        imageView.isHidden = false
        label.isHidden = true
        self.accessibilityLabel = accessibilityLabel
    }

    func setCornerRadius(_ radius: CGFloat) {
        layer.cornerRadius = radius
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Nudge text up by ~1pt like the stock keyboard's optical centering.
        label.frame = bounds.insetBy(dx: 2, dy: 0).offsetBy(dx: 0, dy: -1)
        imageView.frame = bounds
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
    }

    private func applyColors() {
        let background: UIColor
        var foreground = theme.keyText
        switch style {
        case .letter:
            background = isPressed ? theme.pressedLetterKey : theme.letterKey
        case .function:
            if isActive {
                background = theme.letterKey
            } else {
                background = isPressed ? theme.pressedFunctionKey : theme.functionKey
            }
            if isActive && !theme.isDark { foreground = .black }
        case .primary:
            background = isPressed ? theme.functionKey : theme.accentHighlight
            foreground = .white
        }
        backgroundColor = background
        label.textColor = foreground
        imageView.tintColor = foreground
        layer.shadowColor = theme.keyShadow.cgColor
        layer.shadowOpacity = theme.shadowOpacity
    }
}
