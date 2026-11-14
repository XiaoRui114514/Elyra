// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Elyra contributors
import Foundation
import CoreFoundation

public enum ElyraError: Error, LocalizedError, Equatable {
    case invalid(String), conflict, integrity, outsideWorkspace, systemUnavailable
    public var errorDescription: String? {
        switch self {
        case .invalid(let message): return message
        case .conflict: return "The document changed in another window. Reload before saving. Your draft is preserved."
        case .integrity: return "Backup integrity verification failed. No restore was started."
        case .outsideWorkspace: return "This file is outside Elyra’s managed workspace."
        case .systemUnavailable: return "System modification is unavailable: no authorized, verified system writer is installed."
        }
    }
}

public indirect enum PlistValue: Codable, Sendable, Equatable {
    case string(String), integer(Int64), real(Double), boolean(Bool), data(Data), date(Date)
    case array([PlistValue]), dictionary([String: PlistValue])

    public var kind: String {
        switch self {
        case .string: "String"
        case .integer: "Integer"
        case .real: "Real"
        case .boolean: "Boolean"
        case .data: "Data"
        case .date: "Date"
        case .array: "Array"
        case .dictionary: "Dictionary"
        }
    }
    public var summary: String {
        switch self {
        case .string(let v): v
        case .integer(let v): String(v)
        case .real(let v): String(v)
        case .boolean(let v): v ? "true" : "false"
        case .data(let v): "\(v.count) bytes"
        case .date(let v): ISO8601DateFormatter().string(from: v)
        case .array(let v): "\(v.count) items"
        case .dictionary(let v): "\(v.count) keys"
        }
    }
    public init(foundation value: Any, depth: Int = 0) throws {
        guard depth < 64 else { throw ElyraError.invalid("Plist nesting exceeds 64 levels.") }
        switch value {
        case let v as String: self = .string(v)
        case let v as Data: self = .data(v)
        case let v as Date:
            guard v.timeIntervalSinceReferenceDate.isFinite else { throw ElyraError.invalid("Non-finite date.") }
            self = .date(v)
        case let v as NSNumber:
            if CFGetTypeID(v) == CFBooleanGetTypeID() { self = .boolean(v.boolValue) }
            else if String(cString: v.objCType).contains("f") || String(cString: v.objCType).contains("d") {
                guard v.doubleValue.isFinite else { throw ElyraError.invalid("Non-finite real number.") }
                self = .real(v.doubleValue)
            } else {
                guard let integer = Int64(v.stringValue) else { throw ElyraError.invalid("Integer is outside the signed 64-bit range.") }
                self = .integer(integer)
            }
        case let v as [String: Any]:
            self = .dictionary(try v.mapValues { try Self(foundation: $0, depth: depth + 1) })
        case let v as [Any]: self = .array(try v.map { try Self(foundation: $0, depth: depth + 1) })
        default: throw ElyraError.invalid("Unsupported plist value.")
        }
    }
    public var foundation: Any {
        switch self {
        case .string(let v): v
        case .integer(let v): NSNumber(value: v)
        case .real(let v): NSNumber(value: v)
        case .boolean(let v): NSNumber(value: v)
        case .data(let v): v
        case .date(let v): v
        case .array(let v): v.map(\.foundation)
        case .dictionary(let v): v.mapValues(\.foundation)
        }
    }
    public func validate(depth: Int = 0) throws {
        guard depth < 64 else { throw ElyraError.invalid("Plist nesting exceeds 64 levels.") }
        switch self {
        case .real(let v): guard v.isFinite else { throw ElyraError.invalid("Non-finite real number.") }; break
        case .date(let v): guard v.timeIntervalSinceReferenceDate.isFinite else { throw ElyraError.invalid("Non-finite date.") }; break
        case .array(let values): for v in values { try v.validate(depth: depth + 1) }
        case .dictionary(let values): for v in values.values { try v.validate(depth: depth + 1) }
        default: break
        }
    }
    public func encoded(format: PropertyListSerialization.PropertyListFormat = .binary) throws -> Data {
        try validate()
        return try PropertyListSerialization.data(fromPropertyList: foundation, format: format, options: 0)
    }
    public static let maximumBytes = 16 * 1024 * 1024
    public static func decode(_ data: Data) throws -> Self {
        guard !data.isEmpty, data.count <= maximumBytes else { throw ElyraError.invalid("Choose a plist smaller than 16 MB.") }
        return try Self(foundation: PropertyListSerialization.propertyList(from: data, options: [], format: nil))
    }
    /// A complete XML plist, including nested Array/Dictionary and exact data types.
    public var xml: String { (try? String(data: encoded(format: .xml), encoding: .utf8)) ?? "" }
    public static func parseXML(_ text: String) throws -> Self { try decode(Data(text.utf8)) }

    public func value(at path: [String]) -> Self? {
        guard let first = path.first else { return self }
        switch self {
        case .dictionary(let values): return values[first]?.value(at: Array(path.dropFirst()))
        case .array(let values):
            guard let index = Int(first), values.indices.contains(index) else { return nil }
            return values[index].value(at: Array(path.dropFirst()))
        default: return nil
        }
    }
    public mutating func set(_ value: Self?, at path: [String]) throws {
        guard let first = path.first else {
            guard let value else { throw ElyraError.invalid("Cannot remove the plist root.") }
            self = value; return
        }
        switch self {
        case .dictionary(var values):
            if path.count == 1 { values[first] = value }
            else {
                guard var child = values[first] else { throw ElyraError.invalid("Parent key does not exist.") }
                try child.set(value, at: Array(path.dropFirst())); values[first] = child
            }
            self = .dictionary(values)
        case .array(var values):
            guard let index = Int(first), values.indices.contains(index) else { throw ElyraError.invalid("Array index is out of range.") }
            if path.count == 1, value == nil { values.remove(at: index) }
            else { try values[index].set(value, at: Array(path.dropFirst())) }
            self = .array(values)
        default: throw ElyraError.invalid("This value is not a container.")
        }
    }
    public var children: [(String, Self)] {
        switch self {
        case .dictionary(let v): v.keys.sorted().map { ($0, v[$0]!) }
        case .array(let v): v.enumerated().map { (String($0.offset), $0.element) }
        default: []
        }
    }
}

public struct PlistChange: Identifiable, Sendable, Equatable {
    public let path: [String]
    public let before: PlistValue?
    public let after: PlistValue?
    // Length-prefixed components avoid collisions from '/' or '.' inside dictionary keys.
    public var id: String { path.map { "\($0.utf8.count):\($0)" }.joined() }
    public var displayPath: String { path.map { $0.replacingOccurrences(of: "~", with: "~0").replacingOccurrences(of: "/", with: "~1") }.joined(separator: "/") }
    public static func between(_ before: PlistValue, _ after: PlistValue, path: [String] = []) -> [Self] {
        guard before != after else { return [] }
        if case .dictionary(let a) = before, case .dictionary(let b) = after {
            return Set(a.keys).union(b.keys).sorted().flatMap { key -> [Self] in
                if let left = a[key], let right = b[key] { return between(left, right, path: path + [key]) }
                return [Self(path: path + [key], before: a[key], after: b[key])]
            }
        }
        return [Self(path: path, before: before, after: after)]
    }
}
