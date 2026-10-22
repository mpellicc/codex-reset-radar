import RadarCore
import ServiceManagement
import SwiftUI

struct RadarPanel: View {
    @EnvironmentObject private var model: RadarModel
    @EnvironmentObject private var updater: Updater

    private let isTranslocated = Translocation.isTranslocated(bundleURL: Bundle.main.bundleURL)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Divider()
            NotificationsOffWarning(access: model.notificationAccess)
            announcement
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
    }

    private var header: some View {
        HStack {
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

/// The panel opens with keyboard focus on its first link, which then shows a focus ring
/// as if it were selected. Clicking still works; only the ring goes.
private struct NoFocusEffect: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 14.0, *) {
            content.focusEffectDisabled()
        } else {
            content
        }
    }
}

extension Color {
    /// Brand accent, #267CFF.
    fileprivate static let signalBlue = Color(red: 0x26 / 255, green: 0x7C / 255, blue: 0xFF / 255)
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
private struct SwitchRow: View {
    private let title: String
    @Binding private var isOn: Bool

    init(_ title: String, isOn: Binding<Bool>) {
        self.title = title
        _isOn = isOn
    }

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title).frame(maxWidth: .infinity, alignment: .leading)
        }
        .toggleStyle(.switch)
        // System Settings uses the mini switch; the regular one dwarfs the panel's text.
        .controlSize(.mini)
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
            SwitchRow("Reminder", isOn: binding(\.reminder))
            SwitchRow("Landed", isOn: binding(\.landed))
        }
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
