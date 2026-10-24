import AppKit

/// A short sound when an agent you're not looking at needs you, finishes or
/// stops with an error, so you can tell which without looking. Each state has
/// its own macOS system sound, chosen in View › Agent Sounds. They play
/// whether or not desktop notifications are on. Also in the tab bar's
/// right-click menu and the Setup Assistant.
final class AgentSounds: NSObject, ObservableObject, NSMenuDelegate {
    static let shared = AgentSounds()

    typealias State = Ghostty.Action.ProgramStatus.State

    /// The states that make a sound, in menu order.
    static let states: [State] = [.blocked, .done, .error]

    /// The sounds in /System/Library/Sounds.
    static let choices = [
        "Basso", "Blow", "Bottle", "Frog", "Funk", "Glass", "Hero",
        "Morse", "Ping", "Pop", "Purr", "Sosumi", "Submarine", "Tink",
    ]

    private static let enabledKey = "AgentSoundsEnabled"
    private static let soundsKey = "AgentSounds"

    /// Distinct by default: a light ping when it needs you, a chime when it's
    /// done, a low thud on an error.
    private static let defaults: [State: String] = [.blocked: "Ping", .done: "Glass", .error: "Basso"]

    @Published var isEnabled: Bool {
        didSet { UserDefaults.ghostty.set(isEnabled, forKey: Self.enabledKey) }
    }

    override private init() {
        isEnabled = UserDefaults.ghostty.object(forKey: Self.enabledKey) as? Bool ?? true
        super.init()
    }

    /// The sound for a state, or nil for none.
    func sound(for state: State) -> String? {
        guard let key = Self.key(for: state) else { return nil }
        let chosen = UserDefaults.ghostty.dictionary(forKey: Self.soundsKey)?[key] as? String
        let name = chosen ?? Self.defaults[state]
        return name?.isEmpty == false ? name : nil
    }

    func setSound(_ name: String?, for state: State) {
        guard let key = Self.key(for: state) else { return }
        var sounds = UserDefaults.ghostty.dictionary(forKey: Self.soundsKey) ?? [:]
        sounds[key] = name ?? ""
        objectWillChange.send()
        UserDefaults.ghostty.set(sounds, forKey: Self.soundsKey)
    }

    /// Play a state's sound now, to hear what it is.
    func preview(_ state: State) {
        if let name = sound(for: state) { play(name) }
    }

    /// When several agents change at once, play one sound, not a pile.
    private var lastPlayed = Date.distantPast

    func play(for state: State) {
        guard isEnabled, let name = sound(for: state) else { return }
        guard Date().timeIntervalSince(lastPlayed) > 0.5 else { return }
        lastPlayed = Date()
        play(name)
    }

    private func play(_ name: String) {
        guard let sound = NSSound(named: NSSound.Name(name)) else { return }
        sound.stop()
        sound.play()
    }

    private static func key(for state: State) -> String? {
        switch state {
        case .blocked: return "blocked"
        case .done: return "done"
        case .error: return "error"
        default: return nil
        }
    }

    static func label(for state: State) -> String {
        switch state {
        case .blocked: return "Needs You"
        case .done: return "Finished"
        case .error: return "Error"
        default: return ""
        }
    }

    // MARK: Menu

    /// "Agent Sounds" for the View menu: Play Sounds, then a sound per state.
    /// Choosing a sound plays it.
    func menuItem() -> NSMenuItem {
        let menu = NSMenu(title: "Agent Sounds")
        menu.delegate = self
        menu.autoenablesItems = false

        let toggle = NSMenuItem(title: "Play Sounds", action: #selector(toggleEnabled(_:)), keyEquivalent: "")
        toggle.target = self
        menu.addItem(toggle)
        menu.addItem(.separator())

        for state in Self.states {
            let sounds = NSMenu(title: Self.label(for: state))
            sounds.delegate = self
            for name in [nil] + Self.choices {
                let item = NSMenuItem(title: name ?? "None", action: #selector(chooseSound(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = SoundChoice(state: state, name: name)
                sounds.addItem(item)
                if name == nil { sounds.addItem(.separator()) }
            }
            let item = NSMenuItem(title: Self.label(for: state), action: nil, keyEquivalent: "")
            item.submenu = sounds
            menu.addItem(item)
        }

        let item = NSMenuItem(title: "Agent Sounds", action: nil, keyEquivalent: "")
        item.submenu = menu
        return item
    }

    private final class SoundChoice: NSObject {
        let state: State
        let name: String?

        init(state: State, name: String?) {
            self.state = state
            self.name = name
        }
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        for item in menu.items {
            if item.action == #selector(toggleEnabled(_:)) {
                item.state = isEnabled ? .on : .off
            } else if let choice = item.representedObject as? SoundChoice {
                item.state = sound(for: choice.state) == choice.name ? .on : .off
            } else if item.submenu != nil {
                item.isEnabled = isEnabled
            }
        }
    }

    @objc private func toggleEnabled(_ sender: NSMenuItem) {
        isEnabled.toggle()
    }

    @objc private func chooseSound(_ sender: NSMenuItem) {
        guard let choice = sender.representedObject as? SoundChoice else { return }
        setSound(choice.name, for: choice.state)
        if let name = choice.name { play(name) }
    }
}
