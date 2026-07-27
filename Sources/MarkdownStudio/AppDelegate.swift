import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var documentWindows: [DocumentWindowController] = []
    private var pendingOpenURLs: [URL] = []
    private var didFinishLaunching = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMenus()
        didFinishLaunching = true

        if pendingOpenURLs.isEmpty {
            createWindow()
        } else {
            let urls = pendingOpenURLs
            pendingOpenURLs.removeAll()
            urls.forEach { createWindow(opening: $0) }
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        for controller in documentWindows where !controller.confirmClose() {
            controller.showWindow(nil)
            controller.window?.makeKeyAndOrderFront(nil)
            return .terminateCancel
        }
        return .terminateNow
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        let urls = filenames.map { URL(fileURLWithPath: $0) }
        if didFinishLaunching {
            urls.forEach { createWindow(opening: $0) }
        } else {
            pendingOpenURLs.append(contentsOf: urls)
        }
        sender.reply(toOpenOrPrint: .success)
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        let url = URL(fileURLWithPath: filename)
        if didFinishLaunching {
            createWindow(opening: url)
        } else {
            pendingOpenURLs.append(url)
        }
        return true
    }

    @objc private func newDocument() {
        createWindow()
    }

    @objc private func openDocument() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            .init(filenameExtension: "md")!,
            .init(filenameExtension: "markdown")!,
            .plainText
        ]
        panel.allowsMultipleSelection = true
        guard panel.runModal() == .OK else { return }
        openInWindows(panel.urls)
    }

    @objc private func saveDocument() {
        activeController?.saveDocument()
    }

    @objc private func saveDocumentAs() {
        activeController?.saveDocumentAs()
    }

    @objc private func togglePreview() {
        activeController?.togglePreview()
    }

    private var activeController: DocumentWindowController? {
        if let keyWindow = NSApp.keyWindow,
           let controller = documentWindows.first(where: { $0.window === keyWindow }) {
            return controller
        }
        return documentWindows.last
    }

    private func createWindow(opening url: URL? = nil) {
        if let url,
           documentWindows.count == 1,
           let blankWindow = documentWindows.first,
           blankWindow.isPristineUntitled
        {
            blankWindow.openDocument(at: url)
            blankWindow.showWindow(nil)
            blankWindow.window?.makeKeyAndOrderFront(nil)
            return
        }

        let controller = DocumentWindowController(opening: url)
        if let previousFrame = documentWindows.last?.window?.frame {
            controller.window?.setFrameOrigin(
                NSPoint(x: previousFrame.origin.x + 28, y: previousFrame.origin.y - 28)
            )
        }
        controller.onClose = { [weak self, weak controller] in
            guard let self, let controller else { return }
            self.documentWindows.removeAll { $0 === controller }
        }
        documentWindows.append(controller)
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func openInWindows(_ urls: [URL]) {
        for url in urls {
            createWindow(opening: url)
        }
    }

    private func buildMenus() {
        let mainMenu = NSMenu()
        NSApp.mainMenu = mainMenu

        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appItem.submenu = appMenu
        appMenu.addItem(
            withTitle: "About Markdown Studio",
            action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
            keyEquivalent: ""
        )
        appMenu.addItem(.separator())
        appMenu.addItem(
            withTitle: "Quit Markdown Studio",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )

        let fileItem = NSMenuItem()
        mainMenu.addItem(fileItem)
        let fileMenu = NSMenu(title: "File")
        fileItem.submenu = fileMenu
        fileMenu.addItem(withTitle: "New Window", action: #selector(newDocument), keyEquivalent: "n").target = self
        fileMenu.addItem(withTitle: "Open…", action: #selector(openDocument), keyEquivalent: "o").target = self
        fileMenu.addItem(.separator())
        fileMenu.addItem(withTitle: "Save", action: #selector(saveDocument), keyEquivalent: "s").target = self
        let saveAs = fileMenu.addItem(
            withTitle: "Save As…",
            action: #selector(saveDocumentAs),
            keyEquivalent: "S"
        )
        saveAs.keyEquivalentModifierMask = [.command, .shift]
        saveAs.target = self

        let editItem = NSMenuItem()
        mainMenu.addItem(editItem)
        let editMenu = NSMenu(title: "Edit")
        editItem.submenu = editMenu
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        let redo = editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        redo.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        let viewItem = NSMenuItem()
        mainMenu.addItem(viewItem)
        let viewMenu = NSMenu(title: "View")
        viewItem.submenu = viewMenu
        let previewItem = viewMenu.addItem(
            withTitle: "Toggle Markdown Preview",
            action: #selector(togglePreview),
            keyEquivalent: "v"
        )
        previewItem.keyEquivalentModifierMask = [.command, .shift]
        previewItem.target = self
    }
}
