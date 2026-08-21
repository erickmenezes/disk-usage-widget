import SwiftUI
import WidgetKit

@main
struct DiskUsageApp: App {
    @StateObject private var monitor = LowSpaceMonitor()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(monitor)
                .onAppear { monitor.start() }
        }
        .defaultSize(width: 460, height: 520)
    }
}

struct ContentView: View {
    @EnvironmentObject private var monitor: LowSpaceMonitor
    @State private var volumes: [DiskInfo] = []
    @State private var alertsEnabled = AppGroup.alertsEnabled
    @State private var threshold = AppGroup.thresholdPercent

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Disk Usage").font(.largeTitle.bold())
            Text("Add the widget from the desktop: right-click → Edit Widgets → Disk Usage.")
                .font(.callout).foregroundStyle(.secondary)

            Divider()

            ForEach(volumes, id: \.id) { v in
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

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Toggle("Alert me when the boot volume is low on space", isOn: $alertsEnabled)
                    .onChange(of: alertsEnabled) { _, new in
                        AppGroup.alertsEnabled = new
                        monitor.check()
                    }

                HStack {
                    Text("Threshold")
                    Stepper("\(threshold)% free or less", value: $threshold, in: 1...50)
                        .onChange(of: threshold) { _, new in
                            AppGroup.thresholdPercent = new
                            monitor.check()
                        }
                }
                .disabled(!alertsEnabled)

                HStack(spacing: 10) {
                    if let pct = monitor.currentFreePercent {
                        Text("Boot volume: \(pct)% free")
                            .font(.caption).foregroundStyle(.secondary).monospacedDigit()
                    }
                    if !monitor.authorized {
                        Label("Notifications not permitted", systemImage: "exclamationmark.triangle")
                            .font(.caption).foregroundStyle(.orange)
                    }
                }

                if !AppGroup.isShared {
                    Label("App Group unavailable — settings are local only",
                          systemImage: "exclamationmark.triangle")
                        .font(.caption).foregroundStyle(.orange)
                }
            }

            Spacer()

            HStack {
                Button("Reload Widget Timelines") {
                    WidgetCenter.shared.reloadAllTimelines()
                }
                Button("Send Test Alert") { monitor.sendTestNotification() }
                    .disabled(!monitor.authorized)
            }
        }
        .padding(20)
        .task { volumes = DiskReader.allVolumes() }
    }
}
