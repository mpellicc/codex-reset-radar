import AppKit
import Foundation
import Network
import RadarCore
import os

@MainActor
final class RadarModel: ObservableObject {
    @Published private(set) var status: StatusData?
    @Published private(set) var lastChecked: Date?
    @Published private(set) var lastError: String?
    @Published private(set) var isRefreshing = false
    /// True after two polls in a row failed; the menu bar icon shows it.
    @Published private(set) var isOffline = false
    /// Ticks every minute so countdowns stay current between polls.
    @Published private(set) var now = Date()

    private static let pollInterval: TimeInterval = 15 * 60

    private let client = StatusClient()
    private let notifier = Notifier()
    let notificationAccess = NotificationAccessMonitor()
    private var timers: [Timer] = []
    private var pollTimer: Timer?
    private var retryTimer: Timer?
    private var wakeObserver: NSObjectProtocol?
    private let pathMonitor = NWPathMonitor()
    private var reconnect = ReconnectDebounce()
    private var failures = FailureCounter()
    /// Set after a 429 (or 503 with `Retry-After`); polls before it are skipped.
    private var retryNotBefore: Date?

    init() {
        refresh(.launch)

        let poll = Timer.scheduledTimer(withTimeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh(.timer) }
        }
        poll.tolerance = 60
        let tick = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.now = Date() }
        }
        tick.tolerance = 5
        timers = [poll, tick]
        pollTimer = poll

        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refresh(.wake) }
        }

        // Runs on the monitor's queue, so the closure must not be main-actor isolated.
        pathMonitor.pathUpdateHandler = { @Sendable [weak self] path in
            let satisfied = path.status == .satisfied
            Task { @MainActor in self?.pathChanged(satisfied: satisfied) }
        }
        pathMonitor.start(queue: DispatchQueue(label: "CodexResetRadar.pathMonitor"))
    }

    var pending: ScheduledReset? { status?.scheduledReset }

    func refresh(_ trigger: RefreshTrigger) {
        guard !isRefreshing else {
            Log.poll.notice("refresh (\(trigger.rawValue, privacy: .public)) skipped: one is already running")
            return
        }
        if let retryNotBefore, Date() < retryNotBefore {
            Log.poll.notice(
                "refresh (\(trigger.rawValue, privacy: .public)) skipped: paused until \(retryNotBefore.ISO8601Format(), privacy: .public)"
            )
            return
        }
        Log.poll.notice("refresh (\(trigger.rawValue, privacy: .public)) started")
        isRefreshing = true
        Task {
            defer { isRefreshing = false }
            let wasOffline = isOffline
            do {
                let status = try await client.fetch()
                self.status = status
                lastError = nil
                retryNotBefore = nil
                failures.recordSuccess()
                isOffline = false
                notifier.process(status)
            } catch {
                let failure = PollFailure(error, now: Date(), nextRegularPoll: nextRegularPoll)
                let nsError = error as NSError
                Log.poll.error(
                    "refresh (\(trigger.rawValue, privacy: .public)) failed: \(failure.message, privacy: .public) [\(nsError.domain, privacy: .public) \(nsError.code, privacy: .public)], \(self.failures.count + 1, privacy: .public) in a row"
                )
                lastError = failure.message
                failures.recordFailure()
                isOffline = failures.isOffline
                retryNotBefore = failure.retryNotBefore
                if let until = failure.retryNotBefore {
                    Log.poll.notice("polling paused until \(until.ISO8601Format(), privacy: .public)")
                }
                scheduleRetry(at: failure.retryNotBefore)
            }
            if isOffline != wasOffline {
                Log.poll.notice("offline state changed: \(self.isOffline ? "offline" : "online", privacy: .public)")
            }
            lastChecked = Date()
            now = Date()
        }
    }

    private var nextRegularPoll: Date {
        pollTimer?.fireDate ?? Date().addingTimeInterval(Self.pollInterval)
    }

    private func pathChanged(satisfied: Bool) {
        let shouldRefresh = reconnect.shouldRefresh(pathSatisfied: satisfied, now: Date())
        Log.poll.notice(
            "network \(satisfied ? "reachable" : "unreachable", privacy: .public), reconnect refresh \(shouldRefresh ? "due" : "not due", privacy: .public)"
        )
        if shouldRefresh {
            refresh(.reconnect)
        }
    }

    /// Polls again right when a `Retry-After` runs out, unless the regular poll comes first anyway.
    private func scheduleRetry(at date: Date?) {
        retryTimer?.invalidate()
        retryTimer = nil
        guard let date, date < nextRegularPoll else { return }
        Log.poll.notice("retry-after refresh scheduled for \(date.ISO8601Format(), privacy: .public)")
        retryTimer = Timer.scheduledTimer(withTimeInterval: max(date.timeIntervalSinceNow, 1), repeats: false) {
            [weak self] _ in
            Task { @MainActor in self?.refresh(.retryAfter) }
        }
    }
}
