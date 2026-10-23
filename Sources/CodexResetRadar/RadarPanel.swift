import RadarCore
import ServiceManagement
import SwiftUI

struct RadarPanel: View {
    @EnvironmentObject private var model: RadarModel
    @EnvironmentObject private var updater: Updater

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sweeps = 0
    @State private var codexWord = SecretWord("codex")
    @State private var keyMonitor: Any?

    private let isTranslocated = Translocation.isTranslocated(bundleURL: Bundle.main.bundleURL)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Divider()
            NotificationsOffWarning(access: model.notificationAccess)
            announcement
            if let watch = model.forecast {
                WatchForecast(watch: watch)
            }
            Divider()
            history
            Divider()
            footer
        }
        .padding(14)
        .frame(width: 320)
        // Report the content's exact height, so the panel window fits it instead of leaving blank strips.
        .fixedSize(horizontal: false, vertical: true)
        .tint(.signalBlue)
        .modifier(NoFocusEffect())
        // A button usually holds keyboard focus in the panel, and AppKit controls take key presses
        // before `onKeyPress` would see them, so the panel's key events are watched directly.
        .onAppear(perform: watchForSecretWord)
        // The panel is hidden and shown again rather than rebuilt, so a half-typed word is
        // dropped when its window closes.
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { _ in
            codexWord.reset()
        }
    }

    /// Only the letters of the word are taken, so every other key reaches the focused control.
    private func watchForSecretWord() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard event.window is MenuBarPanel,
                event.modifierFlags.intersection([.command, .option, .control]).isEmpty,
                let letter = event.charactersIgnoringModifiers?.first, codexWord.isPart(of: letter)
            else { return event }
            if codexWord.type(letter) {
                ping()
            }
            return nil
        }
    }

    /// Easter egg: typing "codex" sweeps the radar once and plays a short system sound.
    /// Under Reduce Motion, the sound alone.
    private func ping() {
        NSSound(named: "Ping")?.play()
        if !reduceMotion {
            sweeps += 1
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            // The menu bar's radar symbol: the needle and outer ring turn once for each sweep.
            MenuBarLabel.radar
                .symbolEffect(.rotate.byLayer, value: sweeps)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("Codex Reset Radar").font(.headline)
            Spacer()
            Button {
                model.refresh(.manual)
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .disabled(model.isRefreshing)
            .help("Check now")
        }
    }

    @ViewBuilder
    private var announcement: some View {
        if let reset = model.pending {
            VStack(alignment: .leading, spacing: 6) {
                Label("\(reset.typeLabel) announced", systemImage: "bell.badge.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tint)
                if let when = reset.scheduledFor {
                    Text(Format.when(when)).font(.title3.weight(.semibold))
                    Text(
                        when > model.now
                            ? String(localized: "in \(Format.spokenCountdown(to: when, from: model.now))")
                            : String(localized: "Scheduled time passed, waiting for it to land")
                    )
                    .foregroundStyle(.secondary)
                } else {
                    Text("Time not given yet").foregroundStyle(.secondary)
                }
                Text("“\(reset.text)”")
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)
                if let url = reset.source.url {
                    Link("View post", destination: url).font(.callout)
                }
            }
        } else if model.status != nil {
            Label("No reset announced", systemImage: "moon.zzz")
                .foregroundStyle(.secondary)
        } else {
            Text(model.lastError == nil ? LocalizedStringKey("Checking…") : "Couldn't reach codex-resets.com")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var history: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let last = model.status?.latestReset {
                Text("Last reset \(Format.relative(last.announcedAt, to: model.now))")
            }
            if let avg = model.status?.stats.avgIntervalDays {
                Text("Every \(avg, specifier: "%.1f") days on average")
                    .foregroundStyle(.secondary)
            }
            if let checked = model.lastChecked {
                Text("Checked \(checked.formatted(date: .omitted, time: .shortened))")
                    .foregroundStyle(.secondary)
            }
            if let error = model.lastError {
                Text(error).foregroundStyle(.red)
            }
        }
        .font(.callout)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isTranslocated {
                TranslocationWarning()
            }
            LaunchAtLoginToggle()
                .disabled(isTranslocated)
            NotificationSwitches()
            Link("Data from codex-resets.com", destination: URL(string: "https://codex-resets.com")!)
                .font(.caption)
            // Its own row: next to the link, the buttons overflow the panel width, above all in Italian.
            HStack {
                Button("Check for Updates…") { updater.checkForUpdates() }
                    .disabled(!updater.canCheckForUpdates)
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .keyboardShortcut("q")
            }
        }
    }
}

/// Matches a word typed one letter at a time, ignoring case. It remembers only how far into the word it is.
private struct SecretWord {
    private let letters: [Character]
    private var matched = 0

    init(_ word: String) {
        letters = Array(word.lowercased())
    }

    /// Whether `letter` is one this word can use, so any other key is left alone.
    func isPart(of letter: Character) -> Bool {
        letters.contains(Character(letter.lowercased()))
    }

    /// Takes the next letter; true when it completes the word.
    mutating func type(_ letter: Character) -> Bool {
        let letter = Character(letter.lowercased())
        if letter == letters[matched] {
            matched += 1
        } else {
            matched = letter == letters[0] ? 1 : 0
        }
        guard matched == letters.count else { return false }
        matched = 0
        return true
    }

    mutating func reset() {
        matched = 0
    }
}

