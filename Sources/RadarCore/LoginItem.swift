import Foundation

/// Mirrors `SMAppService.Status`, so the library doesn't depend on ServiceManagement.
public enum LoginItemStatus: Equatable, Sendable {
    case notRegistered
    case enabled
    case requiresApproval
    case notFound
}

/// What the Launch at login toggle shows for a login item status.
public struct LoginItemToggleState: Equatable, Sendable {
    public let isOn: Bool
    /// Set while the user still has to approve the item in System Settings.
    public let approvalHint: String?

    public init(status: LoginItemStatus) {
        switch status {
        case .enabled:
            isOn = true
            approvalHint = nil
        case .requiresApproval:
            // Registered but switched off in System Settings. Staying on lets the user unregister it.
            isOn = true
            approvalHint = String(localized: "Approve Codex Reset Radar in System Settings → General → Login Items.")
        case .notRegistered, .notFound:
            isOn = false
            approvalHint = nil
        }
    }
}
