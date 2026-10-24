import Foundation

/// Installs KinTerm's Claude Code status hook, the same way as
/// `agents/claude-code/install.sh` but without needing `jq`: the hook (bundled
/// in the app) is copied to `~/.config/kinterm/agents/claude-code/`, and a
/// Claude config folder's `settings.json` runs it for every event it reports.
enum AgentHookInstaller {
    enum InstallError: LocalizedError {
        case hookMissing
        case unreadableSettings(URL)

        var errorDescription: String? {
            switch self {
            case .hookMissing:
                return "This copy of KinTerm doesn't include the Claude Code hook."
            case .unreadableSettings(let url):
                return "\((url.path as NSString).abbreviatingWithTildeInPath) isn't valid JSON, so it was left alone."
            }
        }
    }

    private static let hookName = "kinterm-agent-status"

    /// Hook entries from before the rename are replaced too.
    private static let ourHooks = ["kinterm-agent-status", "ghostty-agent-status"]

    /// The Claude Code events the hook reports, with their matcher.
    private static let events: [(name: String, matcher: String?)] = [
        ("SessionStart", nil), ("UserPromptSubmit", nil), ("PreToolUse", "*"), ("PostToolUse", "*"),
        ("Notification", nil), ("Stop", nil), ("StopFailure", nil), ("SessionEnd", nil),
    ]

    /// Where the hook is installed, which the settings point at.
    static var hookURL: URL {
        let env = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"].flatMap { $0.isEmpty ? nil : $0 }
        let config = env.map { URL(fileURLWithPath: $0) }
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".config")
        return config.appendingPathComponent("kinterm/agents/claude-code/\(hookName)")
    }

    /// Whether a Claude config folder's settings already run the hook.
    static func isInstalled(in folder: URL) -> Bool {
        guard let data = try? Data(contentsOf: folder.appendingPathComponent("settings.json")),
              let text = String(data: data, encoding: .utf8) else { return false }
        return text.contains(hookName)
    }

    /// Copy the hook into place and add it to `folder`'s settings. Before
    /// the first change, the settings are copied to
    /// `settings.json.before-kinterm`. Installing twice is safe.
    static func install(into folder: URL) throws {
        try installHook()

        let fm = FileManager.default
        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        let settingsURL = folder.appendingPathComponent("settings.json")
        var settings: [String: Any] = [:]
        if let data = try? Data(contentsOf: settingsURL), !data.isEmpty {
            guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw InstallError.unreadableSettings(settingsURL)
            }
            settings = object
            let backup = folder.appendingPathComponent("settings.json.before-kinterm")
            if !fm.fileExists(atPath: backup.path) {
                try data.write(to: backup)
            }
        }

        var hooks = settings["hooks"] as? [String: Any] ?? [:]
        for event in events {
            var entries = (hooks[event.name] as? [[String: Any]] ?? []).filter { !isOurs($0) }
            var entry: [String: Any] = ["hooks": [["type": "command", "command": hookURL.path, "timeout": 5]]]
            if let matcher = event.matcher { entry["matcher"] = matcher }
            entries.append(entry)
            hooks[event.name] = entries
        }
        settings["hooks"] = hooks

        let data = try JSONSerialization.data(
            withJSONObject: settings, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        try data.write(to: settingsURL, options: .atomic)
    }

    /// Copy the bundled hook to `hookURL`, replacing an older copy.
    private static func installHook() throws {
        guard let bundled = Bundle.main.url(forResource: hookName, withExtension: nil) else {
            throw InstallError.hookMissing
        }
        let fm = FileManager.default
        try fm.createDirectory(at: hookURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        if fm.fileExists(atPath: hookURL.path) {
            try fm.removeItem(at: hookURL)
        }
        try fm.copyItem(at: bundled, to: hookURL)
        try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: hookURL.path)
    }

    /// A settings hook entry that runs our hook (or the one from before the
    /// rename).
    private static func isOurs(_ entry: [String: Any]) -> Bool {
        let commands = (entry["hooks"] as? [[String: Any]] ?? []).compactMap { $0["command"] as? String }
        return commands.contains { command in ourHooks.contains { command.contains($0) } }
    }
}
