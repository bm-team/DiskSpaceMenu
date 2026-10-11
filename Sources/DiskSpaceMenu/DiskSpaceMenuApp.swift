import SwiftUI

@main
struct DiskSpaceMenuApp: App {
    @StateObject private var store = DiskStore()

    var body: some Scene {
        MenuBarExtra {
            DiskPanel(store: store)
        } label: {
            Label(store.internalVolume.map { amount($0.free) } ?? "—", systemImage: "internaldrive")
                .help("Свободно на внутреннем диске")
        }
        .menuBarExtraStyle(.window)
    }
}
