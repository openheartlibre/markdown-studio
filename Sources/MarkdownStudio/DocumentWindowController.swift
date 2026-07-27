import AppKit
@preconcurrency import WebKit

final class DocumentWindowController: NSWindowController,
    NSWindowDelegate,
    NSTextViewDelegate,
    WKNavigationDelegate,
    NSToolbarDelegate
{
    var onClose: (() -> Void)?
    var isPristineUntitled: Bool {
        documentState.fileURL == nil && documentState.text.isEmpty && !documentState.isDirty
    }

    private let documentState = DocumentState()
    private var textView: NSTextView!
    private var editorScrollView: NSScrollView!
    private var preview: WKWebView!
    private var container: NSView!
    private var modeControl: NSSegmentedControl!
    private var previewWorkItem: DispatchWorkItem?
    private var shortcutMonitor: Any?
    private var showingPreview = false
    private var closeWasConfirmed = false
    private var previewZoom = 1.0
    private var zoomLabel: NSTextField?

    init(opening url: URL? = nil) {
        super.init(window: nil)
        buildWindow()
        installShortcutMonitor()

        if let url {
            do {
                try documentState.open(url)
                textView.string = documentState.text
                showPreview()
            } catch {
                showError(error)
                showEditor()
            }
        } else {
            showEditor()
        }
        updateTitle()
    }

    required init?(coder: NSCoder) {
        nil
    }

    deinit {
        if let shortcutMonitor {
            NSEvent.removeMonitor(shortcutMonitor)
        }
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(sender)
    }

    func openDocument(at url: URL) {
        do {
            try documentState.open(url)
            textView.string = documentState.text
            showPreview()
            updateTitle()
        } catch {
            showError(error)
        }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        closeWasConfirmed || confirmClose()
    }

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }

    func confirmClose() -> Bool {
        guard documentState.isDirty else {
            closeWasConfirmed = true
            return true
        }

        let alert = NSAlert()
        alert.messageText = "Do you want to save “\(documentState.displayName)”?"
        alert.informativeText = "Your changes will be lost if you don’t save them."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Don’t Save")
        alert.addButton(withTitle: "Cancel")

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            saveDocument()
            closeWasConfirmed = !documentState.isDirty
        case .alertSecondButtonReturn:
            closeWasConfirmed = true
        default:
            closeWasConfirmed = false
        }
        return closeWasConfirmed
    }

    func saveDocument() {
        if documentState.fileURL == nil {
            saveDocumentAs()
            return
        }
        do {
            try documentState.save()
            updateTitle()
        } catch {
            showError(error)
        }
    }

    func saveDocumentAs() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [
            .init(filenameExtension: "md")!,
            .init(filenameExtension: "markdown")!,
            .plainText
        ]
        panel.nameFieldStringValue = documentState.displayName
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try documentState.save(to: url)
            updateTitle()
        } catch {
            showError(error)
        }
    }

    @objc func togglePreview() {
        showingPreview ? showEditor() : showPreview()
    }

    @objc private func zoomIn() {
        setPreviewZoom(previewZoom + 0.1)
    }

    @objc private func zoomOut() {
        setPreviewZoom(previewZoom - 0.1)
    }

    @objc private func modeChanged(_ sender: NSSegmentedControl) {
        sender.selectedSegment == 0 ? showEditor() : showPreview()
    }

    func textDidChange(_ notification: Notification) {
        documentState.updateText(textView.string)
        updateTitle()
        guard showingPreview else { return }

        previewWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.loadPreview()
        }
        previewWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18, execute: item)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if navigationAction.navigationType == .linkActivated,
           let url = navigationAction.request.url
        {
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }

    private func buildWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1080, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        self.window = window
        window.center()
        window.minSize = NSSize(width: 640, height: 440)
        window.delegate = self
        window.titlebarAppearsTransparent = false
        window.titleVisibility = .visible
        window.isMovableByWindowBackground = true

        let toolbar = NSToolbar(identifier: "MarkdownStudioToolbar-\(UUID().uuidString)")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        window.toolbar = toolbar
        window.toolbarStyle = .unified

        container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = container

        editorScrollView = NSScrollView()
        editorScrollView.translatesAutoresizingMaskIntoConstraints = false
        editorScrollView.hasVerticalScroller = true
        editorScrollView.hasHorizontalScroller = false
        editorScrollView.autohidesScrollers = true
        editorScrollView.drawsBackground = true

        textView = NSTextView(frame: editorScrollView.contentView.bounds)
        textView.delegate = self
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.allowsUndo = true
        textView.font = .monospacedSystemFont(ofSize: 15, weight: .regular)
        textView.textContainerInset = NSSize(width: 30, height: 30)
        textView.minSize = NSSize(width: 0, height: editorScrollView.contentSize.height)
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(
            width: editorScrollView.contentSize.width,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.lineBreakMode = .byWordWrapping
        editorScrollView.documentView = textView

        preview = WKWebView()
        preview.translatesAutoresizingMaskIntoConstraints = false
        preview.navigationDelegate = self

        container.addSubview(editorScrollView)
        container.addSubview(preview)
        NSLayoutConstraint.activate([
            editorScrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            editorScrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            editorScrollView.topAnchor.constraint(equalTo: container.topAnchor),
            editorScrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            preview.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            preview.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            preview.topAnchor.constraint(equalTo: container.topAnchor),
            preview.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        preview.isHidden = true
    }

    private func showEditor() {
        showingPreview = false
        preview.isHidden = true
        editorScrollView.isHidden = false
        modeControl?.selectedSegment = 0
        window?.makeFirstResponder(textView)
    }

    private func showPreview() {
        showingPreview = true
        editorScrollView.isHidden = true
        preview.isHidden = false
        modeControl?.selectedSegment = 1
        preview.pageZoom = previewZoom
        loadPreview()
    }

    private func loadPreview() {
        preview.loadHTMLString(
            MarkdownRenderer.page(for: documentState.text),
            baseURL: documentState.fileURL?.deletingLastPathComponent()
        )
    }

    private func updateTitle() {
        window?.title = "\(documentState.isDirty ? "● " : "")\(documentState.displayName) — Markdown Studio"
        window?.representedURL = documentState.fileURL
    }

    private func setPreviewZoom(_ value: Double) {
        previewZoom = min(2.5, max(0.5, value))
        preview.pageZoom = previewZoom
        zoomLabel?.stringValue = "\(Int((previewZoom * 100).rounded()))%"
    }

    private func showError(_ error: Error) {
        let alert = NSAlert(error: error)
        if let window {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }

    private func installShortcutMonitor() {
        shortcutMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.window?.isKeyWindow == true else { return event }
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if event.charactersIgnoringModifiers?.lowercased() == "v",
               modifiers.contains([.command, .shift])
            {
                self.togglePreview()
                return nil
            }
            if modifiers.contains(.command) {
                switch event.charactersIgnoringModifiers {
                case "-", "_":
                    self.zoomOut()
                    return nil
                case "=", "+":
                    self.zoomIn()
                    return nil
                default:
                    break
                }
            }
            return event
        }
    }

    private static let saveItem = NSToolbarItem.Identifier("save")
    private static let modeItem = NSToolbarItem.Identifier("mode")
    private static let zoomItem = NSToolbarItem.Identifier("zoom")

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.flexibleSpace, Self.saveItem, Self.modeItem, Self.zoomItem]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [Self.saveItem, .flexibleSpace, Self.modeItem, Self.zoomItem, .flexibleSpace]
    }

    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier identifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        let item = NSToolbarItem(itemIdentifier: identifier)
        switch identifier {
        case Self.saveItem:
            item.label = "Save"
            item.toolTip = "Save File (⌘S)"
            let saveButton = NSButton(
                title: "Save",
                image: NSImage(
                    systemSymbolName: "externaldrive.fill",
                    accessibilityDescription: "Save File"
                )!,
                target: self,
                action: #selector(saveFromToolbar)
            )
            saveButton.imagePosition = .imageLeading
            saveButton.bezelStyle = .texturedRounded
            item.view = saveButton
        case Self.modeItem:
            modeControl = NSSegmentedControl(
                labels: ["Edit", "Preview"],
                trackingMode: .selectOne,
                target: self,
                action: #selector(modeChanged(_:))
            )
            modeControl.selectedSegment = showingPreview ? 1 : 0
            item.view = modeControl
            item.label = "View Mode"
        case Self.zoomItem:
            let zoomOutButton = NSButton(
                image: NSImage(
                    systemSymbolName: "minus.magnifyingglass",
                    accessibilityDescription: "Zoom Out"
                )!,
                target: self,
                action: #selector(zoomOut)
            )
            zoomOutButton.bezelStyle = .texturedRounded

            let label = NSTextField(labelWithString: "100%")
            label.alignment = .center
            label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
            label.widthAnchor.constraint(equalToConstant: 46).isActive = true
            zoomLabel = label

            let zoomInButton = NSButton(
                image: NSImage(
                    systemSymbolName: "plus.magnifyingglass",
                    accessibilityDescription: "Zoom In"
                )!,
                target: self,
                action: #selector(zoomIn)
            )
            zoomInButton.bezelStyle = .texturedRounded

            let stack = NSStackView(views: [zoomOutButton, label, zoomInButton])
            stack.orientation = .horizontal
            stack.alignment = .centerY
            stack.spacing = 4
            item.view = stack
            item.label = "Preview Zoom"
        default:
            return nil
        }
        return item
    }

    @objc private func saveFromToolbar() {
        saveDocument()
    }
}
