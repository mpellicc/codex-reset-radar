import AppKit
import RadarCore
import UserNotifications

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

    override init() {
        super.init()
        center.delegate = self
        // The center calls back on a background queue; @Sendable keeps the closure off the main actor,
        // or Swift 6 traps on the isolation check when it runs.
        center.requestAuthorization(options: [.alert, .sound]) { @Sendable _, _ in }
    }

    func process(_ status: StatusData) {
        announceIfNew(status.scheduledReset)
        notifyIfLanded(status.latestReset)
        syncReminder(for: status.scheduledReset)
    }

    private func announceIfNew(_ reset: ScheduledReset?) {
        guard let announcement = tracker.announcementIfNew(reset) else { return }
        let reset = announcement.reset
        let when = announcement.scheduledFor

        let content = UNMutableNotificationContent()
        content.title =
            announcement.kind == .announced
            ? String(localized: "Codex \(reset.typeNoun) announced")
            : String(localized: "Codex \(reset.typeNoun) rescheduled")
        content.subtitle = "\(Format.when(when)) · \(Format.relative(when))"
        content.body = reset.text
        content.sound = .default
        if let url = reset.source.url {
            content.userInfo = ["url": url.absoluteString]
        }
        let stamp = Int(when.timeIntervalSince1970)
        center.add(UNNotificationRequest(identifier: "reset-\(reset.id)-\(stamp)", content: content, trigger: nil))
    }

    private func notifyIfLanded(_ latest: Reset?) {
        guard let landed = landings.landedIfNew(latest) else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Codex \(landed.typeNoun) landed")
        content.body = String(localized: "Your usage limits are back.")
        content.sound = .default
        content.userInfo = ["url": Self.homepage.absoluteString]
        center.add(UNNotificationRequest(identifier: "landed-\(landed.id)", content: content, trigger: nil))
    }

    /// Keeps a single scheduled request in step with the pending reset. It is replaced when the
    /// time changes and removed once there is nothing to remind about (landed, called off, too close).
    private func syncReminder(for reset: ScheduledReset?) {
        guard let reset, let reminder = Reminder.planned(for: reset, now: Date()) else {
            center.removePendingNotificationRequests(withIdentifiers: [Self.reminderID])
            return
        }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Codex \(reset.typeNoun) in 15 minutes")
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
