import AppKit
import Combine
import SwiftUI

// The face tab bar. See scope/designs/01-window-face-tabs.md for the design
// this matches.

/// The design's colors for the tab bar and hover card.
enum AgentTabBarColors {
    static let bar = Color(agentHex: 0x22242a)
    static let border = Color(agentHex: 0x2e3038)
    static let selected = Color(agentHex: 0x363944)
    static let hovered = Color(agentHex: 0x2c2e35)
    static let plusBorder = Color(agentHex: 0x4a4e59)
    static let plusBorderHovered = Color(agentHex: 0x8a8f99)
    static let plusText = Color(agentHex: 0xa8adb7)
    static let plusTextHovered = Color(agentHex: 0xf1f2f4)

    static let card = Color(agentHex: 0x24262d)
    static let cardBorder = Color(agentHex: 0x3a3d47)
    static let cardTitle = Color(agentHex: 0xf1f2f4)
    static let cardText = Color(agentHex: 0xc2c6cf)
    static let cardMuted = Color(agentHex: 0x8a8f99)
    static let shellAccount = Color(agentHex: 0x4a4e59)

    /// The state label's color in the hover card.
    static func label(for state: Ghostty.Action.ProgramStatus.State?) -> Color {
        switch state {
        case .working: return Color(agentHex: 0x7db4ff)
        case .blocked: return Color(agentHex: 0xf5a524)
        case .done: return Color(agentHex: 0x3fb950)
        case .error: return Color(agentHex: 0xff7b72)
        case .idle, .clear, nil: return Color(agentHex: 0xa8adb7)
        }
    }
}

/// Where the agent tab bar is shown and how big its faces are. Shared by all
/// windows and kept across launches.
final class AgentTabBarSettings: ObservableObject {
    static let shared = AgentTabBarSettings()

    enum Position: String, CaseIterable {
        /// A row of faces above the terminal.
        case top

        /// A column of faces to the left of the terminal.
        case left

        /// The standard macOS tab bar, with a small face on each tab.
        case native
    }

    enum FaceSize: String, CaseIterable {
        case small
        case medium
        case large

        /// The design's scale for each size, applied to a 40pt face.
        var scale: CGFloat {
            switch self {
            case .small: return 0.8
            case .medium: return 1
            case .large: return 1.25
            }
        }

        var label: String {
            switch self {
            case .small: return "S"
            case .medium: return "M"
            case .large: return "L"
            }
        }
    }

    private static let positionKey = "AgentTabBarPosition"
    private static let faceSizeKey = "AgentTabBarFaceSize"

    @Published var position: Position {
        didSet {
            UserDefaults.ghostty.set(position.rawValue, forKey: Self.positionKey)
            AgentTabBarModel.setNeedsRefresh()
        }
    }

    @Published var faceSize: FaceSize {
        didSet { UserDefaults.ghostty.set(faceSize.rawValue, forKey: Self.faceSizeKey) }
    }

    /// Whether our own tab bar replaces the native one.
    var replacesNativeTabBar: Bool { position != .native }

    private init() {
        position = UserDefaults.ghostty.string(forKey: Self.positionKey)
            .flatMap(Position.init(rawValue:)) ?? .top
        faceSize = UserDefaults.ghostty.string(forKey: Self.faceSizeKey)
            .flatMap(FaceSize.init(rawValue:)) ?? .medium
    }
}

/// One tab as shown in the agent tab bar.
struct AgentTab: Identifiable, Equatable {
    let id: ObjectIdentifier
    let title: String
    let status: Ghostty.Action.ProgramStatus?
    let isSelected: Bool

    /// The keyboard shortcut that selects this tab, e.g. "⌘1".
    let shortcut: String?

    /// The focused terminal's working directory.
    let pwd: String?

    /// When the tab was opened.
    let openedAt: Date
}

/// The tabs of one window's tab group, kept up to date for the agent tab bar.
///
/// Tabs are still native macOS window tabs, so everything that works with tabs
/// (shortcuts, menus, dragging windows together, restoring) keeps working. This
/// only replaces how they're drawn.
final class AgentTabBarModel: ObservableObject {
    @Published private(set) var tabs: [AgentTab] = []

    private weak var controller: BaseTerminalController?
    private var windows: [ObjectIdentifier: Weak<NSWindow>] = [:]
    private var cancellables: Set<AnyCancellable> = []

    /// Anything that changes what any tab bar shows calls `setNeedsRefresh`,
    /// and every tab bar refreshes. There are only ever a handful of tabs.
    private static let changes = PassthroughSubject<Void, Never>()

    static func setNeedsRefresh() {
        changes.send()
    }

