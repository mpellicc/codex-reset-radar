import AppKit
import RadarCore
import UserNotifications
import os

/// Keeps the notified pairs in `UserDefaults`.
private struct UserDefaultsNotifiedStore: NotifiedStore {
    private let defaults = UserDefaults.standard
    private let key = "notifiedAnnouncements"

    func load() -> [String: Double] {
        defaults.dictionary(forKey: key) as? [String: Double] ?? [:]
    }

    func save(_ notified: [String: Double]) {
        defaults.set(notified, forKey: key)
    }
}

/// Keeps the id of the latest reset seen in `UserDefaults`.
private struct UserDefaultsLandedStore: LandedStore {
    private let defaults = UserDefaults.standard
    private let key = "lastSeenResetID"

    func load() -> String? {
        defaults.string(forKey: key)
    }

    func save(_ id: String) {
        defaults.set(id, forKey: key)
    }
}

/// Sends one notification per announced reset time and one per landed reset, schedules the reminder,
/// and opens the source post (or codex-resets.com for a landed reset) on click.
@MainActor
final class Notifier: NSObject, UNUserNotificationCenterDelegate {
    private static let homepage = URL(string: "https://codex-resets.com")!
    private static let reminderID = "reset-reminder"

    private let center = UNUserNotificationCenter.current()
    private let tracker = AnnouncementTracker(store: UserDefaultsNotifiedStore())
    private let landings = LandingTracker(store: UserDefaultsLandedStore())
    private let preferencesStore = UserDefaultsNotificationPreferencesStore()
    private(set) var preferences: NotificationPreferences
    /// The pending reset of the last poll, so a switch can re-sync the reminder without waiting for the next one.
    private var lastScheduledReset: ScheduledReset?

    override init() {
        preferences = preferencesStore.load()
        super.init()

        center.delegate = self
        // The center calls back on a background queue; @Sendable keeps the closure off the main actor,
        // or Swift 6 traps on the isolation check when it runs.
        center.requestAuthorization(options: [.alert, .sound]) { @Sendable granted, error in
            Log.notify.notice(
                "authorization request: granted \(granted, privacy: .public), error \(error?.localizedDescription ?? "none", privacy: .public)"
            )
        }
    }

    /// Applies new notification switches right away. The reminder is the only kind with something
    /// pending in the system, so it is re-synced here instead of at the next poll.
    func update(_ preferences: NotificationPreferences) {
        self.preferences = preferences
        preferencesStore.save(preferences)
        syncReminder(for: lastScheduledReset)
    }

    func process(_ status: StatusData) {
        lastScheduledReset = status.scheduledReset
        announceIfNew(status.scheduledReset)
        notifyIfLanded(status.latestReset)
        syncReminder(for: status.scheduledReset)
    }

    private func announceIfNew(_ reset: ScheduledReset?) {
        guard let recorded = tracker.announcementIfNew(reset) else { return }
        guard let announcement = preferences.allowing(recorded) else {
            Log.notify.notice(
                "announcement for reset \(recorded.reset.id, privacy: .public) not sent: announcements are switched off"
            )
            return
        }
        let reset = announcement.reset
        let when = announcement.scheduledFor

        let content = UNMutableNotificationContent()
        content.title =
            announcement.kind == .announced
            ? "Codex \(reset.typeLabel.lowercased()) announced"
            : "Codex \(reset.typeLabel.lowercased()) rescheduled"
        content.subtitle = "\(Format.when(when)) · \(Format.relative(when))"
        content.body = reset.text
        content.sound = .default
        if let url = reset.source.url {
            content.userInfo = ["url": url.absoluteString]
        }
        let stamp = Int(when.timeIntervalSince1970)
        center.add(UNNotificationRequest(identifier: "reset-\(reset.id)-\(stamp)", content: content, trigger: nil))
        Log.notify.notice("announcement sent for reset \(reset.id, privacy: .public)")
    }

    private func notifyIfLanded(_ latest: Reset?) {
        guard let recorded = landings.landedIfNew(latest) else { return }
        guard let landed = preferences.allowing(landed: recorded) else {
            Log.notify.notice(
                "landed notification for reset \(recorded.id, privacy: .public) not sent: landed notifications are switched off"
            )
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Codex \(landed.typeLabel.lowercased()) landed"
        content.body = "Your usage limits are back."
        content.sound = .default
        content.userInfo = ["url": Self.homepage.absoluteString]
        center.add(UNNotificationRequest(identifier: "landed-\(landed.id)", content: content, trigger: nil))
        Log.notify.notice("landed notification sent for reset \(landed.id, privacy: .public)")
    }

    /// Keeps a single scheduled request in step with the pending reset. It is replaced when the
    /// time changes and removed once there is nothing to remind about (landed, called off, too close).
    private func syncReminder(for reset: ScheduledReset?) {
        guard let reset, let reminder = preferences.plannedReminder(for: reset, now: Date()) else {
            center.removePendingNotificationRequests(withIdentifiers: [Self.reminderID])
            if preferences.reminder {
                Log.notify.notice("reminder removed (nothing to remind about)")
            } else {
                Log.notify.notice("reminder removed: reminders are switched off")
            }
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Codex \(reset.typeLabel.lowercased()) in 15 minutes"
        content.subtitle = Format.when(reminder.scheduledFor)
        content.body = reset.text
        content.sound = .default
        if let url = reset.source.url {
            content.userInfo = ["url": url.absoluteString]
        }
        // A calendar trigger holds an absolute time, so it still fires on schedule after the Mac sleeps.
        let fields: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents(fields, from: reminder.fireDate), repeats: false)
        center.add(UNNotificationRequest(identifier: Self.reminderID, content: content, trigger: trigger))
        Log.notify.notice(
            "reminder scheduled for \(reminder.fireDate.ISO8601Format(), privacy: .public) (reset \(reset.id, privacy: .public)), replacing any pending one"
        )
    }

    // The center calls its delegate on a background queue, so these hop to the main actor where needed.

    // Menu bar apps count as frontmost while the panel is open; show the banner anyway.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let string = response.notification.request.content.userInfo["url"] as? String,
            let url = URL(string: string)
        {
            Task { @MainActor in NSWorkspace.shared.open(url) }
        }
        completionHandler()
    }
}
