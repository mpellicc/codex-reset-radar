import Foundation
import os

/// A notification to deliver a fixed lead time before a pending reset's scheduled time.
///
/// There is no stored state: the reminder is a function of the pending reset and the clock, so
/// every poll can re-derive it. Arming it again for the same pair is a no-op, a reschedule moves
/// it, and once it is due (or the reset landed or was called off) nothing is planned any more.
public struct Reminder: Equatable, Sendable {
    /// The lead times the user can pick, in minutes.
    public static let leadMinuteChoices = [5, 15, 30, 60]
    public static let defaultLeadMinutes = 15

    public let resetID: String
    public let scheduledFor: Date
    public let leadTime: TimeInterval

    public init(resetID: String, scheduledFor: Date, leadTime: TimeInterval = TimeInterval(defaultLeadMinutes * 60)) {
        self.resetID = resetID
        self.scheduledFor = scheduledFor
        self.leadTime = leadTime
    }

    public var fireDate: Date { scheduledFor.addingTimeInterval(-leadTime) }

    /// The reminder to have armed for this pending reset, or nil when none should be: no pending
    /// reset, no date yet, or less than the lead time left (the announcement already covers it).
    public static func planned(
        for reset: ScheduledReset?, now: Date, leadTime: TimeInterval = TimeInterval(defaultLeadMinutes * 60)
    ) -> Reminder? {
        guard let reset else {
            Log.notify.notice("no reminder: no pending reset")
            return nil
        }
        guard let when = reset.scheduledFor else {
            Log.notify.notice("no reminder: reset \(reset.id, privacy: .public) has no date yet")
            return nil
        }
        let reminder = Reminder(resetID: reset.id, scheduledFor: when, leadTime: leadTime)
        guard reminder.fireDate > now else {
            Log.notify.notice(
                "no reminder: reset \(reset.id, privacy: .public) is less than the lead time away or past (\(when.ISO8601Format(), privacy: .public))"
            )
            return nil
        }
        return reminder
    }
}
