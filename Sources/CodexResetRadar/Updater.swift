import Combine
import Foundation
import Sparkle

/// Sparkle's standard updater: it checks the appcast once a day in the background, and on demand,
/// then downloads, installs and relaunches through its own windows.
@MainActor
final class Updater: ObservableObject {
    @Published private(set) var canCheckForUpdates = false

    private let controller: SPUStandardUpdaterController?
    private var cancellable: AnyCancellable?

    init() {
        // `swift run` has no Info.plist, so there is no feed or key and Sparkle would only show a startup error.
        guard Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") != nil else {
            controller = nil
            return
        }
        let controller = SPUStandardUpdaterController(
            startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        self.controller = controller
        cancellable = controller.updater.publisher(for: \.canCheckForUpdates)
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.canCheckForUpdates = $0 }
    }

    func checkForUpdates() {
        controller?.checkForUpdates(nil)
    }
}
