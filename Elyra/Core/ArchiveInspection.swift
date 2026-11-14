// SPDX-License-Identifier: GPL-3.0-only
import Foundation
import ZIPFoundation

public struct ArchiveItem: Identifiable, Sendable, Equatable {
    public let path: String
    public let directory: Bool
    public let byteCount: UInt64
    public let crc32: UInt32
    public var id: String { path }
}
public struct ArchiveSummary: Sendable {
    public let items: [ArchiveItem]
    public let expandedByteCount: UInt64
    public let hasWallpaperDescriptors: Bool
}
/// Offline, bounded inspection. No entry is installed or extracted into a system directory.
public enum ArchiveInspection {
    public static let maximumInput = 64 * 1024 * 1024
    public static let maximumEntry: UInt64 = 32 * 1024 * 1024
    public static let maximumExpanded: UInt64 = 128 * 1024 * 1024
    public static let maximumEntries = 2000

    public static func inspect(_ data: Data) throws -> ArchiveSummary {
        guard data.count <= maximumInput else { throw ElyraError.invalid("The archive exceeds the safe entry or expansion limit.") }
        let data = data.startIndex == 0 ? data : Data(Array(data))
        let headers = try preflight(data)
        let count = headers.count
        let archive = try Archive(data: data, accessMode: .read)
        var items: [ArchiveItem] = [], paths = Set<String>(), filePaths = Set<String>(), total: UInt64 = 0
        for entry in archive {
            try Task.checkCancellation()
            let path = try validatedPath(entry.path, directory: entry.type == .directory)
            guard let header = headers.first(where: { $0.path == entry.path }),
                  header.crc32 == entry.checksum, header.bytes == entry.uncompressedSize else {
                throw ElyraError.invalid("Archive directory and entry metadata disagree.")
            }
            if entry.type == .directory, entry.uncompressedSize != 0 { throw ElyraError.invalid("The archive contains unsupported directory data.") }
            let canonical = path.precomposedStringWithCanonicalMapping.lowercased()
            guard entry.type != .symlink, paths.insert(canonical).inserted, items.count < maximumEntries else {
                throw ElyraError.invalid("The archive contains unsafe paths, duplicate names or links.")
            }
            let parts = canonical.split(separator: "/")
            if parts.count > 1 {
                for n in 1..<parts.count {
                    guard !filePaths.contains(parts.prefix(n).joined(separator: "/")) else {
                        throw ElyraError.invalid("The archive contains conflicting file and directory paths.")
                    }
                }
            }
            if entry.type == .file {
                guard !paths.contains(where: { $0.hasPrefix(canonical + "/") }) else {
                    throw ElyraError.invalid("The archive contains conflicting file and directory paths.")
                }
                filePaths.insert(canonical)
            }
            guard entry.uncompressedSize <= maximumEntry, total <= maximumExpanded - min(maximumExpanded, entry.uncompressedSize) else {
                throw ElyraError.invalid("The archive exceeds the safe entry or expansion limit.")
            }
            total += entry.uncompressedSize
            var actual: UInt64 = 0
            if entry.type == .file {
                let crc = try archive.extract(entry, bufferSize: 64 * 1024) { chunk in
                    try Task.checkCancellation()
                    actual += UInt64(chunk.count)
                    guard actual <= entry.uncompressedSize, actual <= maximumEntry else { throw ElyraError.invalid("Archive data exceeds its declared size.") }
                }
                guard actual == entry.uncompressedSize, crc == entry.checksum else { throw ElyraError.invalid("Archive CRC or size verification failed.") }
            }
            items.append(ArchiveItem(path: path, directory: entry.type == .directory, byteCount: entry.uncompressedSize, crc32: entry.checksum))
        }
        // ZIPFoundation can stop iteration on unsupported entries; never present a truncated listing as verified.
        guard items.count == count else { throw ElyraError.invalid("The archive contains unsupported or truncated entries.") }
        let descriptorNames: Set<String> = ["Wallpaper.plist", "com.apple.posterkit.provider.descriptor.identifier", "com.apple.posterkit.provider.contents.userInfo"]
        return ArchiveSummary(items: items.sorted { $0.path < $1.path }, expandedByteCount: total,
                              hasWallpaperDescriptors: items.contains { descriptorNames.contains(($0.path as NSString).lastPathComponent) })
    }
    public static func readEntry(_ path: String, from data: Data, maximumBytes: Int = 8 * 1024 * 1024) throws -> Data {
        guard data.count <= maximumInput else { throw ElyraError.invalid("The archive exceeds the safe entry or expansion limit.") }
        let data = data.startIndex == 0 ? data : Data(Array(data))
        guard maximumBytes > 0, maximumBytes <= Int(maximumEntry) else { throw ElyraError.invalid("Invalid archive preview limit.") }
        let summary = try inspect(data)
        guard let item = summary.items.first(where: { $0.path == path }), !item.directory,
              item.byteCount <= UInt64(maximumBytes) else { throw ElyraError.invalid("This archive entry is too large to preview.") }
        let archive = try Archive(data: data, accessMode: .read)
        guard let entry = archive[path] else { throw ElyraError.invalid("Archive entry not found.") }
        var result = Data()
        let crc = try archive.extract(entry, bufferSize: 64 * 1024) { chunk in
            try Task.checkCancellation()
            guard result.count <= maximumBytes - chunk.count else { throw ElyraError.invalid("This archive entry is too large to preview.") }
            result.append(chunk)
        }
        guard result.count == Int(item.byteCount), crc == item.crc32 else { throw ElyraError.invalid("Archive CRC or size verification failed.") }
        return result
    }
    public static func validatedPath(_ original: String, directory: Bool) throws -> String {
        let path = directory && original.hasSuffix("/") ? String(original.dropLast()) : original
        let parts = path.split(separator: "/", omittingEmptySubsequences: false)
        guard !path.isEmpty, path.utf8.count < 1024, !path.hasPrefix("/"), !path.contains("\\"), !path.contains("\0"),
              !path.contains(":"), parts.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }) else {
            throw ElyraError.invalid("The archive contains unsafe paths, duplicate names or links.")
        }
        return path
    }
    /// Classic ZIP central-directory preflight detects encryption, multi-disk and skipped entries.
    /// ZIP64 is deliberately unsupported under these small archive limits.
    private struct Header {
        let path: String
        let crc32: UInt32
        let bytes: UInt64
    }
    private static func preflight(_ data: Data) throws -> [Header] {
        let failure = ElyraError.invalid("Unsupported, encrypted, ZIP64 or damaged archive.")
        guard (22...maximumInput).contains(data.count) else { throw failure }
        func u16(_ p: Int) throws -> UInt16 {
            guard p >= 0, p <= data.count - 2 else { throw failure }
            return UInt16(data[p]) | UInt16(data[p+1]) << 8
        }
        func u32(_ p: Int) throws -> UInt32 {
            guard p >= 0, p <= data.count - 4 else { throw failure }
            return UInt32(data[p]) | UInt32(data[p+1]) << 8 | UInt32(data[p+2]) << 16 | UInt32(data[p+3]) << 24
        }
        var end: Int?
        for p in stride(from: data.count - 22, through: max(0, data.count - 65557), by: -1) {
            if try u32(p) == 0x06054b50, p + 22 + Int(try u16(p+20)) == data.count { end = p; break }
        }
        guard let end, try u16(end+4) == 0, try u16(end+6) == 0 else { throw failure }
        let entries = Int(try u16(end+10))
        guard entries > 0, entries <= maximumEntries, try u16(end+8) == UInt16(entries) else { throw failure }
        let size = Int(try u32(end+12)), start = Int(try u32(end+16))
        guard start >= 0, start <= end, size <= end - start else { throw failure }
        var p = start
        var headers: [Header] = []
        for _ in 0..<entries {
            guard p <= end - 46, try u32(p) == 0x02014b50 else { throw failure }
            let flags = try u16(p+8), method = try u16(p+10)
            let compressed = try u32(p+20), expanded = try u32(p+24)
            let nameLength = Int(try u16(p+28)), extraLength = Int(try u16(p+30)), commentLength = Int(try u16(p+32))
            let local = Int(try u32(p+42))
            guard flags & 0x41 == 0, method == 0 || method == 8, compressed != UInt32.max, expanded != UInt32.max,
                  try u16(p+34) == 0, local <= start - 30, nameLength > 0,
                  46 + nameLength + extraLength + commentLength <= end - p else { throw failure }
            let name = data[(p+46)..<(p+46+nameLength)]
            guard let decodedName = String(data: name, encoding: .utf8) else { throw failure }
            guard try u32(local) == 0x04034b50, try u16(local+6) == flags, try u16(local+8) == method else { throw failure }
            let localNameLength = Int(try u16(local+26)), localExtraLength = Int(try u16(local+28))
            let payload = local + 30 + localNameLength + localExtraLength
            guard localNameLength == nameLength, payload <= start, Int(compressed) <= start - payload,
                  data[(local+30)..<(local+30+localNameLength)] == name else { throw failure }
            if flags & 8 == 0 {
                guard try u32(local+14) == u32(p+16), try u32(local+18) == compressed, try u32(local+22) == expanded else { throw failure }
            }
            headers.append(Header(path: decodedName, crc32: try u32(p+16), bytes: UInt64(expanded)))
            p += 46 + nameLength + extraLength + commentLength
        }
        guard p == start + size else { throw failure }
        return headers
    }
}
