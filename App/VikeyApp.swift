import SwiftUI

/// MenuBarExtra needs macOS 13; on macOS 12 the menu bar icon is an NSStatusItem (LegacyStatusItem).
@main
enum VikeyMain {
    static func main() {
        if #available(macOS 13.0, *) { VikeyApp.main() } else { LegacyVikeyApp.main() }
    }
}

@available(macOS 13.0, *)
struct VikeyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var state = AppState.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent()
                .environmentObject(state)
        } label: {
            Image(nsImage: MenuBarIcon.image(vietnamese: state.language == 1))
        }
        .commands { VikeyCommands() }

    }
}

/// macOS 12: no scene of its own (the windows are NSWindows), only the app menu.
struct LegacyVikeyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
            .commands { VikeyCommands() }
    }
}

@MainActor
struct VikeyCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("Giới thiệu về Vikey") { AboutPanel.show() }   // with the credits
            Button("Ghi nhận…") { Windows.acknowledgements.show() }
            Button("Kiểm tra cập nhật…") { Updater.shared.checkForUpdates() }
            Divider()
            DebugMenu()
        }
        CommandGroup(replacing: .appSettings) {
            Button("Mở Vikey…") { Windows.main.show() }
                .keyboardShortcut(",")
        }
    }
}
