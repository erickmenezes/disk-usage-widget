import Foundation

struct DiskInfo: Hashable {
    /// Stable, opaque identifier — safe to persist in an AppIntents
    /// EntityIdentifier. Must never contain "/" (see DiskReader.makeID).
    let id: String
    let volumeName: String
    let path: String
    let totalBytes: Int64
    let availableBytes: Int64

    var usedBytes: Int64 { max(0, totalBytes - availableBytes) }
    var usedFraction: Double {
        totalBytes > 0 ? Double(usedBytes) / Double(totalBytes) : 0
    }

    static func fmt(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
