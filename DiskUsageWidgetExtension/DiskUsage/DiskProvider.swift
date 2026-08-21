import WidgetKit
import OSLog

let duLog = Logger(subsystem: "com.erickmenezes.DiskUsage", category: "provider")

struct DiskEntry: TimelineEntry {
    let date: Date
    /// The volume chosen in the widget config. Used by small/medium.
    let disk: DiskInfo
    /// Every mounted volume. Used by systemLarge, which ignores the picker.
    let allDisks: [DiskInfo]
}

struct DiskProvider: AppIntentTimelineProvider {
    private var fallback: DiskInfo {
        DiskReader.bootVolume()
            ?? DiskInfo(id: "placeholder", volumeName: "Macintosh HD", path: "/",
                        totalBytes: 494_384_795_648, availableBytes: 123_000_000_000)
    }

    func placeholder(in context: Context) -> DiskEntry {
        DiskEntry(date: .now, disk: fallback, allDisks: [fallback])
    }

    func snapshot(for config: SelectVolumeIntent, in context: Context) async -> DiskEntry {
        DiskEntry(date: .now, disk: resolve(config), allDisks: volumes())
    }

    func timeline(for config: SelectVolumeIntent, in context: Context) async -> Timeline<DiskEntry> {
        let entry = DiskEntry(date: .now, disk: resolve(config), allDisks: volumes())
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        return Timeline(entries: [entry], policy: .after(next))
    }

    /// Non-empty so systemLarge never renders a blank card.
    private func volumes() -> [DiskInfo] {
        let all = DiskReader.allVolumes()
        return all.isEmpty ? [fallback] : all
    }

    private func resolve(_ config: SelectVolumeIntent) -> DiskInfo {
        let picked = config.volumeName
        duLog.debug("resolve: config.volumeName=\(picked ?? "<nil>", privacy: .public)")
        guard let name = picked else {
            duLog.error("resolve: no volume in config -> falling back to boot")
            return fallback
        }
        guard let info = DiskReader.info(named: name) else {
            duLog.error("resolve: no mounted volume named \(name, privacy: .public) -> falling back to boot")
            return fallback
        }
        duLog.debug("resolve: OK \(info.volumeName, privacy: .public) total=\(info.totalBytes) avail=\(info.availableBytes)")
        return info
    }
}
