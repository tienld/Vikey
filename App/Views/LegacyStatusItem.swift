import AppKit
import Combine

/// macOS 12 only: the menu bar icon and menu as an NSStatusItem, the same items as MenuBarContent.
@MainActor
final class LegacyStatusItem: NSObject, NSMenuDelegate {
    static let shared = LegacyStatusItem()

    private var item: NSStatusItem?
    private var languageSink: AnyCancellable?

    func install() {
        guard item == nil else { return }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = self
        item.menu = menu
        self.item = item
        languageSink = AppState.shared.$language.sink { [weak item] language in
            item?.button?.image = MenuBarIcon.image(vietnamese: language == 1)
        }
    }

    // rebuilt on every open, so the per-app toggle is for the app in front now
    nonisolated func menuNeedsUpdate(_ menu: NSMenu) {
        MainActor.assumeIsolatedCompat { self.fill(menu) }
    }

    private func fill(_ menu: NSMenu) {
        menu.removeAllItems()
        let state = AppState.shared
        let defaults = UserDefaults.standard
        if state.needsOnboarding {
            menu.addItem(action("Cấp quyền cho Vikey…") { OnboardingWindow.show() })
            menu.addItem(.separator())
        }
        let hotkey = Hotkey(raw: defaults.object(forKey: PrefKey.hotkey) as? Int ?? Hotkey.defaultValue)
        menu.addItem(action("Tiếng Việt   \(hotkey.display)", on: state.language == 1) {
            state.setLanguage(state.language == 1 ? 0 : 1)
        })
        let autoSwitch = defaults.object(forKey: PrefKey.autoSwitch) as? Int ?? 1
        menu.addItem(action("Tự chuyển Anh/Việt", on: autoSwitch == 1) {
            defaults.set(autoSwitch == 1 ? 0 : 1, forKey: PrefKey.autoSwitch)
            Preferences.apply()
        })
        let app = VikeyCore.frontAppName()
        if VikeyCore.frontAppIsExcluded() {
            let excluded = NSMenuItem(title: "\(app): đã loại trừ", action: nil, keyEquivalent: "")
            excluded.isEnabled = false
            menu.addItem(excluded)
        } else {
            let enabled = VikeyCore.autoSwitchEnabledForFrontApp()
            menu.addItem(action("Tự chuyển ở \(app)", on: enabled) {
                VikeyCore.setAutoSwitchForFrontApp(!enabled)
                state.frontAppChanged()
            })
        }
        menu.addItem(.separator())
        menu.addItem(action("Mở Vikey…", key: ",") { Windows.main.show() })
        menu.addItem(.separator())
        menu.addItem(action("Hướng dẫn…") { OnboardingWindow.show() })
        menu.addItem(action("Gửi góp ý…") { Feedback.open() })
        menu.addItem(action("Kiểm tra cập nhật…") { Updater.shared.checkForUpdates() })
        menu.addItem(action("Giới thiệu Vikey") { AboutPanel.show() })
        menu.addItem(action("Thoát Vikey", key: "q") { NSApp.terminate(nil) })
    }

    private func action(_ title: String, on: Bool? = nil, key: String = "", _ run: @escaping @MainActor () -> Void) -> NSMenuItem {
        let item = ClosureMenuItem(title: title, keyEquivalent: key, run: run)
        if let on { item.state = on ? .on : .off }
        return item
    }
}

private final class ClosureMenuItem: NSMenuItem {
    private let run: @MainActor () -> Void

    init(title: String, keyEquivalent: String, run: @escaping @MainActor () -> Void) {
        self.run = run
        super.init(title: title, action: #selector(fire), keyEquivalent: keyEquivalent)
        target = self
    }
    required init(coder: NSCoder) { fatalError("init(coder:) is not used") }

    @objc private func fire() { MainActor.assumeIsolatedCompat { run() } }
}
