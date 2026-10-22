import Foundation
import os

public struct StatusData: Decodable, Sendable {
    public let latestReset: Reset?
    public let scheduledReset: ScheduledReset?
    public let stats: Stats
}

public struct Reset: Decodable, Sendable {
    public let id: String
    public let resetType: String
    public let announcedAt: Date

    public var typeLabel: String { ResetType.label(resetType) }
    public var typeNoun: String { ResetType.noun(resetType) }
}

public struct ScheduledReset: Decodable, Sendable {
    public let id: String
    public let resetType: String
    public let announcedAt: Date
    public let scheduledFor: Date?
    public let text: String
    public let source: Source

    public var typeLabel: String { ResetType.label(resetType) }
    public var typeNoun: String { ResetType.noun(resetType) }
}

private enum ResetType {
    /// How the type reads on its own, as a heading: "Banked reset".
    static func label(_ type: String) -> String {
        type == "banked" ? String(localized: "Banked reset") : String(localized: "Reset")
    }

    /// How it reads mid-sentence: "banked reset". A separate key, because not every language lowercases nouns.
    static func noun(_ type: String) -> String {
        type == "banked" ? String(localized: "banked reset") : String(localized: "reset")
    }
}

public struct Source: Decodable, Sendable {
    public let url: URL?
}

public struct Stats: Decodable, Sendable {
    public let avgIntervalDays: Double?
}

private struct StatusResponse: Decodable {
    let data: StatusData
}

public enum StatusError: LocalizedError, Equatable, Sendable {
    /// A non-200 answer, with the moment the server asked us to wait until (`Retry-After`), if it did.
    case http(Int, retryAfter: Date?)

    public var errorDescription: String? {
        switch self {
        case .http(let code, _): return String(localized: "codex-resets.com returned HTTP \(code)")
        }
    }
}

/// Fetches /api/v1/status, reusing the last response when the server answers 304.
public actor StatusClient {
    private let url = URL(string: "https://codex-resets.com/api/v1/status")!
    private var etag: String?
    private var cached: StatusData?

    public init() {}

    public func fetch() async throws -> StatusData {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("CodexResetRadar/\(Bundle.main.shortVersion)", forHTTPHeaderField: "User-Agent")
        if let etag, cached != nil {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if http.statusCode == 304, let cached {
            Log.poll.notice("fetch 304 not modified, reusing the cached status (ETag matched)")
            return cached
        }
        guard http.statusCode == 200 else {
            let retryAfter = RetryAfter.date(from: http.value(forHTTPHeaderField: "Retry-After"), now: Date())
            let retryAfterText = retryAfter?.ISO8601Format() ?? "none"
            Log.poll.error(
                "fetch HTTP \(http.statusCode, privacy: .public), Retry-After \(retryAfterText, privacy: .public)")
            throw StatusError.http(http.statusCode, retryAfter: retryAfter)
        }

        let status = try Self.decode(data)
        etag = http.value(forHTTPHeaderField: "ETag")
        cached = status
        let etagText = etag == nil ? "no ETag to reuse" : "ETag stored for the next request"
        Log.poll.notice("fetch 200 OK, \(etagText, privacy: .public)")
        return status
    }

    static func decode(_ data: Data) throws -> StatusData {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            let withFraction = ISO8601DateFormatter()
            withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let plain = ISO8601DateFormatter()
            if let date = withFraction.date(from: string) ?? plain.date(from: string) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
        }
        return try decoder.decode(StatusResponse.self, from: data).data
    }
}

extension Bundle {
    public var shortVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
    }
}
