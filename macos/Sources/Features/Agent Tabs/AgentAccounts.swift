import Combine
import Foundation
import SwiftUI

/// One account of a coding agent, such as a Claude Code config folder. Its
/// color is the ring around the face of every tab that uses it.
struct AgentAccount: Codable, Identifiable, Equatable {
    /// What the agent reports as `account` in OSC 7501. For Claude Code, the
    /// config folder's name, e.g. ".claude-work".
    let id: String

    /// The name shown in the hover card and menus, e.g. "work".
    var name: String

    /// The ring color, 0xRRGGBB.
    var color: UInt32

    /// The config folder, if known, e.g. "~/.claude-work".
    var folder: String?

    var swiftUIColor: Color { Color(agentHex: color) }
}

/// The accounts the app knows about. Shared by all windows and kept across
/// launches.
///
/// It works without any setup: on first use it adds every `~/.claude*`
/// folder that holds a Claude config, and an account the app hasn't seen
/// yet is added the first time an agent reports it. Each new account gets
/// the next color from `palette`.
final class AgentAccountStore: ObservableObject {
    static let shared = AgentAccountStore()

    /// Ring colors for new accounts, in order. The first two are the design's
    /// Work and Personal colors. None of them is a face's state color.
    static let palette: [UInt32] = [0x8b7cf6, 0x2dd4bf, 0xf472b6, 0xd4a373, 0xa5b4fc, 0xe2e8f0]

    static let colorNames: [(name: String, color: UInt32)] = [
        ("Violet", 0x8b7cf6), ("Teal", 0x2dd4bf), ("Pink", 0xf472b6),
        ("Sand", 0xd4a373), ("Lavender", 0xa5b4fc), ("White", 0xe2e8f0),
    ]

    private static let key = "AgentAccounts"

    @Published private(set) var accounts: [AgentAccount] {
        didSet {
            if let data = try? JSONEncoder().encode(accounts) {
                UserDefaults.ghostty.set(data, forKey: Self.key)
            }
            AgentTabBarModel.setNeedsRefresh()
        }
    }

    private init() {
        if let data = UserDefaults.ghostty.data(forKey: Self.key),
           let saved = try? JSONDecoder().decode([AgentAccount].self, from: data) {
            accounts = saved
        } else {
            accounts = []
            for folder in Self.claudeConfigFolders() {
                add(id: folder.lastPathComponent, folder: folder.path)
            }
        }
    }

    /// The account with this id, added if it's new.
    func account(for id: String) -> AgentAccount {
        if let account = accounts.first(where: { $0.id == id }) { return account }
        return add(id: id, folder: Self.claudeFolder(named: id)?.path)
    }

    func setColor(_ color: UInt32, for id: String) {
        guard let index = accounts.firstIndex(where: { $0.id == id }) else { return }
        accounts[index].color = color
    }

    func rename(_ id: String, to name: String) {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, let index = accounts.firstIndex(where: { $0.id == id }) else { return }
        accounts[index].name = name
    }

    func remove(_ id: String) {
        accounts.removeAll { $0.id == id }
    }

    /// Add a config folder the user picked. Its id is the folder's name,
    /// which is what the hook reports. Returns the existing account if the
    /// folder is already known.
    @discardableResult
    func add(folder: URL) -> AgentAccount {
        let id = folder.lastPathComponent
        if let index = accounts.firstIndex(where: { $0.id == id }) {
            accounts[index].folder = folder.path
            return accounts[index]
        }
        return add(id: id, folder: folder.path)
    }

    @discardableResult
    private func add(id: String, folder: String?) -> AgentAccount {
        let used = Set(accounts.map(\.color))
        let color = Self.palette.first { !used.contains($0) }
            ?? Self.palette[accounts.count % Self.palette.count]
        let account = AgentAccount(id: id, name: Self.name(for: id), color: color, folder: folder)
        accounts.append(account)
        return account
    }

    /// A short name from a folder name: ".claude" is "default",
    /// ".claude-work" is "work".
    static func name(for id: String) -> String {
        if id == ".claude" { return "default" }
        if id.hasPrefix(".claude-") { return String(id.dropFirst(".claude-".count)) }
        return id
    }

    /// `~/.claude` and every `~/.claude-*` folder that holds a Claude config.
    static func claudeConfigFolders() -> [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let names = (try? FileManager.default.contentsOfDirectory(atPath: home.path)) ?? []
        return names
            .filter { $0 == ".claude" || $0.hasPrefix(".claude-") }
            .sorted { ($0 == ".claude" ? "" : $0) < ($1 == ".claude" ? "" : $1) }
            .compactMap { claudeFolder(named: $0) }
    }

    /// `~/<name>` if it is a folder that holds a Claude config.
    private static func claudeFolder(named name: String) -> URL? {
        let url = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(name)
        let fm = FileManager.default
        var isDirectory: ObjCBool = false
        guard fm.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else { return nil }
        let markers = ["settings.json", ".claude.json", "projects"]
        guard markers.contains(where: { fm.fileExists(atPath: url.appendingPathComponent($0).path) }) else { return nil }
        return url
    }
}
