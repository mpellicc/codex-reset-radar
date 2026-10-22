import Foundation

public enum VoiceOverLabel {
    /// What VoiceOver reads for the menu bar item, which otherwise is a bare icon and a terse countdown.
    /// `loaded` is whether a status has ever been fetched; `pending` is the announced reset, if any.
    public static func menuBar(loaded: Bool, pending: ScheduledReset?, isOffline: Bool, now: Date) -> String {
        let name = "Codex Reset Radar"
        let reset = resetSummary(loaded: loaded, pending: pending, now: now)
        if isOffline {
            // The countdown stays on screen next to the offline icon, so keep speaking it.
            let known = loaded && pending != nil
            return known ? String(localized: "\(name), offline, \(reset)") : String(localized: "\(name), offline")
        }
        return "\(name), \(reset)"
    }

    private static func resetSummary(loaded: Bool, pending: ScheduledReset?, now: Date) -> String {
        guard loaded else { return String(localized: "checking for resets") }
        guard let pending else { return String(localized: "no reset announced") }
        guard let when = pending.scheduledFor else { return String(localized: "reset announced, time not given yet") }
        guard when > now else { return String(localized: "reset due") }
        return String(localized: "reset in \(Format.spokenCountdown(to: when, from: now))")
    }
}
