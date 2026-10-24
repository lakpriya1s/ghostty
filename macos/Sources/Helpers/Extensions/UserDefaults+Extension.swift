import Foundation

extension UserDefaults {
    static var ghosttySuite: String? {
        #if DEBUG
        ProcessInfo.processInfo.environment["GHOSTTY_USER_DEFAULTS_SUITE"]
        #else
        nil
        #endif
    }

    static var ghostty: UserDefaults {
        ghosttySuite.flatMap(UserDefaults.init(suiteName:)) ?? .standard
    }

    /// KinTerm used Ghostty's bundle ID before it was renamed. Its agent
    /// settings and accounts live in that ID's defaults, so copy them over
    /// once, without overwriting anything set since.
    static func migrateAgentSettingsFromGhostty() {
        let defaults = UserDefaults.ghostty
        let migratedKey = "AgentSettingsMigratedFromGhostty"
        guard !defaults.bool(forKey: migratedKey) else { return }
        defaults.set(true, forKey: migratedKey)

        #if DEBUG
        let oldSuite = "com.mitchellh.ghostty.debug"
        #else
        let oldSuite = "com.mitchellh.ghostty"
        #endif
        guard let old = UserDefaults(suiteName: oldSuite)?.persistentDomain(forName: oldSuite) else { return }
        for (key, value) in old where key.hasPrefix("Agent") && defaults.object(forKey: key) == nil {
            defaults.set(value, forKey: key)
        }
    }
}
