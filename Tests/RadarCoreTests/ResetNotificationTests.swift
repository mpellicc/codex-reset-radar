import XCTest

@testable import RadarCore

final class ResetNotificationTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let source = URL(string: "https://example.com/announcement")!

    private func pending(type: String = "regular", sourceURL: URL? = nil) -> ScheduledReset {
        ScheduledReset(
            id: "reset-a", resetType: type, announcedAt: now,
            scheduledFor: now.addingTimeInterval(3600), text: "A reset is coming.",
            source: Source(url: sourceURL)
        )
    }

    private func announcement(_ reset: ScheduledReset, kind: Announcement.Kind = .announced) -> ResetNotification {
        .announcement(Announcement(kind: kind, reset: reset, scheduledFor: reset.scheduledFor!))
    }

    private func landed(type: String = "regular") -> ResetNotification {
        .landed(Reset(id: "reset-a", resetType: type, announcedAt: now))
    }

    func testAnnouncementDescribesTheScheduleAndOpensTheSource() {
        let reset = pending(sourceURL: source)
        let notification = announcement(reset)
        XCTAssertEqual(notification.title, "Codex reset announced")
        XCTAssertEqual(
            notification.subtitle(now: now),
            "Scheduled for \(Format.when(reset.scheduledFor!)) · \(Format.relative(reset.scheduledFor!, to: now))"
        )
        XCTAssertEqual(notification.body, reset.text)
        XCTAssertEqual(notification.url, source)
    }

    func testLandingConfirmsTheResetAndOpensTheHomepage() {
        let notification = landed()
        XCTAssertEqual(notification.title, "Codex reset landed")
        XCTAssertEqual(notification.subtitle(now: now), "Reset confirmed")
        XCTAssertEqual(notification.body, "The reset has landed. Your usage limits are back.")
        XCTAssertEqual(notification.url, URL(string: "https://codex-resets.com"))
    }

    func testSameResetHasSeparateAnnouncementLandingAndReminderIdentities() throws {
        let reset = pending(sourceURL: source)
        let reminder = try XCTUnwrap(Reminder.planned(for: reset, now: now))
        let notifications = [announcement(reset), landed(), ResetNotification.reminder(reset, reminder)]
        XCTAssertEqual(Set(notifications.map(\.identifier)).count, 3)
        XCTAssertEqual(Set(notifications.map(\.threadIdentifier)).count, 3)
        // Preserve the existing request identifiers, including the single replaceable reminder.
        XCTAssertEqual(
            notifications.map(\.identifier), ["reset-reset-a-1800003600", "landed-reset-a", "reset-reminder"])
        XCTAssertEqual(
            notifications.map(\.threadIdentifier), ["reset-announcements", "reset-landings", "reset-reminders"])
    }

    func testReschedulingStaysInTheAnnouncementThreadWithANewRequest() {
        let first = pending()
        let moved = ScheduledReset(
            id: first.id, resetType: first.resetType, announcedAt: first.announcedAt,
            scheduledFor: now.addingTimeInterval(7200), text: first.text, source: first.source
        )
        let original = announcement(first)
        let rescheduled = announcement(moved, kind: .rescheduled)
        XCTAssertEqual(rescheduled.title, "Codex reset rescheduled")
        XCTAssertEqual(rescheduled.threadIdentifier, original.threadIdentifier)
        XCTAssertNotEqual(rescheduled.identifier, original.identifier)
        XCTAssertNotEqual(rescheduled.threadIdentifier, landed().threadIdentifier)
    }

    func testBankedResetsKeepTheirTypeInBothEvents() {
        XCTAssertEqual(announcement(pending(type: "banked")).title, "Codex banked reset announced")
        XCTAssertEqual(landed(type: "banked").title, "Codex banked reset landed")
    }

    func testReminderKeepsItsSourceAndScheduledTime() throws {
        let reset = pending(sourceURL: source)
        let reminder = try XCTUnwrap(Reminder.planned(for: reset, now: now))
        let notification = ResetNotification.reminder(reset, reminder)
        XCTAssertEqual(notification.title, "Codex reset in 15 minutes")
        XCTAssertEqual(notification.subtitle(now: now), Format.when(reminder.scheduledFor))
        XCTAssertEqual(notification.body, reset.text)
        XCTAssertEqual(notification.url, source)
        XCTAssertEqual(notification.identifier, ResetNotification.reminderID)
    }

    func testMissingSourceDoesNotTurnAnAnnouncementIntoALandingLink() {
        XCTAssertNil(announcement(pending()).url)
    }
}