    init(controller: BaseTerminalController) {
        self.controller = controller

        let center = NotificationCenter.default
        let windowChanges = [
            NSWindow.didBecomeKeyNotification,
            NSWindow.didBecomeMainNotification,
            NSWindow.willCloseNotification,
        ].map { center.publisher(for: $0).map { _ in () }.eraseToAnyPublisher() }

        Publishers.MergeMany(windowChanges + [Self.changes.eraseToAnyPublisher()])
            .debounce(for: .milliseconds(20), scheduler: RunLoop.main)
            .sink { [weak self] in self?.refresh() }
            .store(in: &cancellables)
    }

    var window: NSWindow? { controller?.window }

    func refresh() {
        guard let window = controller?.window else { return }

        // A window that closes is still in its tab group while it closes.
        let all = (window.tabbedWindows ?? [window]).filter { $0.isVisible || $0 === window }
        let selected = window.tabGroup?.selectedWindow ?? window
        windows = Dictionary(uniqueKeysWithValues: all.map { (ObjectIdentifier($0), Weak($0)) })
        let newTabs = all.map { tabWindow in
            let tabController = tabWindow.windowController as? BaseTerminalController
            return AgentTab(
                id: ObjectIdentifier(tabWindow),
                title: tabWindow.title,
                status: tabController?.programStatus,
                isSelected: tabWindow === selected,
                shortcut: (tabWindow as? TerminalWindow)?.keyEquivalent,
                pwd: tabController?.focusedSurface?.pwd,
                openedAt: tabController?.createdAt ?? Date()
            )
        }

        if newTabs != tabs { tabs = newTabs }

        (window as? TerminalWindow)?.syncNativeTabBarVisibility()
    }

    func select(_ tab: AgentTab) {
        guard let window = windows[tab.id]?.value else { return }
        window.tabGroup?.selectedWindow = window
        window.makeKeyAndOrderFront(nil)
    }

    func close(_ tab: AgentTab) {
        guard let window = windows[tab.id]?.value else { return }
        (window.windowController as? TerminalController)?.closeTab(nil)
    }

    func newTab() {
        (controller as? TerminalController)?.newTab(nil)
    }
}

/// Puts the agent tab bar above or beside the terminal content.
struct AgentTabBarContainer<Content: View>: View {
    let model: AgentTabBarModel?
    @ObservedObject private var settings = AgentTabBarSettings.shared
    @ViewBuilder let content: Content

    var body: some View {
        if let model {
            switch settings.position {
            case .top:
                VStack(spacing: 0) {
                    AgentTabBar(model: model, vertical: false)
                    VStack(spacing: 0) { content }
                }
            case .left:
                HStack(spacing: 0) {
                    AgentTabBar(model: model, vertical: true)
                    VStack(spacing: 0) { content }
                }
            case .native:
                VStack(spacing: 0) { content }
            }
        } else {
            VStack(spacing: 0) { content }
        }
    }
}

/// A row or column of faces, one per tab, followed by a new tab button.
struct AgentTabBar: View {
    @ObservedObject var model: AgentTabBarModel
    @ObservedObject private var settings = AgentTabBarSettings.shared
    let vertical: Bool

    private var scale: CGFloat { settings.faceSize.scale }

    /// The face, scaled from the design's 40pt.
    private var faceSize: CGFloat { (40 * scale).rounded() }

    /// The round slot a face sits in: the face plus room for its rings.
    private var slot: CGFloat { (40 * scale + 18).rounded() }

    /// The tab button: the slot plus 5pt padding on each side.
    private var button: CGFloat { slot + 10 }

    var body: some View {
        let layout = vertical
            ? AnyLayout(VStackLayout(spacing: 6))
            : AnyLayout(HStackLayout(spacing: 6))

        ScrollView(vertical ? .vertical : .horizontal, showsIndicators: false) {
            layout {
                ForEach(model.tabs) { tab in
                    AgentTabButton(
                        model: model,
                        tab: tab,
                        faceSize: faceSize,
                        slot: slot,
                        button: button,
                        vertical: vertical)
                }

                AgentNewTabButton(size: (slot * 0.7).rounded(), action: model.newTab)
                    .padding(vertical ? .top : .leading, 4)
            }
            .padding(vertical
                ? EdgeInsets(top: 12, leading: 8, bottom: 12, trailing: 8)
                : EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10))
            .frame(
                maxWidth: vertical ? .infinity : nil,
                maxHeight: vertical ? nil : .infinity,
                alignment: vertical ? .top : .leading)
        }
        .frame(
            width: vertical ? button + 16 : nil,
            height: vertical ? nil : button + 16)
        .background(AgentTabBarColors.bar)
        .overlay(alignment: vertical ? .trailing : .bottom) {
            Rectangle()
                .fill(AgentTabBarColors.border)
                .frame(width: vertical ? 1 : nil, height: vertical ? nil : 1)
        }
        .contextMenu { AgentTabBarMenu() }
        .onAppear { model.refresh() }
    }
}

