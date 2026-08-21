import SwiftUI
import WidgetKit

struct DiskWidgetView: View {
    let entry: DiskEntry
    @Environment(\.widgetFamily) private var family

    private var pct: Int { Int((entry.disk.usedFraction * 100).rounded()) }
    private var tint: Color { Self.tint(for: entry.disk.usedFraction) }

    static func tint(for fraction: Double) -> Color {
        switch fraction {
        case ..<0.75: return .green
        case ..<0.90: return .yellow
        default:      return .red
        }
    }

    /// Internal boot volume vs. anything mounted under /Volumes.
    static func symbol(for disk: DiskInfo) -> String {
        disk.path == "/" ? "internaldrive" : "externaldrive"
    }

    var body: some View {
        switch family {
        case .systemSmall: small
        case .systemLarge: large
        default:           medium
        }
    }

    // MARK: - Small: single ring for the volume chosen in the picker

    private var ring: some View {
        ZStack {
            Circle().stroke(.quaternary, lineWidth: 10)
            Circle()
                .trim(from: 0, to: entry.disk.usedFraction)
                .stroke(tint, style: .init(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(pct)%").font(.title2.bold()).monospacedDigit()
                Text("used").font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    private var small: some View {
        VStack(spacing: 6) {
            ring.frame(width: 72, height: 72)
            Text(entry.disk.volumeName).font(.caption).lineLimit(1)
        }
        .padding()
    }

    // MARK: - Medium: a row of rings, one per volume (Batteries-widget style)

    private var medium: some View {
        // 4 fits comfortably at medium width without the labels colliding.
        let disks = Array(entry.allDisks.prefix(4))
        return HStack(alignment: .top, spacing: 0) {
            ForEach(disks, id: \.id) { disk in
                VolumeGauge(disk: disk)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }

    // MARK: - Large: every volume with full numbers

    private var large: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Volumes").font(.headline)
            // Cap the list so a machine with many mounts cannot overflow the
            // widget; WidgetKit clips silently rather than scrolling.
            ForEach(entry.allDisks.prefix(4), id: \.id) { disk in
                VolumeRow(disk: disk)
            }
            if entry.allDisks.count > 4 {
                Text("+\(entry.allDisks.count - 4) more")
                    .font(.caption2).foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
        }
        .padding()
    }
}

/// A ring with the drive icon inside and the percentage beneath, mirroring the
/// system Batteries widget. Used by systemMedium.
private struct VolumeGauge: View {
    let disk: DiskInfo

    private var pct: Int { Int((disk.usedFraction * 100).rounded()) }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle().stroke(.quaternary, lineWidth: 7)
                Circle()
                    .trim(from: 0, to: disk.usedFraction)
                    .stroke(DiskWidgetView.tint(for: disk.usedFraction),
                            style: .init(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: DiskWidgetView.symbol(for: disk))
                    .font(.system(size: 18))
                    .foregroundStyle(.primary)
            }
            .frame(width: 56, height: 56)

            Text("\(pct)%")
                .font(.callout.weight(.semibold)).monospacedDigit()
            Text(disk.volumeName)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

/// One volume as a small ring plus its numbers. Used by systemLarge.
private struct VolumeRow: View {
    let disk: DiskInfo

    private var pct: Int { Int((disk.usedFraction * 100).rounded()) }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().stroke(.quaternary, lineWidth: 6)
                Circle()
                    .trim(from: 0, to: disk.usedFraction)
                    .stroke(DiskWidgetView.tint(for: disk.usedFraction),
                            style: .init(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(pct)")
                    .font(.caption2.bold()).monospacedDigit()
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 1) {
                Text(disk.volumeName)
                    .font(.subheadline.weight(.medium)).lineLimit(1)
                Text("\(DiskInfo.fmt(disk.availableBytes)) free of \(DiskInfo.fmt(disk.totalBytes))")
                    .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 0)
        }
    }
}
