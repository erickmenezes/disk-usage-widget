import Foundation

enum DiskReader {
    /// AppIntents' EntityIdentifier cannot round-trip identifiers containing
    /// "/", so a raw volume path is unusable as an AppEntity ID — it decodes to
    /// nil and the widget silently falls back. Prefer the volume UUID (also
    /// stable when an external remounts at a different path); otherwise
    /// hex-encode the path so the result is alphanumeric.
    private static func makeID(uuid: String?, path: String) -> String {
        if let uuid, !uuid.isEmpty { return uuid }
        return "p_" + Data(path.utf8).map { String(format: "%02x", $0) }.joined()
    }

    static func info(for url: URL) -> DiskInfo? {
        let keys: Set<URLResourceKey> = [
            .volumeNameKey, .volumeTotalCapacityKey,
            .volumeAvailableCapacityKey, .volumeUUIDStringKey
        ]
        guard let v = try? url.resourceValues(forKeys: keys),
              let total = v.volumeTotalCapacity,
              let avail = v.volumeAvailableCapacity else { return nil }

        return DiskInfo(
            id: makeID(uuid: v.volumeUUIDString, path: url.path),
            volumeName: v.volumeName ?? url.lastPathComponent,
            path: url.path,
            totalBytes: Int64(total),
            availableBytes: Int64(avail)
        )
    }

    /// Resolve a previously-picked volume by display name (what the widget
    /// configuration stores). Falls back to nil if that volume is unmounted.
    static func info(named name: String) -> DiskInfo? {
        allVolumes().first { $0.volumeName == name }
    }

    /// Boot volume — safe default.
    static func bootVolume() -> DiskInfo? {
        info(for: URL(fileURLWithPath: "/"))
    }

    /// All browsable mounted volumes (for the config picker).
    static func allVolumes() -> [DiskInfo] {
        let keys: [URLResourceKey] = [
            .volumeNameKey, .volumeIsBrowsableKey, .volumeTotalCapacityKey
        ]
        let urls = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: keys,
            options: [.skipHiddenVolumes]
        ) ?? []
        return urls.compactMap(info(for:))
    }
}
