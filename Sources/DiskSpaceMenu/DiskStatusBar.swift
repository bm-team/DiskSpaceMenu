import AppKit
import Combine
import SwiftUI

@MainActor
final class DiskStatusBar: NSObject {
    private let store: DiskStore
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private var volumeSubscription: AnyCancellable?

    init(store: DiskStore) {
        self.store = store
        super.init()

        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: DiskPanel(store: store))

        if let button = statusItem.button {
            let icon = NSImage(systemSymbolName: "internaldrive", accessibilityDescription: "Диск")
            icon?.size = NSSize(width: 11, height: 11)
            icon?.isTemplate = true
            button.image = icon
            button.imagePosition = .imageLeft
            button.imageScaling = .scaleProportionallyDown
            button.target = self
            button.action = #selector(togglePopover)
            button.toolTip = "Ёмкость внутреннего тома / свободное место"
        }

        volumeSubscription = store.$volumes.sink { [weak self] volumes in
            self?.updateLabel(with: volumes.first(where: \.isInternal))
        }
    }

    private func updateLabel(with volume: DiskVolume?) {
        let font = NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .regular)
        statusItem.button?.attributedTitle = NSAttributedString(
            string: Self.shortStatus(volume),
            attributes: [.font: font, .foregroundColor: NSColor.labelColor]
        )
        statusItem.button?.setAccessibilityLabel(volume.map {
            "Внутренний диск: ёмкость тома \(amount($0.total)), свободно \(amount($0.free))"
        } ?? "Внутренний диск недоступен")
    }

    private static func shortStatus(_ volume: DiskVolume?) -> String {
        guard let volume else { return "—/—" }

        let total = amount(volume.total).replacingOccurrences(of: " ", with: "")
        let free = amount(volume.free).replacingOccurrences(of: " ", with: "")
        if total.hasSuffix("ГБ"), free.hasSuffix("ГБ") {
            return "\(total.dropLast(2))/\(free.dropLast(2))ГБ"
        }
        return "\(total)/\(free)"
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
