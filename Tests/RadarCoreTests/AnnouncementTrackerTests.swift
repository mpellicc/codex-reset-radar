import XCTest

@testable import RadarCore

private final class InMemoryStore: NotifiedStore {
    var notified: [String: Double] = [:]

    func load() -> [String: Double] { notified }
    func save(_ notified: [String: Double]) { self.notified = notified }
}

final class AnnouncementTrackerTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let store = InMemoryStore()

    private var tracker: AnnouncementTracker { AnnouncementTracker(store: store) }

    private func reset(id: String = "a", in seconds: TimeInterval?, type: String = "regular") -> ScheduledReset {
        ScheduledReset(
            id: id,
            resetType: type,
            announcedAt: now,
            scheduledFor: seconds.map { now.addingTimeInterval($0) },
            text: "Soon.",
            source: Source(url: URL(string: "https://example.com/post"))
        )
    }

    func testNewIdIsAnnounced() throws {
        let announcement = try XCTUnwrap(tracker.announcementIfNew(reset(in: 3600), now: now))
        XCTAssertEqual(announcement.kind, .announced)
        XCTAssertEqual(announcement.reset.id, "a")
        XCTAssertEqual(announcement.scheduledFor, now.addingTimeInterval(3600))
    }

    func testSameIdAndTimeIsNotAnnouncedAgain() {
        XCTAssertNotNil(tracker.announcementIfNew(reset(in: 3600), now: now))
        XCTAssertNil(tracker.announcementIfNew(reset(in: 3600), now: now))
    }

    func testSameIdWithNewTimeIsRescheduled() throws {
        XCTAssertNotNil(tracker.announcementIfNew(reset(in: 3600), now: now))
        let announcement = try XCTUnwrap(tracker.announcementIfNew(reset(in: 7200), now: now))
        XCTAssertEqual(announcement.kind, .rescheduled)
        XCTAssertEqual(announcement.scheduledFor, now.addingTimeInterval(7200))
        XCTAssertNil(tracker.announcementIfNew(reset(in: 7200), now: now))
    }

    func testDifferentIdIsAnnounced() throws {
        XCTAssertNotNil(tracker.announcementIfNew(reset(id: "a", in: 3600), now: now))
        let announcement = try XCTUnwrap(tracker.announcementIfNew(reset(id: "b", in: 3600), now: now))
        XCTAssertEqual(announcement.kind, .announced)
    }

    func testRelaunchDoesNotRepeatAnAnnouncementButStillReportsAReschedule() throws {
        XCTAssertEqual(tracker.announcementIfNew(reset(in: 3600), now: now)?.kind, .announced)
        let relaunched = AnnouncementTracker(store: store)
        XCTAssertNil(relaunched.announcementIfNew(reset(in: 3600), now: now))
        let rescheduled = try XCTUnwrap(relaunched.announcementIfNew(reset(in: 7200), now: now))
        XCTAssertEqual(rescheduled.kind, .rescheduled)
        XCTAssertNil(AnnouncementTracker(store: store).announcementIfNew(reset(in: 7200), now: now))
    }

    func testNothingToAnnounce() {
        XCTAssertNil(tracker.announcementIfNew(nil, now: now))
        XCTAssertNil(tracker.announcementIfNew(reset(in: nil), now: now))
        XCTAssertNil(tracker.announcementIfNew(reset(in: -60), now: now))
        XCTAssertNil(tracker.announcementIfNew(reset(in: 0), now: now))
        XCTAssertTrue(store.notified.isEmpty)
    }

    func testRemembersAtMostFiftyDroppingTheEarliestTimes() {
        for index in 0..<51 {
            XCTAssertNotNil(tracker.announcementIfNew(reset(id: "r\(index)", in: 3600 + Double(index)), now: now))
        }
        XCTAssertEqual(store.notified.count, 50)
        XCTAssertNil(store.notified["r0"])
        XCTAssertNotNil(store.notified["r1"])
        XCTAssertNotNil(store.notified["r50"])
        // A forgotten reset counts as new again.
        XCTAssertEqual(tracker.announcementIfNew(reset(id: "r0", in: 3600), now: now)?.kind, .announced)
    }
}
