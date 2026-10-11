import SwiftUI

private func menuBarAmount(_ bytes: UInt64) -> String {
    amount(bytes).replacingOccurrences(of: " ", with: "")
}

private func menuBarStatus(_ volume: DiskVolume?) -> String {
    guard let volume else { return "З — · С —" }

    if volume.used >= 1_000_000_000, volume.used < 1_000_000_000_000,
       volume.free >= 1_000_000_000, volume.free < 1_000_000_000_000 {
        let used = menuBarAmount(volume.used).replacingOccurrences(of: "ГБ", with: "")
        let free = menuBarAmount(volume.free).replacingOccurrences(of: "ГБ", with: "")
        return "З \(used) · С \(free) ГБ"
    }

    return "З \(menuBarAmount(volume.used)) · С \(menuBarAmount(volume.free))"
}

@main
struct DiskSpaceMenuApp: App {
    @StateObject private var store = DiskStore()

    var body: some Scene {
        MenuBarExtra {
            DiskPanel(store: store)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "internaldrive")
                Text(menuBarStatus(store.internalVolume))
                    .font(.system(size: 11, weight: .medium))
                    .monospacedDigit()
            }
            .fixedSize()
            .help("Внутренний диск: З — занято, С — свободно")
            .accessibilityLabel(store.internalVolume.map {
                "Внутренний диск: занято \(amount($0.used)), свободно \(amount($0.free))"
            } ?? "Внутренний диск недоступен")
        }
        .menuBarExtraStyle(.window)
    }
}
