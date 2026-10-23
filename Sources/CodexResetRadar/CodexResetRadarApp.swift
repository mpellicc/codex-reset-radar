import AppIntents
import AppKit
import SwiftUI

@main
struct CodexResetRadarApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    // The menu bar item is an NSStatusItem (see MenuBarItem), so SwiftUI only needs a scene that shows nothing.
    var body: some Scene {
        Settings { EmptyView() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = RadarModel()
    private let updater = Updater()
    private var menuBarItem: MenuBarItem?

    override init() {
        super.init()
        // The Shortcuts action reads the same model the panel shows (NextResetIntent).
        let model = self.model
        AppDependencyManager.shared.add(dependency: model)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarItem = MenuBarItem(model: model, updater: updater)
    }
}
