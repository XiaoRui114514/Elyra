// SPDX-License-Identifier: GPL-3.0-only
import Foundation
import Security
import Darwin

private final class DeviceDescriptor: SystemConfigurationFile, @unchecked Sendable {
    private var descriptor: Int32
    private let handle: Int64
    private let lock = NSRecursiveLock()
    let identity: String
    init(descriptor: Int32, handle: Int64) throws {
        self.descriptor = descriptor; self.handle = handle
        var info = stat()
        guard fstat(descriptor, &info) == 0, (info.st_mode & S_IFMT) == S_IFREG else { throw ElyraError.invalid("The system target is not a regular file.") }
        identity = "\(info.st_dev):\(info.st_ino)"
    }
    private func checkIdentity() throws {
        var now = stat()
        guard lstat(DeviceBackend.path, &now) == 0, identity == "\(now.st_dev):\(now.st_ino)" else { throw ElyraError.invalid("The system cache was replaced. Read the device again.") }
    }
    func read() throws -> Data {
        lock.lock(); defer { lock.unlock() }
        guard descriptor >= 0 else { throw ElyraError.invalid("The system file session is closed.") }
        try checkIdentity()
        let file = FileHandle(fileDescriptor: descriptor, closeOnDealloc: false)
        try file.seek(toOffset: 0)
        let data = try file.read(upToCount: PlistValue.maximumBytes + 1) ?? Data()
        guard data.count <= PlistValue.maximumBytes else { throw ElyraError.invalid("The system cache exceeds the supported size.") }
        return data
    }
    func replace(_ data: Data) throws {
        lock.lock(); defer { lock.unlock() }
        guard descriptor >= 0 else { throw ElyraError.invalid("The system file session is closed.") }
        try checkIdentity()
        let file = FileHandle(fileDescriptor: descriptor, closeOnDealloc: false)
        try file.seek(toOffset: 0); try file.truncate(atOffset: 0)
        try file.write(contentsOf: data); try file.synchronize()
    }
    func close() {
        lock.lock(); defer { lock.unlock() }
        if descriptor >= 0 { _ = Darwin.close(descriptor); descriptor = -1; worse_query_release(handle) }
    }
    deinit { close() }
}

enum DeviceBackend {
    static let path = "/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist"
    static func binding() throws -> String {
        let service = (Bundle.main.bundleIdentifier ?? "org.elyra.Elyra") + ".system-backups"
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: "device-binding"]
        var read = query; read[kSecReturnData as String] = true; read[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let result = SecItemCopyMatching(read as CFDictionary, &item)
        if result == errSecSuccess, let data = item as? Data, data.count == 32 { return Digest.sha256(data) }
        guard result == errSecItemNotFound else { throw ElyraError.invalid("The device backup key could not be read. Check app signing and Keychain access.") }
        var bytes = [UInt8](repeating: 0, count: 32)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else { throw ElyraError.invalid("The device backup key could not be created.") }
        let data = Data(bytes); var add = query
        add[kSecValueData as String] = data; add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        guard SecItemAdd(add as CFDictionary, nil) == errSecSuccess else { throw ElyraError.invalid("The device backup key could not be saved. Check app signing and Keychain access.") }
        return Digest.sha256(data)
    }
    static func access() -> SystemAccess { SystemAccess { writable in try open(writable: writable) } }
    private static func open(writable: Bool) throws -> any SystemConfigurationFile {
        #if targetEnvironment(simulator)
        throw ElyraError.invalid("Device system access is unavailable in the Simulator.")
        #else
        let flags = (writable ? O_RDWR : O_RDONLY) | O_CLOEXEC | O_NOFOLLOW
        var fd = Darwin.open(path, flags)
        var token: Int64 = -1
        if fd < 0 {
            guard [26,27].contains(ProcessInfo.processInfo.operatingSystemVersion.majorVersion) else { throw ElyraError.invalid("The native access module has not been validated for this system version.") }
            let groups = GXEntitlementsReader.usableAppGroups()
            guard !groups.isEmpty else { throw ElyraError.invalid("System access requires a signed, usable App Group. Enable App Groups in the signing profile and re-sign Elyra.") }
            let target = (path as NSString).deletingLastPathComponent
            for group in groups {
                // Both flags are existing upstream modes. Neither grants access on a patched build.
                for alternate in [false, true] {
                    if let root = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) {
                        try FileManager.default.createDirectory(at: root.appendingPathComponent("Library/Caches"), withIntermediateDirectories: true)
                    }
                    token = worse_query(target, group, alternate, false)
                    if token >= 0 {
                        fd = Darwin.open(path, flags)
                        if fd >= 0 { break }
                        worse_query_release(token); token = -1
                    }
                }
                if fd >= 0 { break }
            }
        }
        guard fd >= 0 else { throw ElyraError.invalid(writable ? "The system denied write access. No device configuration was changed." : "The system cache could not be read. Check build compatibility and App Group signing.") }
        do {
            if writable, flock(fd, LOCK_EX | LOCK_NB) != 0 { throw ElyraError.invalid("The system configuration is busy in another process. Try again after it finishes.") }
            return try DeviceDescriptor(descriptor: fd, handle: token)
        } catch { _ = Darwin.close(fd); worse_query_release(token); throw error }
        #endif
    }
}
