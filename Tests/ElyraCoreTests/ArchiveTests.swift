// SPDX-License-Identifier: GPL-3.0-only
import XCTest
import ZIPFoundation
@testable import ElyraCore

final class ArchiveTests: XCTestCase {
    func zip(_ files: [(String, Data, Entry.EntryType)], compressed: Bool = false) throws -> Data {
        let archive = try Archive(data: Data(), accessMode: .create)
        for (path, bytes, type) in files {
            try archive.addEntry(with: path, type: type, uncompressedSize: Int64(bytes.count), compressionMethod: compressed ? .deflate : .none) { offset, count in
                bytes.subdata(in: Int(offset)..<(Int(offset)+count))
            }
        }
        return try XCTUnwrap(archive.data)
    }
    func testValidZipAndTendiesDescriptorBytesAreInspected() throws {
        let payload = Data("actual descriptor".utf8)
        let archive = try zip([("Pack/Wallpaper.plist", payload, .file), ("Readme.txt", Data("中文".utf8), .file)], compressed: true)
        let result = try ArchiveInspection.inspect(archive)
        XCTAssertEqual(result.items.count, 2)
        XCTAssertTrue(result.hasWallpaperDescriptors)
        XCTAssertEqual(result.expandedByteCount, UInt64(payload.count + Data("中文".utf8).count))
        XCTAssertEqual(try ArchiveInspection.readEntry("Pack/Wallpaper.plist", from: archive), payload)
    }
    func testUnsafeAndAbsolutePathsAreRejected() throws {
        for path in ["../outside", "/absolute", "A/../../B", "A\\B", "C:/B", "A//B", "A/./B"] {
            let data = try zip([(path, Data([65]), .file)])
            XCTAssertThrowsError(try ArchiveInspection.inspect(data), path)
        }
    }
    func testLinksAndCaseInsensitiveDuplicateNamesAreRejected() throws {
        let link = try zip([("link", Data("../../outside".utf8), .symlink)])
        XCTAssertThrowsError(try ArchiveInspection.inspect(link))
        let duplicate = try zip([("A.txt", Data([65]), .file), ("a.TXT", Data([66]), .file)])
        XCTAssertThrowsError(try ArchiveInspection.inspect(duplicate))
    }
    func testConflictingParentFileAndDirectoryNamesAreRejectedInEitherOrder() throws {
        for files: [(String, Data, Entry.EntryType)] in [
            [("A", Data([65]), .file), ("A/child", Data([66]), .file)],
            [("A/child", Data([66]), .file), ("A", Data([65]), .file)]
        ] { XCTAssertThrowsError(try ArchiveInspection.inspect(zip(files))) }
    }
    func testTruncatedEmptyAndUnsupportedArchivesRejected() throws {
        XCTAssertThrowsError(try ArchiveInspection.inspect(Data()))
        let data = try zip([("A.txt", Data([65]), .file)])
        XCTAssertThrowsError(try ArchiveInspection.inspect(Data(data.dropLast(5))))
        XCTAssertThrowsError(try ArchiveInspection.inspect(Data("not a zip".utf8)))
    }
    func testCRCFailureRejected() throws {
        var data = try zip([("A.txt", Data("actual contents".utf8), .file)])
        // Stored entry: fixed local header + filename, then the real content bytes.
        data[30 + "A.txt".utf8.count] ^= 1
        XCTAssertThrowsError(try ArchiveInspection.inspect(data))
    }
    func testEncryptedFlagAndCentralDirectoryCountMismatchRejected() throws {
        let data = try zip([("A.txt", Data([65]), .file)])
        var encrypted = data
        encrypted[6] |= 1
        let central = try XCTUnwrap(data.range(of: Data([0x50,0x4b,0x01,0x02]))?.lowerBound)
        encrypted[central+8] |= 1
        XCTAssertThrowsError(try ArchiveInspection.inspect(encrypted))
        var count = data
        let end = count.count-22
        count[end+8] = 2; count[end+10] = 2
        XCTAssertThrowsError(try ArchiveInspection.inspect(count))
    }
    func testDeclaredExpansionAndPreviewLimitsEnforced() throws {
        let data = try zip([("A.txt", Data("12345678".utf8), .file)])
        XCTAssertThrowsError(try ArchiveInspection.readEntry("A.txt", from: data, maximumBytes: 4))
        XCTAssertThrowsError(try ArchiveInspection.readEntry("missing", from: data))
        var huge = data
        let central = try XCTUnwrap(data.range(of: Data([0x50,0x4b,0x01,0x02]))?.lowerBound)
        let size = UInt32(ArchiveInspection.maximumEntry+1)
        for position in [22, central+24] {
            for byte in 0..<4 { huge[position+byte] = UInt8(truncatingIfNeeded: size >> (byte*8)) }
        }
        XCTAssertThrowsError(try ArchiveInspection.inspect(huge))
    }
    func testDataSliceWithNonzeroIndexIsHandledSafely() throws {
        let valid = try zip([("A.txt", Data([65]), .file)])
        let padded = Data([0]) + valid
        let slice = padded.dropFirst()
        XCTAssertEqual(try ArchiveInspection.inspect(slice).items.count, 1)
        XCTAssertEqual(try ArchiveInspection.readEntry("A.txt", from: slice), Data([65]))
    }
    func testDirectoryEntriesRemainVisibleAndCannotBeReadAsFiles() throws {
        let data = try zip([("Folder/", Data(), .directory), ("Folder/empty.txt", Data(), .file)])
        let summary = try ArchiveInspection.inspect(data)
        XCTAssertTrue(summary.items.contains(where: { $0.path == "Folder" && $0.directory }))
        XCTAssertThrowsError(try ArchiveInspection.readEntry("Folder", from: data))
        XCTAssertEqual(try ArchiveInspection.readEntry("Folder/empty.txt", from: data), Data())
    }
}
