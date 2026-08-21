import SwiftUI
import WidgetKit

@main
struct DiskUsageApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 420, height: 320)
    }
}

struct ContentView: View {
    @State private var volumes: [DiskInfo] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Disk Usage").font(.largeTitle.bold())
            Text("Add the widget from the desktop: right-click the desktop → Edit Widgets → Disk Usage.")
                .font(.callout).foregroundStyle(.secondary)

            Divider()

            ForEach(volumes, id: \.path) { v in
                HStack {
                    Image(systemName: "internaldrive")
                    VStack(alignment: .leading, spacing: 2) {
                        Text(v.volumeName).font(.headline)
                        Text("\(DiskInfo.fmt(v.usedBytes)) used · \(DiskInfo.fmt(v.availableBytes)) free of \(DiskInfo.fmt(v.totalBytes))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(Int((v.usedFraction * 100).rounded()))%").monospacedDigit()
                }
            }

            Spacer()

            Button("Reload Widget Timelines") {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
        .padding(20)
        .task { volumes = DiskReader.allVolumes() }
    }
}
