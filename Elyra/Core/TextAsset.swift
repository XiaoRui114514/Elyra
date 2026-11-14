// SPDX-License-Identifier: GPL-3.0-only
import Foundation

public struct TextAssetSnapshot: Sendable {
    public let asset: AssetRecord
    public let data: Data
    public let text: String
    public static let maximumBytes = 1024 * 1024
    public init(asset: AssetRecord, data: Data) throws {
        guard data.count <= Self.maximumBytes, !data.contains(0), let text = String(data: data, encoding: .utf8) else {
            throw ElyraError.invalid("The text editor supports UTF-8 files up to 1 MB. Binary files are not editable here.")
        }
        self.asset = asset; self.data = data; self.text = text
    }
    public func encoded(_ edited: String) throws -> Data {
        if text == edited { return data }
        let prefix = data.starts(with: [0xef, 0xbb, 0xbf]) ? Data([0xef, 0xbb, 0xbf]) : Data()
        var output = Data(edited.utf8)
        if !prefix.isEmpty, !output.starts(with: prefix) { output = prefix + output }
        guard output.count <= Self.maximumBytes, !output.contains(0) else {
            throw ElyraError.invalid("The text editor supports UTF-8 files up to 1 MB. Binary files are not editable here.")
        }
        return output
    }
}
public struct AssetBackupRecord: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public let assetID: UUID
    public let name: String
    public let date: Date
    public let reason: String
    public let digest: String
    public let byteCount: Int
    public var filename: String { id.uuidString + ".asset" }
}
struct AssetCommitJournal: Codable {
    let asset: AssetRecord
    let desired: String
    let previousState: WorkspaceState
    let state: WorkspaceState
}
