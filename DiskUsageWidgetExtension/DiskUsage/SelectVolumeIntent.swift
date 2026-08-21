import AppIntents

/// NOTE: this deliberately does NOT use AppEntity/EntityQuery.
/// AppIntents could not decode a persisted VolumeEntity here — every timeline
/// logged "Failed to build EntityIdentifier ... not a registered AppEntity
/// identifier", handed back VolumeEntity(nil), and fell through to
/// defaultResult(), so the widget was permanently pinned to the boot volume.
/// A DynamicOptionsProvider over a plain String stores the raw value in the
/// widget config and skips EntityIdentifier entirely.
struct VolumeOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> [String] {
        DiskReader.allVolumes().map(\.volumeName)
    }
}

struct SelectVolumeIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Select Volume"
    static let description = IntentDescription("Choose which disk to display.")

    @Parameter(title: "Volume", optionsProvider: VolumeOptionsProvider())
    var volumeName: String?

    init() {}
}