/// The options for the tab bar itself.
struct AgentTabBarMenu: View {
    @ObservedObject private var settings = AgentTabBarSettings.shared

    var body: some View {
        Picker("Tab Bar", selection: $settings.position) {
            Text("Top").tag(AgentTabBarSettings.Position.top)
            Text("Left").tag(AgentTabBarSettings.Position.left)
            Text("Native macOS Tabs").tag(AgentTabBarSettings.Position.native)
        }
        Picker("Face Size", selection: $settings.faceSize) {
            ForEach(AgentTabBarSettings.FaceSize.allCases, id: \.self) { size in
                Text(size.label).tag(size)
            }
        }
    }
}

/// The dashed round "+" button at the end of the bar.
private struct AgentNewTabButton: View {
    let size: CGFloat
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Text("+")
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(hovering ? AgentTabBarColors.plusTextHovered : AgentTabBarColors.plusText)
                .frame(width: size, height: size)
                .overlay(
                    Circle().strokeBorder(
                        hovering ? AgentTabBarColors.plusBorderHovered : AgentTabBarColors.plusBorder,
                        style: StrokeStyle(lineWidth: 1.5, dash: [3, 3])))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .accessibilityLabel("New Tab")
    }
}

/// One tab: its face, a highlight when selected or hovered, and a details card
/// on hover.
private struct AgentTabButton: View {
    @ObservedObject var model: AgentTabBarModel
    let tab: AgentTab
    let faceSize: CGFloat
    let slot: CGFloat
    let button: CGFloat
    let vertical: Bool

    @State private var hovering = false
    @State private var frame: CGRect = .zero

    var body: some View {
        Button {
            AgentTabCardPanel.shared.hide()
            model.select(tab)
        } label: {
            ZStack {
                if let status = tab.status, status.state != .clear {
                    AgentFaceView(state: status.state, size: faceSize)
                } else {
                    ShellGlyphView(size: faceSize)
                }
            }
            .frame(width: slot, height: slot)
            .overlay(
                // The account ring. Accounts come later (task 08), so for
                // now it is always transparent, like the design's shell tabs.
                Circle().strokeBorder(Color.clear, lineWidth: 2))
            .frame(width: button, height: button)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(tab.isSelected
                        ? AgentTabBarColors.selected
                        : hovering ? AgentTabBarColors.hovered : Color.clear))
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .background(GeometryReader { geometry in
            Color.clear
                .onAppear { frame = geometry.frame(in: .global) }
                .onChange(of: geometry.frame(in: .global)) { frame = $0 }
        })
        .onHover { isHovering in
            hovering = isHovering
            if isHovering {
                // Wait a moment so moving across the bar doesn't flash cards.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    guard hovering, let window = model.window else { return }
                    AgentTabCardPanel.shared.show(
                        AgentTabCard(tab: tab),
                        below: !vertical,
                        anchor: frame,
                        in: window)
                }
            } else {
                AgentTabCardPanel.shared.hide()
            }
        }
        .onChange(of: tab) { newTab in
            // Keep an open card up to date while the agent works.
            guard hovering, let window = model.window else { return }
            AgentTabCardPanel.shared.update(AgentTabCard(tab: newTab), in: window)
        }
        .contextMenu {
            Button("Close Tab") { model.close(tab) }
            Divider()
            AgentTabBarMenu()
        }
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityAddTraits(tab.isSelected ? [.isSelected] : [])
    }

    private var accessibilityLabel: String {
        if let status = tab.status, status.state != .clear {
            return "\(tab.title), \(status.stateLabel)"
        }
        return tab.title
    }
}

/// The details shown when hovering a tab.
private struct AgentTabCard: View {
    let tab: AgentTab

