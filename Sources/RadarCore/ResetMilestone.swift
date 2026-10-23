import Foundation

/// The round-number reset counts that get a mention in the landed notification.
public enum ResetMilestone {
    /// The first milestone, and the step between milestones after it.
    private static let first = 100
    private static let step = 50

    /// The reset number to celebrate when the reset that just landed made `total` a round number
    /// (100, 150, 200, …), or nil for any other count, including an unknown one.
    ///
    /// The landed notification fires once per reset id (`LandingTracker`) and each reset raises the
    /// total by one, so a milestone can only be reported once.
    public static func reached(total: Int?) -> Int? {
        guard let total, total >= first, (total - first) % step == 0 else { return nil }
        return total
    }
}
