import Foundation
import os

/// Persistence for the id of the latest reset already seen.
public protocol LandedStore {
    func load() -> String?
    func save(_ id: String)
}

/// Decides when a reset has landed: the latest reset changes to a new id, announced beforehand or not.
/// A pending reset that merely disappears was called off, which never reaches this type.
public struct LandingTracker {
    private let store: LandedStore

    public init(store: LandedStore) {
        self.store = store
    }

    /// Returns the reset that just landed, if any, and remembers it so it is reported only once.
    /// The first id ever seen is history, so it is recorded without being reported.
    public func landedIfNew(_ latest: Reset?) -> Reset? {
        guard let latest else {
            Log.notify.notice("landing skipped: no latest reset")
            return nil
        }
        let previous = store.load()
        guard previous != latest.id else {
            Log.notify.notice("landing skipped: reset \(latest.id, privacy: .public) already seen")
            return nil
        }

        store.save(latest.id)
        if previous == nil {
            Log.notify.notice("first run: recorded reset \(latest.id, privacy: .public) as history, no notification")
            return nil
        }
        Log.notify.notice("reset \(latest.id, privacy: .public) landed")
        return latest
    }
}
