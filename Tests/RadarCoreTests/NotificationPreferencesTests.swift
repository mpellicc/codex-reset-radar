import XCTest

@testable import RadarCore

private final class InMemoryNotifiedStore: NotifiedStore {
    var notified: [String: Double] = [:]

    func load() -> [String: Double] { notified }
    func save(_ notified: [String: Double]) { self.notified = notified }
}

private final class InMemoryLandedStore: LandedStore {
    var id: String?

    func load() -> String? { id }
    func save(_ id: String) { self.id = id }
}

final class NotificationPreferencesTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private var suiteName = ""
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "NotificationPreferencesTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    private func pending(in seconds: TimeInterval) -> ScheduledReset {
        ScheduledReset(
            id: "a",
            resetType: "regular",
            announcedAt: now,
            scheduledFor: now.addingTimeInterval(seconds),
            text: "Soon.",
            source: Source(url: nil)
        )
    }

    private func latest(_ id: String) -> Reset {
        Reset(id: id, resetType: "regular", announcedAt: now)
    }

    func testAllKindsAreOnByDefault() {
        let preferences = NotificationPreferences()
        XCTAssertTrue(preferences.announced)
        XCTAssertTrue(preferences.reminder)
        XCTAssertTrue(preferences.landed)
    }

    func testNothingStoredLoadsAsAllOn() {
        XCTAssertEqual(UserDefaultsNotificationPreferencesStore(defaults: defaults).load(), NotificationPreferences())
    }

    func testPersistenceRoundTrip() {
        let store = UserDefaultsNotificationPreferencesStore(defaults: defaults)
        let chosen = NotificationPreferences(announced: true, reminder: false, landed: false)
        store.save(chosen)
        XCTAssertEqual(UserDefaultsNotificationPreferencesStore(defaults: defaults).load(), chosen)

        store.save(NotificationPreferences())
        XCTAssertEqual(store.load(), NotificationPreferences())
    }

    func testEachKindIsStoredUnderItsOwnKey() {
        let store = UserDefaultsNotificationPreferencesStore(defaults: defaults)
        defaults.set(false, forKey: "notifyReminder")
        XCTAssertEqual(store.load(), NotificationPreferences(announced: true, reminder: false, landed: true))
    }

    func testSwitchedOffAnnouncementIsDroppedButStillRecorded() throws {
        let store = InMemoryNotifiedStore()
        let tracker = AnnouncementTracker(store: store)
        var preferences = NotificationPreferences(announced: false)

        // Off: the tracker records the pair, but nothing is sent.
        XCTAssertNil(preferences.allowing(tracker.announcementIfNew(pending(in: 3600), now: now)))
        XCTAssertEqual(store.notified["a"], now.addingTimeInterval(3600).timeIntervalSince1970)

        // Back on: the same reset is not sent late.
        preferences.announced = true
        XCTAssertNil(preferences.allowing(tracker.announcementIfNew(pending(in: 3600), now: now)))

        // A new time still notifies, as a reschedule.
        let rescheduled = try XCTUnwrap(preferences.allowing(tracker.announcementIfNew(pending(in: 7200), now: now)))
        XCTAssertEqual(rescheduled.kind, .rescheduled)
    }

    func testSwitchedOnAnnouncementPassesThrough() {
        let tracker = AnnouncementTracker(store: InMemoryNotifiedStore())
        XCTAssertNotNil(NotificationPreferences().allowing(tracker.announcementIfNew(pending(in: 3600), now: now)))
    }

    func testSwitchedOffLandedIsDroppedButStillRecorded() {
        let store = InMemoryLandedStore()
        let tracker = LandingTracker(store: store)
        var preferences = NotificationPreferences(landed: false)

        XCTAssertNil(preferences.allowing(landed: tracker.landedIfNew(latest("a"))))
        XCTAssertNil(preferences.allowing(landed: tracker.landedIfNew(latest("b"))))
        XCTAssertEqual(store.id, "b")

        // Back on: the reset that landed meanwhile is not reported, the next one is.
        preferences.landed = true
        XCTAssertNil(preferences.allowing(landed: tracker.landedIfNew(latest("b"))))
        XCTAssertEqual(preferences.allowing(landed: tracker.landedIfNew(latest("c")))?.id, "c")
    }

    func testReminderIsPlannedOnlyWhileSwitchedOn() {
        let reset = pending(in: 3600)
        var preferences = NotificationPreferences(reminder: false)
        XCTAssertNil(preferences.plannedReminder(for: reset, now: now))

        // Back on: the pending dated reset is planned again, with no state to catch up on.
        preferences.reminder = true
        XCTAssertEqual(
            preferences.plannedReminder(for: reset, now: now),
            Reminder(resetID: "a", scheduledFor: now.addingTimeInterval(3600)))
    }

    func testReminderStaysOffWhenNothingIsPlannable() {
        let preferences = NotificationPreferences()
        XCTAssertNil(preferences.plannedReminder(for: nil, now: now))
        XCTAssertNil(preferences.plannedReminder(for: pending(in: 600), now: now))
    }

    func testKindsAreIndependent() {
        let preferences = NotificationPreferences(announced: false, reminder: true, landed: false)
        XCTAssertNotNil(preferences.plannedReminder(for: pending(in: 3600), now: now))
    }
}
