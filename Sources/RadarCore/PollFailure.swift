import Foundation

/// Parses the `Retry-After` response header.
public enum RetryAfter {
    /// The moment the server asked us to wait until: `now` plus the delay in seconds, or the HTTP-date as is.
    /// Nil when the header is missing or unreadable.
    public static func date(from header: String?, now: Date) -> Date? {
        guard let value = header?.trimmingCharacters(in: .whitespaces), !value.isEmpty else { return nil }
        if value.allSatisfy({ $0.isASCII && $0.isNumber }), let seconds = TimeInterval(value) {
            return now.addingTimeInterval(seconds)
        }
        return httpDate(value)
    }

    /// The three date formats HTTP allows (RFC 9110): IMF-fixdate, obsolete RFC 850 and asctime.
    private static let httpDateFormats = [
        "EEE, dd MMM yyyy HH:mm:ss zzz",
        "EEEE, dd-MMM-yy HH:mm:ss zzz",
        "EEE MMM d HH:mm:ss yyyy",
    ]

    private static func httpDate(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        for format in httpDateFormats {
            formatter.dateFormat = format
            if let date = formatter.date(from: value) { return date }
        }
        return nil
    }
}

/// What a failed poll means for the user and for the next poll.
public struct PollFailure: Equatable, Sendable {
    /// Short text for the panel.
    public let message: String
    /// Polls before this moment should be skipped. Nil when the next poll can go ahead as usual.
    public let retryNotBefore: Date?

    /// The longest we honour a `Retry-After`, so a bogus value can't silence polling for good.
    public static let maxRetryDelay: TimeInterval = 24 * 3600

    private static let offlineCodes: Set<URLError.Code> = [
        .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff, .dnsLookupFailed,
    ]

    /// Classifies an error from a poll. `nextRegularPoll` is when the regular schedule polls again, and is
    /// where a 429 without `Retry-After` backs off to.
    public init(
        _ error: Error, now: Date, nextRegularPoll: Date, locale: Locale = .current, timeZone: TimeZone = .current
    ) {
        if let error = error as? StatusError, case .http(let status, let retryAfter) = error {
            let pause = Self.pause(status: status, retryAfter: retryAfter, now: now, nextRegularPoll: nextRegularPoll)
            retryNotBefore = pause
            switch status {
            case 429:
                let retryAt = pause ?? nextRegularPoll
                let clock = Format.clock(retryAt, locale: locale, timeZone: timeZone)
                message = String(localized: "Rate limited, retrying at \(clock)")
            case 500...599:
                message = String(localized: "codex-resets.com is having trouble")
            default:
                message = error.localizedDescription
            }
        } else if let error = error as? URLError, error.code == .timedOut {
            message = String(localized: "Request timed out")
            retryNotBefore = nil
        } else if let error = error as? URLError, Self.offlineCodes.contains(error.code) {
            message = String(localized: "You're offline")
            retryNotBefore = nil
        } else if error is DecodingError || (error as? URLError)?.code == .badServerResponse {
            message = String(localized: "Unexpected response from codex-resets.com")
            retryNotBefore = nil
        } else {
            message = error.localizedDescription
            retryNotBefore = nil
        }
    }

    /// 429 and 503 with a future `Retry-After` pause polling until then; a 429 without one pauses until the
    /// next regular poll.
    private static func pause(status: Int, retryAfter: Date?, now: Date, nextRegularPoll: Date) -> Date? {
        guard status == 429 || status == 503 else { return nil }
        if let retryAfter, retryAfter > now {
            return min(retryAfter, now.addingTimeInterval(maxRetryDelay))
        }
        return status == 429 ? nextRegularPoll : nil
    }
}

/// Decides when the network coming back should trigger a refresh.
public struct ReconnectDebounce: Sendable {
    private let minimumGap: TimeInterval
    private var wasSatisfied: Bool?
    private var lastRefresh: Date?

    public init(minimumGap: TimeInterval = 30) {
        self.minimumGap = minimumGap
    }

    /// Feed every path update. True when the network just came back (not at launch, which polls anyway)
    /// and no reconnect refresh happened within the minimum gap, so a flapping network can't spam the API.
    public mutating func shouldRefresh(pathSatisfied: Bool, now: Date) -> Bool {
        defer { wasSatisfied = pathSatisfied }
        guard pathSatisfied, wasSatisfied == false else { return false }
        if let lastRefresh, now.timeIntervalSince(lastRefresh) < minimumGap { return false }
        lastRefresh = now
        return true
    }
}
