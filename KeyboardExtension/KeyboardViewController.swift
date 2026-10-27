import UIKit

/// Principal class of the keyboard extension (see `NSExtensionPrincipalClass` in Info.plist).
///
/// Acts as a coordinator: owns the shift/page state, routes `KeyEvent`s from `KeyboardView`
/// to the `textDocumentProxy`, and wires up the clipboard bar, panel, and shortcuts.
final class KeyboardViewController: UIInputViewController {

    // MARK: Dependencies & state

    private let store = ClipboardStore.shared
    private lazy var monitor = PasteboardMonitor(store: store)
    private let feedback = FeedbackManager()
    private var state = KeyboardState()
    private var lastSpaceTime: TimeInterval?
    private var isPanelExpanded = false

    // MARK: Views

    private let barView = ClipboardBarView()
    private let keyboardView = KeyboardView()
    private let panelView = ClipboardPanelView()
    private let toastView = ToastView()

    private var heightConstraint: NSLayoutConstraint?
    private var barHeightConstraint: NSLayoutConstraint?
    private var metrics: KeyboardMetrics = .portrait
    private var theme: KeyboardTheme = .light

    // MARK: Lifecycle

    override func loadView() {
        let input = KeyboardInputView(frame: .zero, inputViewStyle: .keyboard)
        input.allowsSelfSizing = true
        view = input
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildHierarchy()
        bindCallbacks()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        feedback.hasFullAccess = hasFullAccess
        feedback.prepare()
        updateMetrics()
        refreshEnvironment()
        if hasFullAccess {
            monitor.start()
        }
        reloadClipboard()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        monitor.stop()
        keyboardView.cancelAllTouches()
        setPanelExpanded(false)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateMetrics()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in self.updateMetrics() })
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyTheme()
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        // Host field may have changed (keyboardAppearance, returnKeyType, cursor position...).
        refreshEnvironment()
    }

    // MARK: Setup

    private func buildHierarchy() {
        view.backgroundColor = KeyboardTheme.usesSystemBackdrop ? .clear : theme.background

        // Order matters: keyboardView sits above the bar so key popups can overlap it.
        [barView, keyboardView, panelView, toastView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        panelView.isHidden = true

        let guide = view.safeAreaLayoutGuide
        let barHeight = barView.heightAnchor.constraint(equalToConstant: metrics.barHeight)
        let height = view.heightAnchor.constraint(equalToConstant: metrics.totalHeight)
        height.priority = UILayoutPriority(999)   // avoid conflicts with the system's temporary constraints
        barHeightConstraint = barHeight
        heightConstraint = height

        NSLayoutConstraint.activate([
            height,
            barHeight,
            barView.topAnchor.constraint(equalTo: view.topAnchor),
            barView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            barView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),

            keyboardView.topAnchor.constraint(equalTo: barView.bottomAnchor),
            keyboardView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            keyboardView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),

            panelView.topAnchor.constraint(equalTo: barView.bottomAnchor),
            panelView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            panelView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            panelView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),

            toastView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastView.centerYAnchor.constraint(equalTo: barView.centerYAnchor),
            toastView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -40),
        ])
    }

    private func bindCallbacks() {
        keyboardView.onEvent = { [weak self] event in self?.handle(event) }
        keyboardView.onKeyDown = { [weak self] _ in self?.feedback.keyClick() }
        keyboardView.onGlobeKeyCreated = { [weak self] control in
            guard let self else { return }
            control.removeTarget(nil, action: nil, for: .allEvents)
            control.addTarget(self, action: #selector(self.handleInputModeList(from:with:)), for: .allTouchEvents)
        }
        keyboardView.rebindGlobeKey()

        monitor.onChange = { [weak self] in self?.reloadClipboard() }

        barView.onSelect = { [weak self] item in self?.insertClip(item) }
        barView.onDelete = { [weak self] item in self?.deleteClip(item) }
        barView.onToggleExpanded = { [weak self] in
            guard let self else { return }
            self.setPanelExpanded(!self.isPanelExpanded)
        }

        panelView.onSelect = { [weak self] item in self?.insertClip(item) }
        panelView.onDelete = { [weak self] item in self?.deleteClip(item) }
        panelView.onClear = { [weak self] in
            self?.store.clear()
            self?.reloadClipboard()
        }
    }

    // MARK: Environment (theme, metrics, return key, globe)

    private func updateMetrics() {
        // iPhone landscape: screen wider than tall. (UIScreen.main is not deprecated at iOS 15.)
        let screen = UIScreen.main.bounds.size
        let newMetrics: KeyboardMetrics = screen.width > screen.height ? .landscape : .portrait
        guard newMetrics != metrics || heightConstraint?.constant != newMetrics.totalHeight else { return }
        metrics = newMetrics
        heightConstraint?.constant = newMetrics.totalHeight
        barHeightConstraint?.constant = newMetrics.barHeight
        keyboardView.setMetrics(newMetrics)
    }

    private func refreshEnvironment() {
        applyTheme()
        keyboardView.setShowsGlobe(needsInputModeSwitchKey)
        let (title, primary) = Self.returnKeyLabel(for: textDocumentProxy.returnKeyType ?? .default)
        keyboardView.setReturnKey(title: title, isPrimary: primary)
        updateAutoShift()
    }

    private func applyTheme() {
        let newTheme = KeyboardTheme.resolve(appearance: textDocumentProxy.keyboardAppearance, traits: traitCollection)
        theme = newTheme
        if !KeyboardTheme.usesSystemBackdrop { view.backgroundColor = newTheme.background }
        keyboardView.setTheme(newTheme)
        barView.apply(theme: newTheme)
        panelView.apply(theme: newTheme)
        toastView.apply(theme: newTheme)
    }

    static func returnKeyLabel(for type: UIReturnKeyType) -> (String, Bool) {
        switch type {
        case .go: return ("go", true)
        case .google, .yahoo, .search: return ("search", true)
        case .join: return ("join", true)
        case .next: return ("next", false)
        case .route: return ("route", true)
        case .send: return ("send", true)
        case .done: return ("done", true)
        case .emergencyCall: return ("emergency", true)
        case .continue: return ("continue", true)
        case .default: return ("return", false)
        @unknown default: return ("return", false)
        }
    }

    // MARK: Key events

    private func handle(_ event: KeyEvent) {
        let proxy = textDocumentProxy

        switch event {
        case .character(let text):
            proxy.insertText(text)
            state.didInsertCharacter(text)
            lastSpaceTime = nil
            updateAutoShift()

        case .space:
            let now = CACurrentMediaTime()
            if TextContext.shouldConvertDoubleSpace(before: proxy.documentContextBeforeInput,
                                                    lastSpaceTime: lastSpaceTime, now: now) {
                proxy.deleteBackward()
                proxy.insertText(". ")
                lastSpaceTime = nil
            } else {
                proxy.insertText(" ")
                lastSpaceTime = now
            }
            state.didInsertSpace()
            updateAutoShift()

        case .backspace:
            proxy.deleteBackward()
            lastSpaceTime = nil
            updateAutoShift()

        case .returnKey:
            proxy.insertText("\n")
            lastSpaceTime = nil
            updateAutoShift()

        case .shift:
            state.tapShift(at: CACurrentMediaTime())

        case .switchPage(let page):
            state.setPage(page)

        case .shortcut(let action):
            performShortcut(action)
        }

        keyboardView.configure(page: state.page, shift: state.shift)
    }

    private func updateAutoShift() {
        let mode = Self.autocapMode(textDocumentProxy.autocapitalizationType ?? .sentences)
        let should = TextContext.shouldAutoCapitalize(before: textDocumentProxy.documentContextBeforeInput, mode: mode)
        state.applyAutoShift(should)
        keyboardView.configure(page: state.page, shift: state.shift)
    }

    static func autocapMode(_ type: UITextAutocapitalizationType) -> AutocapMode {
        switch type {
        case .none: return .none
        case .words: return .words
        case .sentences: return .sentences
        case .allCharacters: return .allCharacters
        @unknown default: return .sentences
        }
    }

    // MARK: Shortcuts (long-press V / C)

    private func performShortcut(_ action: ShortcutAction) {
        let actions = ShortcutActions(proxy: textDocumentProxy, store: store, hasFullAccess: hasFullAccess)
        let result = (action == .paste) ? actions.paste() : actions.copy()
        feedback.shortcutFired()

        switch result {
        case .pasted:
            toastView.show("Pasted")
            lastSpaceTime = nil
            updateAutoShift()
        case .copied(let text):
            let snippet = text.count > 24 ? String(text.prefix(24)) + "…" : text
            toastView.show("Copied ‘\(snippet)’")
            // Our own write bumps changeCount; record it so the monitor doesn't re-process it.
            store.lastSeenChangeCount = UIPasteboard.general.changeCount
            reloadClipboard()
        case .empty:
            toastView.show(action == .paste ? "Clipboard is empty" : "Nothing to copy")
        case .needsFullAccess:
            toastView.show("Enable Full Access to use the clipboard")
        }
    }

    // MARK: Clipboard

    private func reloadClipboard() {
        let items = hasFullAccess ? store.items : []
        barView.update(items: items, hasFullAccess: hasFullAccess)
        panelView.update(items: items)
    }

    private func insertClip(_ item: ClipItem) {
        feedback.keyClick()
        feedback.lightTap()
        textDocumentProxy.insertText(item.text)
        lastSpaceTime = nil
        updateAutoShift()
    }

    private func deleteClip(_ item: ClipItem) {
        store.remove(id: item.id)
        reloadClipboard()
    }

    private func setPanelExpanded(_ expanded: Bool) {
        guard expanded != isPanelExpanded else { return }
        isPanelExpanded = expanded
        if expanded {
            keyboardView.cancelAllTouches()
            reloadClipboard()
        }
        panelView.isHidden = !expanded
        keyboardView.isHidden = expanded
        barView.setExpanded(expanded)
    }
}
