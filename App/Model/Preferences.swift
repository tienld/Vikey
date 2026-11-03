import Foundation
import ServiceManagement

/// UserDefaults keys shared with the keyboard core (VikeyCore.mm reads them in VKLoadSettings).
enum PrefKey {
    static let spelling = "Spelling"
    static let restoreIfInvalid = "RestoreIfInvalidWord"
    static let modernOrthography = "ModernOrthography"
    static let useMacro = "UseMacro"
    static let macroInEnglish = "UseMacroInEnglishMode"
    static let autoCapsMacro = "vAutoCapsMacro"
    static let smartSwitch = "UseSmartSwitchKey"
    static let smartSwitchPerSite = "SmartSwitchPerSite"
    static let autoSwitch = "AutoSwitchByTyping"
    static let pauseAfterManual = "PauseAutoAfterManual"
    static let typingLogKeys = "TypingLogKeys"
    static let typingLogEnabled = "TypingLogEnabled"
    static let hotkey = "SwitchKeyStatus"
    static let teencode = "Teencode"
    static let telexStyle = "TelexStyle"   // D56: 0 Telex, 1 Simple Telex 1, 2 Simple Telex 2
    static let excludedApps = "ExcludedApps"   // bundle ids Vikey stays out of (array of String)
    static let mainTab = "MainWindowTab"   // the main window's tab
}

/// Defaults every setting starts with (registered so @AppStorage and the core agree).
enum Preferences {
    static func register() {
        UserDefaults.standard.register(defaults: [
            PrefKey.spelling: 1, PrefKey.restoreIfInvalid: 1, PrefKey.modernOrthography: 1,
            PrefKey.useMacro: 1, PrefKey.macroInEnglish: 1, PrefKey.autoCapsMacro: 0,
            PrefKey.smartSwitch: 1, PrefKey.smartSwitchPerSite: false, PrefKey.autoSwitch: 1, PrefKey.pauseAfterManual: 1,
            PrefKey.typingLogKeys: 1, PrefKey.typingLogEnabled: 0, PrefKey.hotkey: Hotkey.defaultValue,
            PrefKey.teencode: 1, PrefKey.telexStyle: 0, PrefKey.mainTab: "general",
            PrefKey.excludedApps: ExcludedApps.defaults,
        ])
    }

    /// Call after changing a setting so the keyboard core picks it up.
    static func apply() { VikeyCore.reloadSettings() }
}

enum LaunchAtLogin {
    static var isEnabled: Bool {
        if #available(macOS 13.0, *) { return SMAppService.mainApp.status == .enabled }
        return FileManager.default.fileExists(atPath: agentURL.path)
    }
    static func set(_ on: Bool) {
        do {
            if #available(macOS 13.0, *) {
                if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            } else if on {
                // macOS 12 has no SMAppService: a LaunchAgent that opens Vikey at login
                let agent: [String: Any] = ["Label": agentLabel, "ProgramArguments": ["/usr/bin/open", Bundle.main.bundlePath], "RunAtLoad": true]
                try FileManager.default.createDirectory(at: agentURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                try PropertyListSerialization.data(fromPropertyList: agent, format: .xml, options: 0).write(to: agentURL)
            } else if FileManager.default.fileExists(atPath: agentURL.path) {
                try FileManager.default.removeItem(at: agentURL)
            }
        } catch {
            NSLog("Vikey: launch at login change failed: \(error)")
        }
    }
    private static let agentLabel = "com.devuap.vikey.login"
    private static var agentURL: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/LaunchAgents/\(agentLabel).plist")
    }
}
