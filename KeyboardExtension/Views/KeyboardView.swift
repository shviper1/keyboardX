import UIKit

enum KeyEvent: Equatable {
    case character(String)
    case backspace
    case space
    case returnKey
    case shift
    case switchPage(KeyboardPage)
    case shortcut(ShortcutAction)
}

/// Lays out and renders the keys, and owns all touch handling.
///
/// Touches are mapped to the *nearest* key (no dead zones between keys, like the stock
/// keyboard). Each touch runs its own long-press timer instead of using
/// `UILongPressGestureRecognizer`, so behaviours never conflict: a key declares exactly one
/// `LongPressBehavior` (accents, a paste/copy shortcut, or auto-repeat).
final class KeyboardView: UIView {
    static let longPressDelay: TimeInterval = 0.5
    static let repeatInterval: TimeInterval = 0.1

    var onEvent: ((KeyEvent) -> Void)?
    /// Fired on every key touch-down (used for the input click).
    var onKeyDown: ((KeyModel) -> Void)?
    /// Lets the controller attach `handleInputModeList(from:with:)` to the globe key.
    var onGlobeKeyCreated: ((UIControl) -> Void)?

    private(set) var page: KeyboardPage = .letters
    private(set) var shiftState: ShiftState = .lowercase
    private(set) var showsGlobe = true
    private(set) var metrics: KeyboardMetrics = .portrait
    private(set) var theme: KeyboardTheme = .light
    private var returnTitle = "return"
    private var returnIsPrimary = false

    private var rows: [KeyRow] = []
    private var keyViews: [[KeyButton]] = []
    private var allKeyViews: [KeyButton] { keyViews.flatMap { $0 } }

    // MARK: Touch tracking

    private final class ActiveTouch {
        var key: KeyButton
        var popup: KeyPopupView?
        var accentPopup: AccentPopupView?
        var longPressWork: DispatchWorkItem?
        var repeatTimer: Timer?
        /// A long-press shortcut fired: lifting the finger must not insert the character.
        var consumed = false

        init(key: KeyButton) { self.key = key }

        func invalidate() {
            longPressWork?.cancel()
            longPressWork = nil
            repeatTimer?.invalidate()
            repeatTimer = nil
            popup?.removeFromSuperview()
            popup = nil
            accentPopup?.removeFromSuperview()
            accentPopup = nil
            key.isPressed = false
        }
    }

    private var activeTouches: [UITouch: ActiveTouch] = [:]

    // MARK: Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
        clipsToBounds = false          // popups extend over the clipboard bar
        backgroundColor = .clear
        reloadKeys()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Configuration

    func configure(page: KeyboardPage, shift: ShiftState) {
        let pageChanged = page != self.page
        self.page = page
        self.shiftState = shift
        if pageChanged { reloadKeys() } else { refreshKeyAppearance() }
    }

    func setShowsGlobe(_ shows: Bool) {
        guard shows != showsGlobe else { return }
        showsGlobe = shows
        reloadKeys()
    }

    func setMetrics(_ metrics: KeyboardMetrics) {
        guard metrics != self.metrics else { return }
        self.metrics = metrics
        cancelAllTouches()
        refreshKeyAppearance()
        setNeedsLayout()
    }

    func setTheme(_ theme: KeyboardTheme) {
        guard theme != self.theme else { return }
        self.theme = theme
        allKeyViews.forEach { $0.theme = theme }
    }

    func setReturnKey(title: String, isPrimary: Bool) {
        guard title != returnTitle || isPrimary != returnIsPrimary else { return }
        returnTitle = title
        returnIsPrimary = isPrimary
        refreshKeyAppearance()
    }

    // MARK: Building keys

    private func reloadKeys() {
        cancelAllTouches()
        allKeyViews.forEach { $0.removeFromSuperview() }
        rows = KeyboardLayout.rows(for: page, showsGlobe: showsGlobe)
        keyViews = rows.map { row in
            row.allKeys.map { model in
                let key = KeyButton(model: model, style: style(for: model))
                key.theme = theme
                addSubview(key)
                if model.kind == .globe {
                    key.isUserInteractionEnabled = true
                    onGlobeKeyCreated?(key)
                }
                return key
            }
        }
        refreshKeyAppearance()
        setNeedsLayout()
    }

    /// Re-attaches the globe handler (call after setting `onGlobeKeyCreated`).
    func rebindGlobeKey() {
        allKeyViews.filter { $0.model.kind == .globe }.forEach { onGlobeKeyCreated?($0) }
    }

