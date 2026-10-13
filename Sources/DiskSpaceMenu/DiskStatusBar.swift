import AppKit
import Combine
import SwiftUI

@MainActor
final class DiskStatusBar: NSObject {
    private let store: DiskStore
    private let displaySettings: StatusDisplaySettings
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private var volumeSubscription: AnyCancellable?
    private var settingsSubscription: AnyCancellable?

    init(store: DiskStore, displaySettings: StatusDisplaySettings) {
        self.store = store
        self.displaySettings = displaySettings
        super.init()

        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: DiskPanel(store: store, displaySettings: displaySettings))

        if let button = statusItem.button {
            button.imagePosition = .imageOnly
            button.imageScaling = .scaleNone
            button.target = self
            button.action = #selector(togglePopover)
            button.toolTip = "Ёмкость внутреннего тома / свободное место"
        }

        volumeSubscription = store.$volumes.sink { [weak self] volumes in
            guard let self else { return }
            self.updateLabel(with: volumes.first(where: \.isInternal),
                             layout: self.displaySettings.layout, fontSize: self.displaySettings.activeSize)
        }
        settingsSubscription = Publishers.CombineLatest3(
            displaySettings.$layout, displaySettings.$oneLineSize, displaySettings.$twoLineSize
        ).sink { [weak self] layout, oneLineSize, twoLineSize in
            guard let self else { return }
            self.updateLabel(with: self.store.internalVolume, layout: layout,
                             fontSize: layout == .oneLine ? oneLineSize : twoLineSize)
        }
    }

    private func updateLabel(with volume: DiskVolume?, layout: StatusLayout, fontSize: Double) {
        statusItem.button?.image = StatusBadgeRenderer.image(for: volume, layout: layout, fontSize: fontSize)
        statusItem.button?.setAccessibilityLabel(volume.map {
            "Внутренний диск: ёмкость тома \(amount($0.total)), свободно \(amount($0.free))"
        } ?? "Внутренний диск недоступен")
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.close()
        } else {
            store.refresh()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
