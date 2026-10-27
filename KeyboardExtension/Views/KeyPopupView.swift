import UIKit

/// Builds the stock "balloon" key preview outline: a wide rounded bubble on top that
/// narrows through a curved neck into the exact shape of the pressed key.
enum BalloonPath {
    static func make(keyRect k: CGRect, topRect t: CGRect, keyRadius r: CGFloat, topRadius R: CGFloat) -> UIBezierPath {
        let neck = min(k.height * 0.35, 14)
        let p = UIBezierPath()

        p.move(to: CGPoint(x: t.minX, y: t.minY + R))
        p.addArc(withCenter: CGPoint(x: t.minX + R, y: t.minY + R), radius: R,
                 startAngle: .pi, endAngle: .pi * 1.5, clockwise: true)
        p.addLine(to: CGPoint(x: t.maxX - R, y: t.minY))
        p.addArc(withCenter: CGPoint(x: t.maxX - R, y: t.minY + R), radius: R,
                 startAngle: .pi * 1.5, endAngle: 0, clockwise: true)
        p.addLine(to: CGPoint(x: t.maxX, y: t.maxY))

        // right neck
        p.addCurve(to: CGPoint(x: k.maxX, y: k.minY + neck),
                   controlPoint1: CGPoint(x: t.maxX, y: t.maxY + neck * 0.5),
                   controlPoint2: CGPoint(x: k.maxX, y: k.minY + neck * 0.5))
        p.addLine(to: CGPoint(x: k.maxX, y: k.maxY - r))
        p.addArc(withCenter: CGPoint(x: k.maxX - r, y: k.maxY - r), radius: r,
                 startAngle: 0, endAngle: .pi / 2, clockwise: true)
        p.addLine(to: CGPoint(x: k.minX + r, y: k.maxY))
        p.addArc(withCenter: CGPoint(x: k.minX + r, y: k.maxY - r), radius: r,
                 startAngle: .pi / 2, endAngle: .pi, clockwise: true)
        p.addLine(to: CGPoint(x: k.minX, y: k.minY + neck))

        // left neck
        p.addCurve(to: CGPoint(x: t.minX, y: t.maxY),
                   controlPoint1: CGPoint(x: k.minX, y: k.minY + neck * 0.5),
                   controlPoint2: CGPoint(x: t.minX, y: t.maxY + neck * 0.5))
        p.close()
        return p
    }
}

/// Base class: a view whose frame is the union of the key and the bubble,
/// drawing the balloon in local coordinates.
class BalloonView: UIView {
    let shapeLayer = CAShapeLayer()
    /// Bubble rect in this view's coordinates.
    private(set) var bubbleRect: CGRect = .zero

