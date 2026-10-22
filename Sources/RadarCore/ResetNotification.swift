import Foundation

/// Content and identity for reset notifications. Each event has its own request namespace and
/// thread, keeping announcements separate from landings under macOS automatic grouping.
public enum ResetNotification {
    case announcement(Announcement)
    case landed(Reset)
    case reminder(ScheduledReset, Reminder)

    public var identifier: String {
        switch self {
        case .announcement(let announcement):
            let stamp = Int(announcement.scheduledFor.timeIntervalSince1970)
            return "reset-\(announcement.reset.id)-\(stamp)"
        case .landed(let reset):
            return "landed-\(reset.id)"
        case .reminder:
            // Only one pending reminder is armed; rescheduling replaces it.
            return Self.reminderID
        }
    }

    public static let reminderID = "reset-reminder"

    public var threadIdentifier: String {
        switch self {
        case .announcement: return "reset-announcements"
        case .landed: return "reset-landings"
        case .reminder: return "reset-reminders"
        }
    }

    public var title: String {
        switch self {
        case .announcement(let announcement):
            let event = announcement.kind == .announced ? "announced" : "rescheduled"
            return "Codex \(announcement.reset.typeLabel.lowercased()) \(event)"
        case .landed(let reset):
            return "Codex \(reset.typeLabel.lowercased()) landed"
        case .reminder(let reset, _):
            return "Codex \(reset.typeLabel.lowercased()) in 15 minutes"
        }
    }

    public func subtitle(now: Date = Date()) -> String {
        switch self {
        case .announcement(let announcement):
            return
                "Scheduled for \(Format.when(announcement.scheduledFor)) · \(Format.relative(announcement.scheduledFor, to: now))"
        case .landed:
            return "Reset confirmed"
        case .reminder(_, let reminder):
            return Format.when(reminder.scheduledFor)
        }
    }

    public var body: String {
        switch self {
        case .announcement(let announcement): return announcement.reset.text
        case .landed: return "The reset has landed. Your usage limits are back."
        case .reminder(let reset, _): return reset.text
        }
    }

    public var url: URL? {
        switch self {
        case .announcement(let announcement): return announcement.reset.source.url
        case .landed: return URL(string: "https://codex-resets.com")
        case .reminder(let reset, _): return reset.source.url
        }
    }
}