/// The panel opens with keyboard focus on its first link, which then shows a focus ring
/// as if it were selected. Clicking still works; only the ring goes.
private struct NoFocusEffect: ViewModifier {
    func body(content: Content) -> some View {
        content.focusEffectDisabled()
    }
}

extension Color {
    /// Brand accent, #267CFF.
    fileprivate static let signalBlue = Color(red: 0x26 / 255, green: 0x7C / 255, blue: 0xFF / 255)
}

/// The source's AI guess that a reset may be coming. Deliberately quieter than an announcement:
/// secondary colour, its own icon, and a line saying it is a guess.
private struct WatchForecast: View {
    let watch: Watch

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Forecast", systemImage: "sparkles")
                .font(.subheadline.weight(.semibold))
            if let chance = watch.resetChancePercent {
                Text("\(watch.levelLabel), \(chance)% chance")
            } else {
                Text(watch.levelLabel)
            }
            Text(verbatim: watch.forecastWindow)
            Text("“\(watch.text)”")
                .italic()
                .fixedSize(horizontal: false, vertical: true)
            if let url = watch.source.url {
                Link("View source", destination: url).font(.callout)
            }
            Text("AI guess, not an announcement")
                .font(.caption)
        }
        .foregroundStyle(.secondary)
    }
}

private struct TranslocationWarning: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Running from a temporary location", systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.orange)
            Text(
                """
                Quit, move Codex Reset Radar to Applications and open it from there. \
                Launch at login is disabled until then, because it would point at a path that disappears.
                """
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// A setting as macOS System Settings shows it: the label on the left, a switch on the right edge.
private struct SwitchRow<Accessory: View>: View {
    private let title: LocalizedStringKey
    @Binding private var isOn: Bool
    private let accessory: Accessory

    /// `accessory` sits right after the label, before the switch.
    init(_ title: LocalizedStringKey, isOn: Binding<Bool>, @ViewBuilder accessory: () -> Accessory) {
        self.title = title
        _isOn = isOn
        self.accessory = accessory()
    }

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack {
                Text(title)
                accessory
                Spacer(minLength: 0)
            }
        }
        .toggleStyle(.switch)
        // System Settings uses the mini switch; the regular one dwarfs the panel's text.
        .controlSize(.mini)
    }
}

extension SwitchRow where Accessory == EmptyView {
    init(_ title: LocalizedStringKey, isOn: Binding<Bool>) {
        self.init(title, isOn: isOn) { EmptyView() }
    }
}

private struct LaunchAtLoginToggle: View {
    @State private var state = Self.currentState()
    @State private var failure: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // The binding reads the service state, so a failed change has nothing to revert and
            // no change handler can call register/unregister a second time.
            SwitchRow("Launch at login", isOn: Binding(get: { state.isOn }, set: { setEnabled($0) }))
            if let hint = state.approvalHint {
                Text(hint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Open Login Items") { SMAppService.openSystemSettingsLoginItems() }
                    .font(.caption)
            }
            if let failure {
                Text(failure)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onAppear(perform: refresh)
        // The panel view can outlive the window, so onAppear alone may miss later openings.
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            refresh()
        }
    }

    private static func currentState() -> LoginItemToggleState {
        LoginItemToggleState(status: LoginItemStatus(SMAppService.mainApp.status))
    }

    private func refresh() {
        state = Self.currentState()
        failure = nil
    }

    private func setEnabled(_ wanted: Bool) {
        do {
            if wanted {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            failure = nil
        } catch {
            let reason = error.localizedDescription
            failure =
                wanted
                ? String(localized: "Couldn't enable launch at login: \(reason)")
                : String(localized: "Couldn't disable launch at login: \(reason)")
        }
        state = Self.currentState()
    }
}

/// One checkbox per kind of notification, applied as soon as it is clicked.
private struct NotificationSwitches: View {
    @EnvironmentObject private var model: RadarModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Notify me about")
                .font(.caption)
                .foregroundStyle(.secondary)
            SwitchRow("Announced", isOn: binding(\.announced))
            SwitchRow("Reminder", isOn: binding(\.reminder)) {
                Picker("Reminder lead time", selection: leadTime) {
                    ForEach(ReminderLeadTime.allCases, id: \.self) { lead in
                        Text("\(lead.rawValue) min").tag(lead)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .fixedSize()
                .controlSize(.small)
                .disabled(!model.notificationPreferences.reminder)
            }
            SwitchRow("Landed", isOn: binding(\.landed))
        }
    }

    private var leadTime: Binding<ReminderLeadTime> {
        Binding(
            get: { model.notificationPreferences.reminderLeadTime },
            set: { lead in
                var preferences = model.notificationPreferences
                preferences.reminderLeadTime = lead
                model.setNotificationPreferences(preferences)
            })
    }

    private func binding(_ kind: WritableKeyPath<NotificationPreferences, Bool>) -> Binding<Bool> {
        Binding(
            get: { model.notificationPreferences[keyPath: kind] },
            set: { wanted in
                var preferences = model.notificationPreferences
                preferences[keyPath: kind] = wanted
                model.setNotificationPreferences(preferences)
            })
    }
}

extension LoginItemStatus {
    fileprivate init(_ status: SMAppService.Status) {
        switch status {
        case .enabled: self = .enabled
        case .requiresApproval: self = .requiresApproval
        case .notFound: self = .notFound
        case .notRegistered: self = .notRegistered
        @unknown default: self = .notRegistered
        }
    }
}
