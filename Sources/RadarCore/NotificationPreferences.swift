import Foundation

/// Which kinds of notification the user wants. All are on by default.
///
/// The switches only gate what is delivered. The trackers behind them keep recording, so a kind
/// that is switched back on picks up from the present instead of sending what it skipped.
public struct NotificationPreferences: Equatable, Sendable {
    /// "Reset announced" and "rescheduled".
    public var announced: Bool
    /// "Reset in N minutes", N being `reminderLeadMinutes`.
    public var reminder: Bool
    /// "Reset landed".
    public var landed: Bool
    /// How many minutes before the reset the reminder fires. One of `Reminder.leadMinuteChoices`.
    public var reminderLeadMinutes: Int

    public init(
        announced: Bool = true, reminder: Bool = true, landed: Bool = true,
        reminderLeadMinutes: Int = Reminder.defaultLeadMinutes
    ) {
        self.announced = announced
        self.reminder = reminder
        self.landed = landed
        self.reminderLeadMinutes = reminderLeadMinutes
    }

    /// The reminder lead time, for anything that needs to know when a reset is "close" (the reminder itself, and later the menu bar).
    public var reminderLeadTime: TimeInterval { TimeInterval(reminderLeadMinutes * 60) }

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
            reminderLeadMinutes: leadMinutes())
    }

    public func save(_ preferences: NotificationPreferences) {
        defaults.set(preferences.announced, forKey: "notifyAnnounced")
        defaults.set(preferences.reminder, forKey: "notifyReminder")
        defaults.set(preferences.landed, forKey: "notifyLanded")
        defaults.set(preferences.reminderLeadMinutes, forKey: "reminderLeadMinutes")
    }

    /// A missing or unknown value reads as the default.
    private func leadMinutes() -> Int {
        let stored = defaults.object(forKey: "reminderLeadMinutes") as? Int
        return stored.flatMap { Reminder.leadMinuteChoices.contains($0) ? $0 : nil } ?? Reminder.defaultLeadMinutes
    }

    private func flag(_ key: String) -> Bool {
        defaults.object(forKey: key) as? Bool ?? true
    }
}
