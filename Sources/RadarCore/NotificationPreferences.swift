import Foundation

/// Which kinds of notification the user wants. All are on by default.
///
/// The switches only gate what is delivered. The trackers behind them keep recording, so a kind
/// that is switched back on picks up from the present instead of sending what it skipped.
public struct NotificationPreferences: Equatable, Sendable {
    /// "Reset announced" and "rescheduled".
    public var announced: Bool
    /// "Reset in N minutes", N being `reminderLeadTime`.
    public var reminder: Bool
    /// "Reset landed".
    public var landed: Bool
    /// How long before the reset the reminder fires. Anything that needs to know when a reset is
    /// "close" reads it here (the reminder itself, and later the menu bar).
    public var reminderLeadTime: ReminderLeadTime

    public init(
        announced: Bool = true, reminder: Bool = true, landed: Bool = true,
        reminderLeadTime: ReminderLeadTime = .fifteenMinutes
    ) {
        self.announced = announced
        self.reminder = reminder
        self.landed = landed
        self.reminderLeadTime = reminderLeadTime
    }

    /// The announcement to send, or nil when announcements are switched off.
    /// Call it with what the tracker returned, after the tracker has recorded it.
    public func allowing(_ announcement: Announcement?) -> Announcement? {
        announced ? announcement : nil
    }

    /// The landed reset to report, or nil when landed notifications are switched off.
    public func allowing(landed reset: Reset?) -> Reset? {
        landed ? reset : nil
    }

    /// The reminder to have armed for this pending reset, or nil when reminders are switched off.
    public func plannedReminder(for reset: ScheduledReset?, now: Date) -> Reminder? {
        reminder ? Reminder.planned(for: reset, now: now, leadTime: reminderLeadTime) : nil
    }
}

/// Persistence for `NotificationPreferences`.
public protocol NotificationPreferencesStore {
    func load() -> NotificationPreferences
    func save(_ preferences: NotificationPreferences)
}

/// Keeps one boolean per kind in `UserDefaults`. A key that was never written reads as on.
public struct UserDefaultsNotificationPreferencesStore: NotificationPreferencesStore {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> NotificationPreferences {
        NotificationPreferences(
            announced: flag("notifyAnnounced"),
            reminder: flag("notifyReminder"),
            landed: flag("notifyLanded"),
            reminderLeadTime: leadTime())
    }

    public func save(_ preferences: NotificationPreferences) {
        defaults.set(preferences.announced, forKey: "notifyAnnounced")
        defaults.set(preferences.reminder, forKey: "notifyReminder")
        defaults.set(preferences.landed, forKey: "notifyLanded")
        defaults.set(preferences.reminderLeadTime.rawValue, forKey: "reminderLeadMinutes")
    }

    /// A missing, unknown or fractional value reads as 15 minutes.
    private func leadTime() -> ReminderLeadTime {
        (defaults.object(forKey: "reminderLeadMinutes") as? Int).flatMap(ReminderLeadTime.init(rawValue:))
            ?? .fifteenMinutes
    }

    private func flag(_ key: String) -> Bool {
        defaults.object(forKey: key) as? Bool ?? true
    }
}
