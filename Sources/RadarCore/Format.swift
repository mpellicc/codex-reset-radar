import Foundation

public enum Format {
    public static func when(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).hour().minute())
    }

    /// Time of day only, in the user's short style (15:05 or 3:05 PM).
    public static func clock(_ date: Date, locale: Locale = .current, timeZone: TimeZone = .current) -> String {
        date.formatted(Date.FormatStyle(date: .omitted, time: .shortened, locale: locale, timeZone: timeZone))
    }

    public static func relative(_ date: Date, to now: Date = Date()) -> String {
        RelativeDateTimeFormatter().localizedString(for: date, relativeTo: now)
    }

    /// How long is left, split the way the countdown shows it.
    private enum Remaining {
        case due
        case minutes(Int)
        case hoursAndMinutes(Int, Int)
        case hours(Int)
        case days(Int)

        init(to date: Date, from now: Date) {
            let seconds = date.timeIntervalSince(now)
            guard seconds > 0 else {
                self = .due
                return
            }
            let minutes = Int(seconds / 60)
            let hours = minutes / 60
            if minutes < 60 {
                self = .minutes(max(minutes, 1))
            } else if hours < 2 {
                self = .hoursAndMinutes(hours, minutes % 60)
            } else if hours < 48 {
                self = .hours(hours)
            } else {
                self = .days(hours / 24)
            }
        }
    }

    /// Compact countdown for the menu bar: 45m, 1h 59m, 9h, 3d, or "due".
    public static func countdown(to date: Date, from now: Date) -> String {
        switch Remaining(to: date, from: now) {
        case .due: return String(localized: "due")
        case .minutes(let m): return String(localized: "\(m)m")
        case .hoursAndMinutes(let h, let m): return String(localized: "\(h)h \(m)m")
        case .hours(let h): return String(localized: "\(h)h")
        case .days(let d): return String(localized: "\(d)d")
        }
    }

    /// The same countdown spelled out for VoiceOver: 45 minutes, 1 hour 59 minutes, 9 hours, 3 days, or "due".
    public static func spokenCountdown(to date: Date, from now: Date) -> String {
        // One key per form rather than a stringsdict: counts never reach 0, so one and other cover
        // English and Italian, and the English fallback stays right where no strings are bundled (tests).
        func minutes(_ m: Int) -> String { m == 1 ? String(localized: "1 minute") : String(localized: "\(m) minutes") }
        func hours(_ h: Int) -> String { h == 1 ? String(localized: "1 hour") : String(localized: "\(h) hours") }
        switch Remaining(to: date, from: now) {
        case .due: return String(localized: "spoken-due", defaultValue: "due")
        case .minutes(let m): return minutes(m)
        case .hoursAndMinutes(let h, 0): return hours(h)
        case .hoursAndMinutes(let h, let m): return "\(hours(h)) \(minutes(m))"
        case .hours(let h): return hours(h)
        case .days(let d): return String(localized: "\(d) days")
        }
    }
}
