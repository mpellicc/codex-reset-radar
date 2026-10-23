import AppKit
import Combine
import RadarCore
import SwiftUI

/// The menu bar item and the panel it opens.
///
/// It is an NSStatusItem hosting a live SwiftUI view, not a `MenuBarExtra`: a `MenuBarExtra` label is
/// drawn once into a static image, so symbol effects on the radar never animate (ADR 0003).
@MainActor
final class MenuBarItem: NSObject {
    private let model: RadarModel
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let label: NSHostingView<MenuBarLabel>
    private let panel: MenuBarPanel
    private var cancellable: AnyCancellable?

    init(model: RadarModel, updater: Updater) {
        self.model = model
        label = NSHostingView(rootView: MenuBarLabel(model: model))
        panel = MenuBarPanel(
            content: RadarPanel()
                .environmentObject(model)
                .environmentObject(updater))
        super.init()

        guard let button = item.button else { return }
        label.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: button.centerYAnchor),
        ])
        button.target = self
        button.action = #selector(toggle)
        // Open on press, as menus do, not on release.
        button.sendAction(on: [.leftMouseDown, .rightMouseDown])
        panel.onClose = { [weak self] in self?.item.button?.highlight(false) }

        // The label's width follows the countdown, and VoiceOver reads the button, not the hosted view.
        cancellable = model.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async { self?.update() }
        }
        update()
    }

    private func update() {
        label.layoutSubtreeIfNeeded()
        item.length = label.fittingSize.width + 2 * Self.padding
        item.button?.setAccessibilityLabel(
            VoiceOverLabel.menuBar(
                loaded: model.status != nil, pending: model.pending, isOffline: model.isOffline, now: model.now))
    }

    @objc private func toggle() {
        if panel.isVisible {
            panel.close()
            return
        }
        guard let anchor = clickedItemFrame() else { return }
        item.button?.highlight(true)
        panel.show(below: anchor)
    }

    /// The button's frame on screen. With more than one display, each menu bar shows its own copy of
    /// the item in its own window, so the panel opens under the copy under the mouse.
    private func clickedItemFrame() -> NSRect? {
        guard let button = item.button, let window = button.window else { return nil }
        let mouse = NSEvent.mouseLocation
        let clicked = NSApp.windows.first { $0.className == "NSStatusBarWindow" && $0.frame.contains(mouse) }
        return button.convert(button.bounds, to: nil)
            .offsetBy(dx: (clicked ?? window).frame.minX, dy: (clicked ?? window).frame.minY)
    }

    /// Space on each side of the label, like the padding of a system menu bar item.
    private static let padding: CGFloat = 4
}

/// The radar, and the countdown while a dated reset is pending.
struct MenuBarLabel: View {
    @ObservedObject var model: RadarModel

    var body: some View {
        HStack(spacing: 4) {
            if model.isOffline {
                Image(systemName: "antenna.radiowaves.left.and.right.slash")
            } else {
                Self.radar
            }
            if let when = model.pending?.scheduledFor {
                Text(Format.countdown(to: when, from: model.now))
            }
        }
        .font(.system(size: NSFont.menuBarFont(ofSize: 0).pointSize))
        .fixedSize()
        // The status item's button carries the VoiceOver label.
        .accessibilityHidden(true)
    }

    // The custom symbol is compiled into the built .app only; `swift run` falls back to an SF Symbol.
    static let radar: Image =
        NSImage(symbolName: "RadarMenuBar", bundle: .main, variableValue: 1) != nil
        ? Image("RadarMenuBar") : Image(systemName: "dot.radiowaves.left.and.right")
}

/// The panel under the menu bar item. It floats without activating the app, so the app the user is
/// working in keeps its focus, and closes on Escape or a click anywhere else.
@MainActor
final class MenuBarPanel: NSPanel {
    var onClose: (() -> Void)?
    private var outsideClicks: Any?
    private var anchor: NSRect = .zero

    init(content: some View) {
        super.init(
            contentRect: .zero, styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered, defer: true)
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        for kind in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
            standardWindowButton(kind)?.isHidden = true
        }
        isMovable = false
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        level = .statusBar
        collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary, .transient]
        animationBehavior = .utilityWindow

        let background = NSVisualEffectView()
        background.material = .menu
        background.blendingMode = .behindWindow
        background.state = .active
        let host = NSHostingView(rootView: content)
        // The window takes the content's exact size, and follows it when the content grows or shrinks.
        host.sizingOptions = [.minSize, .intrinsicContentSize, .maxSize]
        host.translatesAutoresizingMaskIntoConstraints = false
        background.addSubview(host)
        NSLayoutConstraint.activate([
            host.leadingAnchor.constraint(equalTo: background.leadingAnchor),
            host.trailingAnchor.constraint(equalTo: background.trailingAnchor),
            host.topAnchor.constraint(equalTo: background.topAnchor),
            host.bottomAnchor.constraint(equalTo: background.bottomAnchor),
        ])
        contentView = background

        // Keep the top edge under the menu bar item when the content changes height.
        NotificationCenter.default.addObserver(
            self, selector: #selector(keepAnchored), name: NSWindow.didResizeNotification, object: self)
    }

    override var canBecomeKey: Bool { true }

    func show(below anchor: NSRect) {
        self.anchor = anchor
        keepAnchored()
        makeKeyAndOrderFront(nil)
        outsideClicks = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) {
            [weak self] _ in
            Task { @MainActor in self?.close() }
        }
    }

    override func close() {
        if let outsideClicks { NSEvent.removeMonitor(outsideClicks) }
        outsideClicks = nil
        super.close()
        onClose?()
    }

    override func resignKey() {
        super.resignKey()
        if isVisible { close() }
    }

    override func cancelOperation(_ sender: Any?) {
        close()
    }

    /// Puts the panel's top-left corner just under the menu bar, below the item, kept inside the screen.
    @objc private func keepAnchored() {
        guard anchor != .zero else { return }
        let screen = NSScreen.screens.first { $0.frame.intersects(anchor) } ?? NSScreen.main
        var origin = NSPoint(x: anchor.minX, y: anchor.minY - frame.height - Self.gap)
        if let visible = screen?.visibleFrame {
            origin.x = min(max(origin.x, visible.minX + Self.gap), visible.maxX - frame.width - Self.gap)
            origin.y = min(anchor.minY, visible.maxY) - frame.height - Self.gap
        }
        if frame.origin != origin { setFrameOrigin(origin) }
    }

    private static let gap: CGFloat = 4
}
