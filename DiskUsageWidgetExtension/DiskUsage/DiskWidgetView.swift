import SwiftUI
import WidgetKit

struct DiskWidgetView: View {
    let entry: DiskEntry
    @Environment(\.widgetFamily) private var family

    private var pct: Int { Int((entry.disk.usedFraction * 100).rounded()) }
    private var tint: Color {
        switch entry.disk.usedFraction {
        case ..<0.75: return .green
        case ..<0.90: return .yellow
        default:      return .red
        }
    }

    var body: some View {
        switch family {
        case .systemSmall: small
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
}
