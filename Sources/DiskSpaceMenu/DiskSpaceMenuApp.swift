import SwiftUI

private func menuBarAmount(_ bytes: UInt64) -> String {
    amount(bytes).replacingOccurrences(of: " ", with: "")
}

private func menuBarStatus(_ volume: DiskVolume?) -> String {
    guard let volume else { return "—/—" }

    if volume.total >= 1_000_000_000, volume.total < 1_000_000_000_000,
       volume.free >= 1_000_000_000, volume.free < 1_000_000_000_000 {
        let total = menuBarAmount(volume.total).replacingOccurrences(of: "ГБ", with: "")
        let free = menuBarAmount(volume.free).replacingOccurrences(of: "ГБ", with: "")
        return "\(total)/\(free) ГБ"
    }

    return "\(menuBarAmount(volume.total))/\(menuBarAmount(volume.free))"
}

@main
struct DiskSpaceMenuApp: App {
    @StateObject private var store = DiskStore()

    var body: some Scene {
        MenuBarExtra {
            DiskPanel(store: store)
        } label: {
            Text(menuBarStatus(store.internalVolume))
                .font(.system(size: 10, weight: .regular))
                .monospacedDigit()
                .fixedSize()
                .help("Внутренний диск: ёмкость тома / свободно")
                .accessibilityLabel(store.internalVolume.map {
                    "Внутренний диск: ёмкость тома \(amount($0.total)), свободно \(amount($0.free))"
                } ?? "Внутренний диск недоступен")
        }
        .menuBarExtraStyle(.window)
    }
}