    private var status: Ghostty.Action.ProgramStatus? {
        guard let status = tab.status, status.state != .clear else { return nil }
        return status
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(tab.title.isEmpty ? "Terminal" : tab.title)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundColor(AgentTabBarColors.cardTitle)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 0)
                if let shortcut = tab.shortcut {
                    Text(shortcut)
                        .font(.system(size: 12.5))
                        .foregroundColor(AgentTabBarColors.cardMuted)
                }
            }

            TimelineView(.periodic(from: .now, by: 1)) { context in
                (Text(status?.stateLabel ?? "Shell")
                    .foregroundColor(AgentTabBarColors.label(for: status?.state))
                    .fontWeight(.semibold)
                 + Text(" · \(elapsed(now: context.date))")
                    .foregroundColor(AgentTabBarColors.cardMuted))
                    .font(.system(size: 12.5))
            }
            .padding(.top, 2)

            Text(status?.msg ?? (status == nil ? "Plain shell, no agent" : status!.appDisplayName))
                .font(.system(size: 12.5))
                .foregroundColor(AgentTabBarColors.cardText)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)

            HStack(spacing: 6) {
                // The account's color. Accounts come later (task 08).
                Circle()
                    .fill(AgentTabBarColors.shellAccount)
                    .frame(width: 8, height: 8)
                Text(footer)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .font(.system(size: 11.5))
            .foregroundColor(AgentTabBarColors.cardMuted)
            .padding(.top, 10)
        }
        .padding(14)
        .frame(width: 300, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AgentTabBarColors.card))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(AgentTabBarColors.cardBorder, lineWidth: 1))
    }

    /// "Claude Code · ~/code/api", or "No account · ~" for a shell.
    private var footer: String {
        let pwd = tab.pwd.map { ($0 as NSString).abbreviatingWithTildeInPath }
        guard let status else { return ["No account", pwd].compactMap { $0 }.joined(separator: " · ") }
        return [status.appDisplayName, pwd ?? status.title].compactMap { $0 }.joined(separator: " · ")
    }

    /// The time part of the state line, worded like the design:
    /// "2m 14s" working, "waiting 1m", "3m ago" done, "idle 12m", "open 40m".
    private func elapsed(now: Date) -> String {
        guard let status else { return "open \(Self.duration(from: tab.openedAt, to: now, seconds: false))" }
        let short = Self.duration(from: status.since, to: now, seconds: false)
        switch status.state {
        case .working: return Self.duration(from: status.since, to: now, seconds: true)
        case .blocked: return "waiting \(short)"
        case .done, .error: return "\(short) ago"
        case .idle, .clear: return "idle \(short)"
        }
    }

    private static func duration(from start: Date, to end: Date, seconds showSeconds: Bool) -> String {
        let total = max(0, Int(end.timeIntervalSince(start)))
        let hours = total / 3600, minutes = (total % 3600) / 60, seconds = total % 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        if minutes > 0 { return showSeconds ? "\(minutes)m \(seconds)s" : "\(minutes)m" }
        return "\(seconds)s"
    }
}

/// A floating panel that shows a tab's hover card next to its face. It's a
/// separate borderless window so the card can draw over the terminal, and it
/// never becomes key, so the terminal keeps keyboard focus.
final class AgentTabCardPanel {
    static let shared = AgentTabCardPanel()

    private lazy var panel: NSPanel = {
        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = true
        return panel
    }()

    private weak var parent: NSWindow?
    private var below = true
    private var anchor: CGRect = .zero

    /// Show a card under (or to the right of) `anchor`, a frame in the
    /// window's SwiftUI global coordinates.
    func show<Card: View>(_ card: Card, below: Bool, anchor: CGRect, in window: NSWindow) {
        self.below = below
        self.anchor = anchor
        update(card, in: window)
    }

    func update<Card: View>(_ card: Card, in window: NSWindow) {
        let host = NSHostingView(rootView: card.fixedSize())
        host.frame.size = host.fittingSize
        panel.contentView = host

        guard let contentView = window.contentView else { return }
        // SwiftUI's global coordinates start at the top left of the content
        // view; AppKit's start at the bottom left.
        let flipped = NSRect(
            x: anchor.minX,
            y: contentView.bounds.height - anchor.maxY,
            width: anchor.width,
            height: anchor.height)
        let face = window.convertToScreen(contentView.convert(flipped, to: nil))
        let size = host.fittingSize
        var origin = below
            ? NSPoint(x: face.minX, y: face.minY - 8 - size.height)
            : NSPoint(x: face.maxX + 10, y: face.maxY - size.height)

        // Keep the card on screen.
        if let screen = window.screen?.visibleFrame {
            origin.x = min(max(origin.x, screen.minX + 4), screen.maxX - size.width - 4)
            origin.y = max(origin.y, screen.minY + 4)
        }

        panel.setFrame(NSRect(origin: origin, size: size), display: true)
        if parent !== window {
            parent?.removeChildWindow(panel)
            window.addChildWindow(panel, ordered: .above)
            parent = window
        }
        panel.orderFront(nil)
        panel.invalidateShadow()
    }

    func hide() {
        parent?.removeChildWindow(panel)
        parent = nil
        panel.orderOut(nil)
    }
}
