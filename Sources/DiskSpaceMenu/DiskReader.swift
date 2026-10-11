import Foundation

struct DiskVolume: Identifiable, Sendable {
    let id: String
    let name: String
    let total: UInt64
    let free: UInt64
    let isInternal: Bool
    let mountPath: String
    var used: UInt64 { total >= free ? total - free : 0 }
}

enum DiskReader {
    static func plist(_ arguments: [String]) -> [String: Any]? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/diskutil")
        process.arguments = arguments
        let output = Pipe()
        process.standardOutput = output
        process.standardError = Pipe()
        do {
            try process.run()
            let data = output.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            return try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        } catch { return nil }
    }

    static func capacity(_ url: URL) -> (UInt64, UInt64)? {
        var values = statfs()
        guard statfs(url.path, &values) == 0 else { return nil }
        let block = UInt64(values.f_bsize)
        return (UInt64(values.f_blocks) * block, UInt64(values.f_bavail) * block)
    }

    static func isPhysical(_ info: [String: Any], identifiers: Set<String>) -> Bool {
        if let id = info["DeviceIdentifier"] as? String, identifiers.contains(id) { return true }
        if let stores = info["APFSPhysicalStores"] as? [[String: Any]] {
            return stores.contains { store in
                guard let id = store["APFSPhysicalStore"] as? String else { return false }
                return identifiers.contains(id)
            }
        }
        return false
    }

    static func read() -> [DiskVolume] {
        guard let physical = plist(["list", "-plist", "physical"]),
              let identifiers = physical["AllDisks"] as? [String] else { return [] }
        let ids = Set(identifiers)
        var urls = [URL(fileURLWithPath: "/", isDirectory: true)]
        urls += (FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: nil, options: []) ?? [])
            .filter { $0.path.hasPrefix("/Volumes/") }
        var seen = Set<String>()
        return urls.compactMap { url in
            guard let info = plist(["info", "-plist", url.path]),
                  isPhysical(info, identifiers: ids),
                  info["Internal"] as? Bool != nil,
                  let device = info["DeviceIdentifier"] as? String,
                  seen.insert(device).inserted,
                  let (total, free) = capacity(url), total > 0 else { return nil }
            let isInternal = info["Internal"] as? Bool ?? false
            let name = (info["VolumeName"] as? String).flatMap { $0.isEmpty ? nil : $0 }
                ?? (isInternal ? "Внутренний диск" : url.lastPathComponent)
            return DiskVolume(id: device, name: name, total: total, free: free, isInternal: isInternal, mountPath: url.path)
        }.sorted { a, b in
            if a.isInternal != b.isInternal { return a.isInternal }
            return a.name.localizedStandardCompare(b.name) == .orderedAscending
        }
    }
}
