import os

/// The app's loggers. Read them back with
/// `log show --last 1d --predicate 'subsystem == "dev.mpellicc.CodexResetRadar"' --info`.
///
/// Everything that explains a missed or late notification is logged at `notice` (or `error`), because
/// `info` and `debug` messages are not kept on disk. Interpolated strings are redacted in a stored log
/// unless marked `.public`, so mark only public data (ids, announcement text, dates, status codes).
public enum Log {
    public static let subsystem = "dev.mpellicc.CodexResetRadar"

    /// Fetching and scheduling polls.
    public static let poll = Logger(subsystem: subsystem, category: "poll")
    /// Notification decisions and the system's notification settings.
    public static let notify = Logger(subsystem: subsystem, category: "notify")
}

/// What started a refresh, for the log.
public enum RefreshTrigger: String, Sendable {
    case launch
    case timer
    case wake
    case manual
    case reconnect
    case retryAfter = "retry-after"
}
