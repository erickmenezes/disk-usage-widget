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

    var body: some View {
        switch family {
        case .systemSmall: small
        case .systemLarge: large
        default:           medium
        }
    }

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

    private var medium: some View {
        HStack(spacing: 16) {
            ring.frame(width: 84, height: 84)
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.disk.volumeName).font(.headline).lineLimit(1)
                Label(DiskInfo.fmt(entry.disk.usedBytes) + " used", systemImage: "internaldrive")
                    .font(.caption)
                Text(DiskInfo.fmt(entry.disk.availableBytes) + " free")
                    .font(.caption).foregroundStyle(.secondary)
                Text("of " + DiskInfo.fmt(entry.disk.totalBytes))
                    .font(.caption2).foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding()
    }
    /// systemLarge: every mounted volume as its own ring row. Ignores the
    /// config picker by design - the point of the large family is the overview.
    private var large: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Volumes")
                .font(.headline)
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
