import XCTest

@testable import RadarCore

final class StatusDecodingTests: XCTestCase {
    private func decodeFixture(_ name: String) throws -> StatusData {
        let url = try XCTUnwrap(Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures"))
        return try StatusClient.decode(Data(contentsOf: url))
    }

    private func date(_ iso: String, fractional: Bool = true) throws -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions =
            fractional ? [.withInternetDateTime, .withFractionalSeconds] : [.withInternetDateTime]
        return try XCTUnwrap(formatter.date(from: iso))
    }

    func testPendingWithDate() throws {
        let status = try decodeFixture("pending-with-date")
        let pending = try XCTUnwrap(status.scheduledReset)
        XCTAssertEqual(pending.id, "2113162413008884099")
        XCTAssertEqual(pending.resetType, "regular")
        XCTAssertEqual(pending.typeLabel, "Reset")
        XCTAssertEqual(pending.announcedAt, try date("2026-10-22T06:55:54.000Z"))
        XCTAssertEqual(pending.scheduledFor, try date("2026-10-22T17:00:00.000Z"))
        XCTAssertEqual(pending.text, "Lands tomorrow before 10am PST.")
        XCTAssertEqual(pending.source.url, URL(string: "https://x.com/thsottiaux/status/2113162413008884099"))
        XCTAssertEqual(status.latestReset?.id, "2112432076767289678")
        XCTAssertEqual(status.latestReset?.announcedAt, try date("2026-10-20T06:33:48.000Z"))
        XCTAssertEqual(status.stats.avgIntervalDays, 6.3)
    }

    func testPendingWithoutDate() throws {
        let status = try decodeFixture("pending-without-date")
        let pending = try XCTUnwrap(status.scheduledReset)
        XCTAssertNil(pending.scheduledFor)
        XCTAssertEqual(pending.resetType, "banked")
        XCTAssertEqual(pending.typeLabel, "Banked reset")
        XCTAssertNil(pending.source.url)
        XCTAssertNil(status.stats.avgIntervalDays)
    }

    func testNothingPending() throws {
        let status = try decodeFixture("nothing-pending")
        XCTAssertNil(status.scheduledReset)
        XCTAssertNil(status.latestReset)
        XCTAssertEqual(status.stats.avgIntervalDays, 6.3)
    }

    func testPlainISO8601DatesWithoutFractionalSeconds() throws {
        let status = try decodeFixture("plain-iso8601-dates")
        let pending = try XCTUnwrap(status.scheduledReset)
        XCTAssertEqual(pending.announcedAt, try date("2026-10-22T06:55:54Z", fractional: false))
        XCTAssertEqual(pending.scheduledFor, try date("2026-10-22T17:00:00Z", fractional: false))
        XCTAssertEqual(status.latestReset?.announcedAt, try date("2026-10-20T06:33:48Z", fractional: false))
    }

    func testInvalidDateFails() {
        let bad = """
            {"data":{"latest_reset":{"id":"1","reset_type":"regular","announced_at":"yesterday"},\
            "scheduled_reset":null,"stats":{}}}
            """
        XCTAssertThrowsError(try StatusClient.decode(Data(bad.utf8)))
    }

    private func sourceURL(_ url: String) throws -> URL? {
        let json = """
            {"data":{"latest_reset":null,"scheduled_reset":{"id":"1","reset_type":"regular",\
            "announced_at":"2026-10-22T06:55:54Z","scheduled_for":null,"text":"Soon.",\
            "source":{"url":"\(url)"}},"stats":{}}}
            """
        return try XCTUnwrap(StatusClient.decode(Data(json.utf8)).scheduledReset).source.url
    }

    func testSourceURLKeepsHTTPAndHTTPS() throws {
        XCTAssertEqual(try sourceURL("https://x.com/a/status/1"), URL(string: "https://x.com/a/status/1"))
        XCTAssertEqual(try sourceURL("HTTP://example.com"), URL(string: "HTTP://example.com"))
    }

    func testSourceURLDropsOtherSchemes() throws {
        XCTAssertNil(try sourceURL("file:///Applications/Calculator.app"))
        XCTAssertNil(try sourceURL("x-apple.systempreferences:com.apple.preference.security"))
        XCTAssertNil(try sourceURL("javascript:alert(1)"))
    }
}