    private func style(for model: KeyModel) -> KeyButton.Style {
        switch model.kind {
        case .character, .space: return .letter
        case .returnKey: return returnIsPrimary ? .primary : .function
        default: return .function
        }
    }

    private func refreshKeyAppearance() {
        let config = metrics.symbolConfiguration
        for key in allKeyViews {
            key.setCornerRadius(metrics.cornerRadius)
            switch key.model.kind {
            case .character(let c):
                let upper = page == .letters && shiftState != .lowercase
                key.setTitle(displayText(c), font: upper ? metrics.uppercaseLetterFont : metrics.letterFont)
            case .shift:
                let name: String
                switch shiftState {
                case .lowercase: name = "shift"
                case .shifted: name = "shift.fill"
                case .capsLock: name = "capslock.fill"
                }
                key.setSymbol(name, configuration: config, accessibilityLabel: "shift")
                key.isActive = shiftState != .lowercase
            case .backspace:
                key.setSymbol("delete.left", configuration: config, accessibilityLabel: "delete")
            case .globe:
                key.setSymbol("globe", configuration: config, accessibilityLabel: "next keyboard")
            case .pageSwitch(_, let label):
                key.setTitle(label, font: metrics.functionFont)
            case .space:
                key.setTitle("space", font: metrics.functionFont)
            case .returnKey:
                key.setTitle(returnTitle, font: metrics.functionFont)
                key.style = returnIsPrimary ? .primary : .function
            }
        }
    }

    /// Casing applied to a lowercase base character for display/insertion.
    private func displayText(_ base: String) -> String {
        (page == .letters && shiftState != .lowercase) ? base.uppercased() : base
    }

    // MARK: Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        let m = metrics
        let width = bounds.width
        let unit = (width - m.sideInset * 2 - m.horizontalGap * 9) / 10
        let verticalPad = m.verticalGap / 2

