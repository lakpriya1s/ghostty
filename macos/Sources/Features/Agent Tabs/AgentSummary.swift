import AppKit
import Combine
import SwiftUI
import UserNotifications

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
        addViewMenuItem()
        update()
    }

    /// "Agent Tab Bar" and "Show Agents in Menu Bar" in the View menu, so
    /// both can always be changed back: with native tabs there's no face bar
    /// to right-click, and a hidden summary has no menu of its own.
    private var viewMenuItem: NSMenuItem?
    private var positionItems: [(item: NSMenuItem, position: AgentTabBarSettings.Position)] = []

    private func addViewMenuItem() {
        guard viewMenuItem == nil,
              let view = NSApp.mainMenu?.items.first(where: { $0.submenu?.title == "View" })?.submenu else { return }
        view.addItem(.separator())

        let positions = NSMenu(title: "Agent Tab Bar")
        let choices: [(String, AgentTabBarSettings.Position)] = [
            ("Top", .top), ("Title Bar", .titleBar), ("Left", .left), ("Native macOS Tabs", .native),
        ]
        for (title, position) in choices {
            let item = NSMenuItem(title: title, action: #selector(choosePosition(_:)), keyEquivalent: "")
            item.target = self
            positions.addItem(item)
            positionItems.append((item, position))
        }
        let positionMenu = NSMenuItem(title: "Agent Tab Bar", action: nil, keyEquivalent: "")
        positionMenu.submenu = positions
        view.addItem(positionMenu)

        let item = NSMenuItem(title: "Show Agents in Menu Bar", action: #selector(toggleSummary), keyEquivalent: "")
        item.target = self
        view.addItem(item)
        viewMenuItem = item
    }

    @objc private func choosePosition(_ sender: NSMenuItem) {
        guard let position = positionItems.first(where: { $0.item === sender })?.position else { return }
        AgentTabBarSettings.shared.position = position
    }

    @objc private func toggleSummary() {
        AgentTabBarSettings.shared.showsMenuBarSummary.toggle()
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
        viewMenuItem?.state = AgentTabBarSettings.shared.showsMenuBarSummary ? .on : .off
        for (item, position) in positionItems {
            item.state = AgentTabBarSettings.shared.position == position ? .on : .off
        }
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
        hide.toolTip = "Turn it back on in View › Show Agents in Menu Bar"
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

/// The image on an agent notification, from the design: Ghostty's `>_` on a
/// dark rounded square with a dot in the state's color. macOS always shows
/// the app icon on a notification, so this goes in as an attachment.
enum AgentNotificationIcon {
    static func attachment(for state: Ghostty.Action.ProgramStatus.State) -> UNNotificationAttachment? {
        guard let png = image(dot: NSColor(AgentTabBarColors.label(for: state))) else { return nil }

        // The system moves the file into its own store, so each notification
        // needs its own copy.
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ghostty-agent-\(UUID().uuidString).png")
        do {
            try png.write(to: url)
            return try UNNotificationAttachment(identifier: "agent-icon", url: url)
        } catch {
            try? FileManager.default.removeItem(at: url)
            return nil
        }
    }

    /// A 40pt square at 3x: the 34pt icon at the top left and the 12pt dot
    /// hanging 3pt past its bottom right corner.
    private static func image(dot: NSColor) -> Data? {
        let scale: CGFloat = 3
        let size: CGFloat = 40
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size * scale), pixelsHigh: Int(size * scale),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) else { return nil }
        // Draw in points: the size has to be set before making the context.
        rep.size = NSSize(width: size, height: size)
        guard let context = NSGraphicsContext(bitmapImageRep: rep) else { return nil }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        defer { NSGraphicsContext.restoreGraphicsState() }

        let icon = NSRect(x: 0.5, y: 6.5, width: 33, height: 33)
        let square = NSBezierPath(roundedRect: icon, xRadius: 9, yRadius: 9)
        NSColor(AgentTabBarColors.notificationIcon).setFill()
        square.fill()
        NSColor(AgentTabBarColors.cardBorder).setStroke()
        square.lineWidth = 1
        square.stroke()

        let text = NSAttributedString(string: ">_", attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 15, weight: .semibold),
            .foregroundColor: NSColor(AgentTabBarColors.notificationIconText),
        ])
        let textSize = text.size()
        text.draw(at: NSPoint(x: icon.midX - textSize.width / 2, y: icon.midY - textSize.height / 2))

        let ring = NSRect(x: 25, y: 3, width: 12, height: 12)
        NSColor(AgentTabBarColors.card).setFill()
        NSBezierPath(ovalIn: ring).fill()
        dot.setFill()
        NSBezierPath(ovalIn: ring.insetBy(dx: 2, dy: 2)).fill()

        return rep.representation(using: .png, properties: [:])
    }
}
