import AppIntents
import Foundation
import RadarCore

/// "Get Next Codex Reset": the pending reset the app already knows about, for Shortcuts and Siri.
/// It runs in the app's process and reads the model the panel shows. It never polls on its own.
struct NextResetIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Next Codex Reset"
    static let description = IntentDescription(
        "Returns the pending Codex reset, or nothing when no reset is announced.")

    @Dependency private var model: RadarModel

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<PendingResetEntity?> & ProvidesDialog {
        // Right after a launch the first poll may still be running; wait for it rather than answer "none".
        for _ in 0..<40 where model.status == nil && model.isRefreshing {
            try await Task.sleep(nanoseconds: 250_000_000)
        }
        guard model.status != nil else { throw NextResetError.notLoaded }
        guard let pending = model.pending else {
            return .result(value: nil, dialog: "No Codex reset is announced.")
        }
        let entity = PendingResetEntity(pending)
        let noun = pending.typeNoun
        guard let when = pending.scheduledFor else {
            return .result(value: entity, dialog: "A Codex \(noun) is announced, but its time isn't given yet.")
        }
        let date = Format.when(when)
        guard when > Date() else {
            return .result(value: entity, dialog: "A Codex \(noun) was due \(date) and hasn't landed yet.")
        }
        let countdown = Format.spokenCountdown(to: when, from: Date())
        return .result(value: entity, dialog: "The next Codex \(noun) is \(date), in \(countdown).")
    }
}

enum NextResetError: Error, CustomLocalizedStringResourceConvertible {
    case notLoaded

    var localizedStringResource: LocalizedStringResource {
        "Codex Reset Radar hasn't loaded the reset status yet. Try again in a moment."
    }
}

/// The pending reset as Shortcuts sees it.
struct PendingResetEntity: TransientAppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Codex Reset"

    @Property(title: "Scheduled For") var scheduledFor: Date?
    /// The API's `reset_type`: `regular` or `banked`.
    @Property(title: "Type") var type: String
    @Property(title: "Announcement") var text: String
    @Property(title: "Source") var source: URL?

    init() {
        type = ""
        text = ""
    }

    init(_ reset: ScheduledReset) {
        self.init()
        scheduledFor = reset.scheduledFor
        type = reset.resetType
        text = reset.text
        source = reset.source.url
    }

    var displayRepresentation: DisplayRepresentation {
        let title: LocalizedStringResource = type == "banked" ? "Banked reset" : "Reset"
        guard let scheduledFor else {
            return DisplayRepresentation(title: title, subtitle: "Time not given yet")
        }
        return DisplayRepresentation(title: title, subtitle: "Scheduled for \(Format.when(scheduledFor))")
    }
}

struct RadarShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: NextResetIntent(),
            phrases: [
                "When is the next Codex reset in \(.applicationName)",
                "Get the next Codex reset from \(.applicationName)",
                "Next Codex reset in \(.applicationName)",
            ],
            shortTitle: "Next Codex Reset",
            systemImageName: "dot.radiowaves.left.and.right"
        )
    }
}
