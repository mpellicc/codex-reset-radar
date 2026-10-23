import Foundation

/// Where the pending reset stands, as far as the menu bar item shows it.
public enum MenuBarPhase: Equatable, Sendable {
    /// No pending reset with a date.
    case quiet
    /// A dated reset further away than the reminder lead time: the countdown.
    case counting
    /// A dated reset within the reminder lead time: the countdown, and the rings light up.
    case imminent
    /// The scheduled time has passed and the reset hasn't landed yet.
    case pastDue

    public init(pending: ScheduledReset?, now: Date, leadTime: ReminderLeadTime) {
        guard let when = pending?.scheduledFor else {
            self = .quiet
            return
        }
        let left = when.timeIntervalSince(now)
        if left <= 0 {
            self = .pastDue
        } else if left <= leadTime.interval {
            self = .imminent
        } else {
            self = .counting
        }
    }
}