        for (rowIndex, row) in rows.enumerated() {
            let views = keyViews[rowIndex]
            let y = CGFloat(rowIndex) * m.rowPitch + verticalPad
            var frames: [CGRect] = []

            // leading
            var x = m.sideInset
            for model in row.leading {
                let w = unit * CGFloat(model.widthUnits)
                frames.append(CGRect(x: x, y: y, width: w, height: m.keyHeight))
                x += w + m.horizontalGap
            }
            let centerStart = x

            // trailing (computed right-to-left, appended later)
            var trailingFrames: [CGRect] = []
            var tx = width - m.sideInset
            for model in row.trailing.reversed() {
                let w = unit * CGFloat(model.widthUnits)
                tx -= w
                trailingFrames.insert(CGRect(x: tx, y: y, width: w, height: m.keyHeight), at: 0)
                tx -= m.horizontalGap
            }
            let centerEnd = row.trailing.isEmpty ? width - m.sideInset : tx

            // center
            let n = CGFloat(row.center.count)
            if row.centerFills {
                let w = (centerEnd - centerStart - m.horizontalGap * (n - 1)) / n
                var cx = centerStart
                for _ in row.center {
                    frames.append(CGRect(x: cx, y: y, width: w, height: m.keyHeight))
                    cx += w + m.horizontalGap
                }
            } else {
                let total = unit * n + m.horizontalGap * (n - 1)
                var cx = (width - total) / 2
                for _ in row.center {
                    frames.append(CGRect(x: cx, y: y, width: unit, height: m.keyHeight))
                    cx += unit + m.horizontalGap
                }
            }

            frames += trailingFrames
            for (view, frame) in zip(views, frames) {
                view.frame = frame.integralIfNeeded
            }
        }
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: metrics.keysHeight)
    }

    // MARK: Hit testing

    private func nearestKey(to point: CGPoint) -> KeyButton? {
        var best: KeyButton?
        var bestDistance = CGFloat.greatestFiniteMagnitude
        for key in allKeyViews {
            let f = key.frame
            let dx = max(f.minX - point.x, 0, point.x - f.maxX)
            let dy = max(f.minY - point.y, 0, point.y - f.maxY)
            let d = dx * dx + dy * dy
            if d < bestDistance {
                bestDistance = d
                best = key
            }
        }
        return best
    }

    // MARK: Touches

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            // Fast typing rollover: a new touch commits earlier pending character taps.
            for (other, active) in activeTouches where active.key.model.isCharacter
                && active.accentPopup == nil && !active.consumed {
                commit(active)
                active.invalidate()
                activeTouches[other] = nil
            }

            // Resolve after committing: a commit can switch pages and rebuild the keys.
            guard let key = nearestKey(to: touch.location(in: self)), key.model.kind != .globe else { continue }
            let active = ActiveTouch(key: key)
            activeTouches[touch] = active
            begin(active, touch: touch)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            guard let active = activeTouches[touch] else { continue }
            let point = touch.location(in: self)

            if let accent = active.accentPopup {
                accent.updateSelection(forX: point.x)
                continue
            }
            // Slide between character keys before the long-press fires (stock behaviour).
            guard active.key.model.isCharacter, !active.consumed,
                  let newKey = nearestKey(to: point), newKey !== active.key, newKey.model.isCharacter else { continue }
            active.invalidate()
            active.key = newKey
            begin(active, touch: touch, playFeedback: false)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            guard let active = activeTouches.removeValue(forKey: touch) else { continue }
            commit(active)
            active.invalidate()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            activeTouches.removeValue(forKey: touch)?.invalidate()
        }
    }

    func cancelAllTouches() {
        activeTouches.values.forEach { $0.invalidate() }
        activeTouches.removeAll()
    }

    private func begin(_ active: ActiveTouch, touch: UITouch, playFeedback: Bool = true) {
        let key = active.key
        if playFeedback { onKeyDown?(key.model) }

        switch key.model.kind {
        case .character(let base):
            showPopup(for: active, title: displayText(base))
            scheduleLongPress(for: active)

        case .space, .returnKey:
            key.isPressed = true

        case .backspace:
            key.isPressed = true
            onEvent?(.backspace)
            scheduleLongPress(for: active)

        case .shift:
            onEvent?(.shift)
            active.consumed = true

        case .pageSwitch(let target, _):
            active.consumed = true
            onEvent?(.switchPage(target))

        case .globe:
            break
        }
    }

    /// Emits the touch-up event for a tap (if it wasn't consumed by a long-press).
    private func commit(_ active: ActiveTouch) {
        if let accent = active.accentPopup {
            if let option = accent.selectedOption { onEvent?(.character(option)) }
            active.consumed = true
            return
        }
        guard !active.consumed else { return }
        active.consumed = true

        switch active.key.model.kind {
        case .character(let base): onEvent?(.character(displayText(base)))
        case .space: onEvent?(.space)
        case .returnKey: onEvent?(.returnKey)
        default: break
        }
    }

    private func showPopup(for active: ActiveTouch, title: String) {
        let popup = KeyPopupView(keyFrame: active.key.frame, title: title,
                                 metrics: metrics, theme: theme, containerWidth: bounds.width)
        addSubview(popup)
        active.popup = popup
    }

    private func scheduleLongPress(for active: ActiveTouch) {
        let behavior = active.key.model.longPress
        guard behavior != .none else { return }

        let work = DispatchWorkItem { [weak self, weak active] in
            guard let self, let active, !active.consumed else { return }
            self.fireLongPress(behavior, for: active)
        }
        active.longPressWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.longPressDelay, execute: work)
    }

    private func fireLongPress(_ behavior: LongPressBehavior, for active: ActiveTouch) {
        switch behavior {
        case .none:
            break

        case .shortcut(let action):
            active.consumed = true
            active.popup?.removeFromSuperview()
            active.popup = nil
            onEvent?(.shortcut(action))

        case .accents(let list):
            active.popup?.removeFromSuperview()
            active.popup = nil
            let options = list.map { displayText($0) }
            let accent = AccentPopupView(keyFrame: active.key.frame, options: options,
                                         metrics: metrics, theme: theme, containerWidth: bounds.width)
            addSubview(accent)
            accent.updateSelection(forX: active.key.frame.midX)
            active.accentPopup = accent

        case .autoRepeat:
            active.repeatTimer = Timer.scheduledTimer(withTimeInterval: Self.repeatInterval, repeats: true) { [weak self] _ in
                self?.onEvent?(.backspace)
            }
        }
    }
}

private extension CGRect {
    /// Snap to pixel boundaries for crisp edges.
    var integralIfNeeded: CGRect {
        let scale = UIScreen.main.scale
        func snap(_ v: CGFloat) -> CGFloat { (v * scale).rounded() / scale }
        return CGRect(x: snap(minX), y: snap(minY), width: snap(width), height: snap(height))
    }
}
