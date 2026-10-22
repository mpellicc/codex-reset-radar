import AppKit
import Foundation
import Network
import RadarCore

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
    /// Which kinds of notification are switched on.
    @Published private(set) var notificationPreferences: NotificationPreferences

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
        notificationPreferences = notifier.preferences
        refresh()

        let poll = Timer.scheduledTimer(withTimeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
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
            Task { @MainActor in self?.refresh() }
        }

        // Runs on the monitor's queue, so the closure must not be main-actor isolated.
        pathMonitor.pathUpdateHandler = { @Sendable [weak self] path in
            let satisfied = path.status == .satisfied
            Task { @MainActor in self?.pathChanged(satisfied: satisfied) }
        }
        pathMonitor.start(queue: DispatchQueue(label: "CodexResetRadar.pathMonitor"))
    }

    var pending: ScheduledReset? { status?.scheduledReset }

    func setNotificationPreferences(_ preferences: NotificationPreferences) {
        notifier.update(preferences)
        notificationPreferences = preferences
    }

    func refresh() {
        guard !isRefreshing else { return }
        if let retryNotBefore, Date() < retryNotBefore { return }
        isRefreshing = true
        Task {
            defer { isRefreshing = false }
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
                lastError = failure.message
                failures.recordFailure()
                isOffline = failures.isOffline
                retryNotBefore = failure.retryNotBefore
                scheduleRetry(at: failure.retryNotBefore)
            }
            lastChecked = Date()
            now = Date()
        }
    }

    private var nextRegularPoll: Date {
        pollTimer?.fireDate ?? Date().addingTimeInterval(Self.pollInterval)
    }

    private func pathChanged(satisfied: Bool) {
        if reconnect.shouldRefresh(pathSatisfied: satisfied, now: Date()) {
            refresh()
        }
    }

    /// Polls again right when a `Retry-After` runs out, unless the regular poll comes first anyway.
    private func scheduleRetry(at date: Date?) {
        retryTimer?.invalidate()
        retryTimer = nil
        guard let date, date < nextRegularPoll else { return }
        retryTimer = Timer.scheduledTimer(withTimeInterval: max(date.timeIntervalSinceNow, 1), repeats: false) {
            [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }
}
