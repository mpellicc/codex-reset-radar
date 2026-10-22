import AppKit
import RadarCore
import UserNotifications
import os

/// Reads the app's notification settings from the system and says whether they are turned off.
/// It re-reads whenever the app becomes active or a window becomes key (the panel opening),
/// so the answer follows changes made in System Settings without a restart.
@MainActor
final class NotificationAccessMonitor: ObservableObject {
    @Published private(set) var isOff = false

    private var observers: [NSObjectProtocol] = []

    init() {
        check(reason: "launch")

        for name in [NSApplication.didBecomeActiveNotification, NSWindow.didBecomeKeyNotification] {
            observers.append(
                NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                    Task { @MainActor in self?.check(reason: "app or window became active") }
                })
        }
    }

    func check(reason: String) {
        // Called back on a background queue, so the closure must not be main-actor isolated.
        UNUserNotificationCenter.current().getNotificationSettings { @Sendable [weak self] settings in
            let access = NotificationAccess(settings)
            Log.notify.notice(
                "notification settings (\(reason, privacy: .public)): authorization \(String(describing: access.authorization), privacy: .public), alerts \(String(describing: access.alerts), privacy: .public), warning \(access.isOff ? "shown" : "hidden", privacy: .public)"
            )
            Task { @MainActor in self?.isOff = access.isOff }
        }
    }

    /// Opens this app's pane in System Settings, or the Notifications pane if that link isn't understood.
    func openSettings() {
        let pane = "x-apple.systempreferences:com.apple.Notifications-Settings.extension"
        if let id = Bundle.main.bundleIdentifier, let url = URL(string: "\(pane)?id=\(id)"),
            NSWorkspace.shared.open(url)
        {
            return
        }
        if let url = URL(string: pane) {
            NSWorkspace.shared.open(url)
        }
    }
}

extension NotificationAccess {
    fileprivate init(_ settings: UNNotificationSettings) {
        self.init(
            authorization: Authorization(settings.authorizationStatus),
            alerts: Setting(settings.alertSetting))
    }
}

extension NotificationAccess.Authorization {
    fileprivate init(_ status: UNAuthorizationStatus) {
        switch status {
        case .denied: self = .denied
        case .authorized: self = .authorized
        case .provisional: self = .provisional
        case .ephemeral: self = .ephemeral
        default: self = .notDetermined
        }
    }
}

extension NotificationAccess.Setting {
    fileprivate init(_ setting: UNNotificationSetting) {
        switch setting {
        case .disabled: self = .disabled
        case .enabled: self = .enabled
        default: self = .notSupported
        }
    }
}
