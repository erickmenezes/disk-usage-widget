import WidgetKit
import SwiftUI

struct DiskUsageWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "DiskUsageWidget",
            intent: SelectVolumeIntent.self,
            provider: DiskProvider()
        ) { entry in
            DiskWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget) // Liquid Glass friendly
        }
        .configurationDisplayName("Disk Usage")
        .description("Used and free space for a volume.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
