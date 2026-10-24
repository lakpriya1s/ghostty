import Cocoa
import SwiftUI

/// The Setup Assistant: a wizard for KinTerm's own options (faces, the tab
/// bar, the Claude Code hook, notifications and the summaries), shown on
/// first launch and from KinTerm › Setup Assistant… after that. Choices apply
/// as they're made, so the windows behind it show them right away.
final class OnboardingController: NSWindowController, NSWindowDelegate {
    static let shared = OnboardingController()

    private static let completedKey = "OnboardingCompleted"

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 560),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: true)
        window.title = "Welcome to KinTerm"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.appearance = NSAppearance(named: .darkAqua)
        window.isReleasedWhenClosed = false
        super.init(window: window)
        window.delegate = self
        window.contentView = NSHostingView(rootView: OnboardingView(finish: { [weak self] in self?.finish() }))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Add "Setup Assistant…" to the app menu, and show the wizard if it
    /// hasn't been finished yet.
    func start() {
        installMenuItem()
        var force = false
        #if DEBUG
        force = ProcessInfo.processInfo.environment["KINTERM_ONBOARDING_STEP"] != nil
        #endif
        guard force || !UserDefaults.ghostty.bool(forKey: Self.completedKey) else { return }
        // After the first terminal window is up, so the wizard sits on top.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in self?.show() }
    }

    @objc func show() {
        guard let window else { return }
        if !window.isVisible {
            window.contentView = NSHostingView(rootView: OnboardingView(finish: { [weak self] in self?.finish() }))
            window.center()
        }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func finish() {
        window?.close()
    }

    func windowWillClose(_ notification: Notification) {
        // Closing early counts too: everything has a working default, and
        // the wizard is always in the KinTerm menu.
        UserDefaults.ghostty.set(true, forKey: Self.completedKey)
    }

    private func installMenuItem() {
        guard let appMenu = NSApp.mainMenu?.items.first?.submenu,
              !appMenu.items.contains(where: { $0.action == #selector(show) }) else { return }
        let item = NSMenuItem(title: "Setup Assistant…", action: #selector(show), keyEquivalent: "")
        item.target = self
        item.setImageIfDesired(systemSymbolName: "wand.and.stars")
        // Right after "About KinTerm".
        appMenu.insertItem(item, at: min(1, appMenu.items.count))
    }
}
