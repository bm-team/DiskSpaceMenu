import AppKit
import Combine

@MainActor
final class DiskStore: ObservableObject {
    @Published private(set) var volumes: [DiskVolume] = []
    @Published private(set) var updating = false
    private var generation = 0
    private var timer: Timer?
    private var observers: [NSObjectProtocol] = []

    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        let workspace = NSWorkspace.shared.notificationCenter
        observers.append(workspace.addObserver(forName: NSWorkspace.didMountNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        })
        observers.append(workspace.addObserver(forName: NSWorkspace.didUnmountNotification, object: nil, queue: .main) { [weak self] note in
            let path = (note.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL)?.path
            Task { @MainActor in
                if let path { self?.volumes.removeAll { $0.mountPath == path } }
                self?.refresh()
            }
        })
        refresh()
    }

    func refresh() {
        generation += 1
        let current = generation
        updating = true
        Task {
            let result = await Task.detached(priority: .utility) { DiskReader.read() }.value
            guard current == generation else { return }
            volumes = result
            updating = false
        }
    }

    var internalVolume: DiskVolume? { volumes.first(where: \.isInternal) }
}
