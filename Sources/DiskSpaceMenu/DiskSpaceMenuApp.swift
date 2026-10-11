import AppKit
import SwiftUI

@MainActor
final class DiskSpaceAppDelegate: NSObject, NSApplicationDelegate {
    private var statusBar: DiskStatusBar?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBar = DiskStatusBar(store: DiskStore())
    }
}

@main
struct DiskSpaceMenuApp: App {
    @NSApplicationDelegateAdaptor(DiskSpaceAppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}
