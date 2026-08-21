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
                // Must be a material, not Color.clear. Clear opts out of the
                // system vibrancy and macOS falls back to an opaque white panel;
                // a material participates in the desktop's wallpaper tinting and
                // is what makes the widget read as translucent.
                // The widget container composites over an OPAQUE backdrop when
                // the desktop is focused, so nothing here can show the wallpaper
                // through: materials resolve to a light panel and explicit alpha
                // (Color.white.opacity(0.25)) renders opaque too. Verified 2026-08-21.
                // The translucency Apple's own widgets keep while focused is not
                // available to third-party widgets. Unfocused, the system applies
                // its wallpaper tint to this widget correctly either way.
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Disk Usage")
        .description("Used and free space for a volume.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
