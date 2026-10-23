import AppKit
import Combine
import SwiftUI

/// A summary of the agents in every window, shown outside the windows: a
/// count on the dock icon and an item in the menu bar. See
/// scope/designs/04-notifications.md.
final class AgentSummary {
    static let shared = AgentSummary()

    /// One tab with an agent in it.
    struct Entry {
        let controller: BaseTerminalController
        let status: Ghostty.Action.ProgramStatus
    }

    private(set) var entries: [Entry] = []

    /// Agents that need the user: waiting on them, or done and not yet seen.
    var attentionCount: Int {
        entries.filter { $0.status.state == .blocked || $0.status.state == .done }.count
    }

    private var statusItem: NSStatusItem?
    private var cancellables: Set<AnyCancellable> = []

    /// Start following changes. Safe to call more than once.
    func start() {
        guard cancellables.isEmpty else { return }
        let closes = NotificationCenter.default.publisher(for: NSWindow.willCloseNotification).map { _ in () }
        Publishers.Merge(AgentTabBarModel.changesPublisher, closes)
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] in self?.update() }
            .store(in: &cancellables)
        update()
    }

    func update() {
        entries = NSApp.windows
            .filter(\.isVisible)
            .compactMap { $0.windowController as? BaseTerminalController }
            .compactMap { controller in
                guard let status = controller.programStatus, status.state != .clear else { return nil }
                return Entry(controller: controller, status: status)
            }
            .sorted { $0.status.state.urgency > $1.status.state.urgency }

        (NSApp.delegate as? AppDelegate)?.syncDockBadge()
        updateStatusItem()
    }

    // MARK: Menu bar

    private func updateStatusItem() {
        let settings = AgentTabBarSettings.shared
        guard settings.showsMenuBarSummary, !entries.isEmpty else {
            if let statusItem { NSStatusBar.system.removeStatusItem(statusItem) }
            statusItem = nil
            return
        }

        let item = statusItem ?? NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem = item
        item.button?.attributedTitle = title()
        item.button?.toolTip = "Agents"
        item.menu = menu()
    }

    /// "● 1 waiting  ● 1 working", with each dot in its state's color, like
    /// the design. Only states that have agents are listed.
    private func title() -> NSAttributedString {
        let counts: [(Ghostty.Action.ProgramStatus.State, String)] = [
            (.blocked, "waiting"), (.error, "error"), (.done, "done"), (.working, "working"), (.idle, "idle"),
        ]
        let font = NSFont.menuBarFont(ofSize: 0)
        let result = NSMutableAttributedString()
        for (state, word) in counts {
            let count = entries.filter { $0.status.state == state }.count
            guard count > 0 else { continue }
            if result.length > 0 { result.append(NSAttributedString(string: "  ", attributes: [.font: font])) }
            result.append(NSAttributedString(string: "● ", attributes: [
                .font: NSFont.systemFont(ofSize: font.pointSize * 0.8),
                .foregroundColor: NSColor(AgentFaceView.color(for: state)),
                .baselineOffset: 1,
            ]))
            result.append(NSAttributedString(string: "\(count) \(word)", attributes: [.font: font]))
        }
        return result
    }

    /// One row per agent, most urgent first. Choosing one jumps to its tab
    /// and split.
    private func menu() -> NSMenu {
        let menu = NSMenu()
        for entry in entries {
            let title = entry.controller.window?.title ?? "Terminal"
            let row = NSMenuItem(title: "\(title) — \(entry.status.stateLabel)", action: #selector(jump(_:)), keyEquivalent: "")
            row.target = self
            row.representedObject = entry.controller
            row.image = Self.dot(AgentFaceView.color(for: entry.status.state))
            if let msg = entry.status.msg { row.toolTip = msg }
            menu.addItem(row)
        }
        menu.addItem(.separator())
        let hide = NSMenuItem(title: "Hide Menu Bar Summary", action: #selector(hideSummary), keyEquivalent: "")
        hide.target = self
        menu.addItem(hide)
        return menu
    }

    @objc private func jump(_ sender: NSMenuItem) {
        guard let controller = sender.representedObject as? BaseTerminalController else { return }
        Self.focus(controller)
    }

    @objc private func hideSummary() {
        AgentTabBarSettings.shared.showsMenuBarSummary = false
    }

    /// Bring a tab forward and focus the split whose agent it shows.
    static func focus(_ controller: BaseTerminalController) {
        let target = controller.programStatus
        let surface = controller.surfaceTree.first { $0.programStatus == target } ?? controller.focusedSurface
        controller.window?.tabGroup?.selectedWindow = controller.window
        if let surface {
            controller.focusSurface(surface)
        } else {
            controller.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private static func dot(_ color: Color) -> NSImage {
        let image = NSImage(size: NSSize(width: 10, height: 10), flipped: false) { rect in
            NSColor(color).setFill()
            NSBezierPath(ovalIn: rect.insetBy(dx: 1, dy: 1)).fill()
            return true
        }
        return image
    }
}
