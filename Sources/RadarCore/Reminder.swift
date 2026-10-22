import Foundation
import os

/// A notification to deliver a fixed lead time before a pending reset's scheduled time.
///
/// There is no stored state: the reminder is a function of the pending reset and the clock, so
/// every poll can re-derive it. Arming it again for the same pair is a no-op, a reschedule moves
/// it, and once it is due (or the reset landed or was called off) nothing is planned any more.
public struct Reminder: Equatable, Sendable {
    public static let leadTime: TimeInterval = 15 * 60

    public let resetID: String
    public let scheduledFor: Date

    public var fireDate: Date { scheduledFor.addingTimeInterval(-Self.leadTime) }

    /// The reminder to have armed for this pending reset, or nil when none should be: no pending
    /// reset, no date yet, or less than the lead time left (the announcement already covers it).
    public static func planned(for reset: ScheduledReset?, now: Date) -> Reminder? {
        guard let reset else {
            Log.notify.notice("no reminder: no pending reset")
            return nil
        }
        guard let when = reset.scheduledFor else {
            Log.notify.notice("no reminder: reset \(reset.id, privacy: .public) has no date yet")
            return nil
        }
        let reminder = Reminder(resetID: reset.id, scheduledFor: when)
        guard reminder.fireDate > now else {
            Log.notify.notice(
                "no reminder: reset \(reset.id, privacy: .public) is less than the lead time away or past (\(when.ISO8601Format(), privacy: .public))"
            )
            return nil
        }
        return reminder
    }
}