    init(keyFrame: CGRect, bubbleFrame: CGRect, cornerRadius: CGFloat, theme: KeyboardTheme) {
        let union = keyFrame.union(bubbleFrame)
        super.init(frame: union)
        isUserInteractionEnabled = false
        let localKey = keyFrame.offsetBy(dx: -union.minX, dy: -union.minY)
        bubbleRect = bubbleFrame.offsetBy(dx: -union.minX, dy: -union.minY)

        shapeLayer.path = BalloonPath.make(keyRect: localKey, topRect: bubbleRect,
                                           keyRadius: cornerRadius, topRadius: cornerRadius * 2).cgPath
        shapeLayer.fillColor = theme.letterKey.cgColor
        shapeLayer.shadowColor = UIColor.black.cgColor
        shapeLayer.shadowOpacity = theme.isDark ? 0.5 : 0.28
        shapeLayer.shadowRadius = 2
        shapeLayer.shadowOffset = CGSize(width: 0, height: 1)
        shapeLayer.strokeColor = UIColor.black.withAlphaComponent(theme.isDark ? 0 : 0.12).cgColor
        shapeLayer.lineWidth = 0.5
        layer.addSublayer(shapeLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// The magnified character preview shown while a character key is held.
final class KeyPopupView: BalloonView {
    init(keyFrame: CGRect, title: String, metrics: KeyboardMetrics, theme: KeyboardTheme, containerWidth: CGFloat) {
        let extra = min(keyFrame.width * 0.45, 14)
        let width = keyFrame.width + extra * 2
        let height = metrics.keyHeight * 1.15
        var x = keyFrame.midX - width / 2
        x = min(max(x, 0), containerWidth - width)
        let bubble = CGRect(x: x, y: keyFrame.minY - height, width: width, height: height)
        super.init(keyFrame: keyFrame, bubbleFrame: bubble, cornerRadius: metrics.cornerRadius, theme: theme)

        let label = UILabel(frame: bubbleRect.offsetBy(dx: 0, dy: 2))
        label.text = title
        label.textAlignment = .center
        label.textColor = theme.keyText
        label.font = .systemFont(ofSize: metrics.isLandscape ? 30 : 38, weight: .light)
        label.adjustsFontSizeToFitWidth = true
        addSubview(label)
    }
}

/// Horizontal strip of alternate characters (vowel accents) with finger-tracking selection.
final class AccentPopupView: BalloonView {
    let options: [String]
    private(set) var selectedIndex: Int? {
        didSet { if oldValue != selectedIndex { updateSelection() } }
    }
    private var cellLabels: [UILabel] = []
    private let highlight = UIView()
    private let cellWidth: CGFloat
    private let theme: KeyboardTheme

    init(keyFrame: CGRect, options: [String], metrics: KeyboardMetrics, theme: KeyboardTheme, containerWidth: CGFloat) {
        self.options = options
        self.theme = theme
        let cellWidth = keyFrame.width + 4
        self.cellWidth = cellWidth
        let padding: CGFloat = 4
        let width = cellWidth * CGFloat(options.count) + padding * 2
        let height = metrics.keyHeight * 1.15

        // Open toward the right like the stock keyboard; flip left near the right edge.
        var x = keyFrame.minX - padding
        if x + width > containerWidth { x = keyFrame.maxX + padding - width }
        x = min(max(x, 0), max(containerWidth - width, 0))
        let bubble = CGRect(x: x, y: keyFrame.minY - height, width: width, height: height)
        super.init(keyFrame: keyFrame, bubbleFrame: bubble, cornerRadius: metrics.cornerRadius, theme: theme)

        highlight.backgroundColor = theme.accentHighlight
        highlight.layer.cornerRadius = metrics.cornerRadius
        highlight.isHidden = true
        addSubview(highlight)

        for (i, option) in options.enumerated() {
            let label = UILabel(frame: CGRect(x: bubbleRect.minX + padding + CGFloat(i) * cellWidth,
                                              y: bubbleRect.minY + 4,
                                              width: cellWidth,
                                              height: bubbleRect.height - 8))
            label.text = option
            label.textAlignment = .center
            label.font = .systemFont(ofSize: metrics.isLandscape ? 22 : 26, weight: .regular)
            label.textColor = theme.keyText
            addSubview(label)
            cellLabels.append(label)
        }
    }

    /// `x` is in this view's superview coordinate space.
    func updateSelection(forX x: CGFloat) {
        let localX = x - frame.minX
        guard let first = cellLabels.first, let last = cellLabels.last else { return }
        if localX < first.frame.minX - cellWidth || localX > last.frame.maxX + cellWidth {
            selectedIndex = nil     // dragged far away: cancel
            return
        }
        let raw = Int(((localX - first.frame.minX) / cellWidth).rounded(.down))
        selectedIndex = min(max(raw, 0), options.count - 1)
    }

    var selectedOption: String? {
        selectedIndex.map { options[$0] }
    }

    private func updateSelection() {
        for (i, label) in cellLabels.enumerated() {
            label.textColor = (i == selectedIndex) ? .white : theme.keyText
        }
        if let i = selectedIndex {
            highlight.frame = cellLabels[i].frame
            highlight.isHidden = false
        } else {
            highlight.isHidden = true
        }
    }
}
