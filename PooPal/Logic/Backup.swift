import CommonCrypto
import CryptoKit
import Foundation

struct BackupEntry: Codable, Equatable {
    var timestamp: Date
    var bristolType: Int?
    var note: String?
}

struct BackupFile: Codable, Equatable {
    var app = "PooPal"
    var version = 1
    var exportedAt: Date
    var entries: [BackupEntry]
}

/// Password-protected wrapper: the plain `BackupFile` JSON sealed with AES-GCM, key from PBKDF2-SHA256.
struct EncryptedBackupFile: Codable {
    var app = "PooPal"
    var format = "encrypted"
    var version = 1
    var kdf = "PBKDF2-SHA256"
    var iterations: Int
    var salt: String
    var payload: String
}

enum BackupError: LocalizedError, Equatable {
    case invalidFile
    case passwordRequired
    case wrongPassword
    case unsupportedVersion(Int)

    var errorDescription: String? {
        switch self {
        case .invalidFile: "这不是 PooPal 的备份文件，或者文件已损坏"
        case .passwordRequired: "这个备份设置了密码，请输入密码"
        case .wrongPassword: "密码不对，再试一次吧"
        case .unsupportedVersion(let v): "备份版本 \(v) 太新了，请先更新 PooPal"
        }
    }
}

enum BackupCodec {
    static let defaultIterations = 210_000

    static func encode(
        _ entries: [BackupEntry],
        exportedAt: Date = .now,
        password: String? = nil,
        iterations: Int = defaultIterations
    ) throws -> Data {
        let sorted = entries.sorted { $0.timestamp < $1.timestamp }
        let plain = try encoder.encode(BackupFile(exportedAt: exportedAt, entries: sorted))
        guard let password, !password.isEmpty else { return plain }

        let salt = randomBytes(16)
        let key = try deriveKey(password: password, salt: salt, iterations: iterations)
        let sealed = try AES.GCM.seal(plain, using: key)
        guard let combined = sealed.combined else { throw BackupError.invalidFile }
        let wrapper = EncryptedBackupFile(
            iterations: iterations,
            salt: salt.base64EncodedString(),
            payload: combined.base64EncodedString()
        )
        return try encoder.encode(wrapper)
    }

    static func isEncrypted(_ data: Data) -> Bool {
        (try? JSONDecoder().decode(EncryptedBackupFile.self, from: data))?.format == "encrypted"
    }

    static func decode(_ data: Data, password: String? = nil) throws -> BackupFile {
        var plain = data
        if isEncrypted(data) {
            guard let password, !password.isEmpty else { throw BackupError.passwordRequired }
            let wrapper = try JSONDecoder().decode(EncryptedBackupFile.self, from: data)
            guard let salt = Data(base64Encoded: wrapper.salt),
                  let combined = Data(base64Encoded: wrapper.payload),
                  wrapper.iterations > 0 else { throw BackupError.invalidFile }
            let key = try deriveKey(password: password, salt: salt, iterations: wrapper.iterations)
            do {
                plain = try AES.GCM.open(AES.GCM.SealedBox(combined: combined), using: key)
            } catch {
                throw BackupError.wrongPassword
            }
        }
        let file: BackupFile
        do {
            file = try decoder.decode(BackupFile.self, from: plain)
        } catch {
            throw BackupError.invalidFile
        }
        guard file.app == "PooPal" else { throw BackupError.invalidFile }
        guard file.version <= 1 else { throw BackupError.unsupportedVersion(file.version) }
        return file
    }

    static func fileName(for date: Date = .now, encrypted: Bool) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMdd-HHmm"
        return "PooPal-备份-\(f.string(from: date))\(encrypted ? "-加密" : "").json"
    }

    // MARK: JSON

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(fractionalISO8601().string(from: date))
        }
        return e
    }()

    /// ISO 8601 with milliseconds, so timestamps survive a round trip at the precision used for de-duplication.
    private static func fractionalISO8601() -> ISO8601DateFormatter {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let text = try container.decode(String.self)
            if let date = fractionalISO8601().date(from: text) ?? ISO8601DateFormatter().date(from: text) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "无法识别的日期：\(text)")
        }
        return d
    }()

    // MARK: Crypto

    private static func randomBytes(_ count: Int) -> Data {
        var generator = SystemRandomNumberGenerator()
        return Data((0..<count).map { _ in UInt8.random(in: .min ... .max, using: &generator) })
    }

    static func deriveKey(password: String, salt: Data, iterations: Int) throws -> SymmetricKey {
        let passwordData = Data(password.utf8)
        var derived = Data(count: 32)
        let status = derived.withUnsafeMutableBytes { derivedBytes in
            salt.withUnsafeBytes { saltBytes in
                passwordData.withUnsafeBytes { passwordBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.baseAddress?.assumingMemoryBound(to: CChar.self), passwordData.count,
                        saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self), salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256), UInt32(iterations),
                        derivedBytes.baseAddress?.assumingMemoryBound(to: UInt8.self), 32
                    )
                }
            }
        }
        guard status == kCCSuccess else { throw BackupError.invalidFile }
        return SymmetricKey(data: derived)
    }
}

/// How an import changes the existing data: entries are matched by timestamp (to the second).
/// Matches are never overwritten; they only gain a Bristol type / note they were missing.
struct MergePlan: Equatable {
    struct Fill: Equatable {
        let existingIndex: Int
        let bristolType: Int?
        let note: String?
    }

    var inserts: [BackupEntry] = []
    var fills: [Fill] = []
    var duplicates = 0

    static func make(existing: [BackupEntry], incoming: [BackupEntry]) -> MergePlan {
        var plan = MergePlan()
        var indexByKey: [Int64: Int] = [:]
        for (index, entry) in existing.enumerated() {
            indexByKey[EntryKey.of(entry.timestamp)] = indexByKey[EntryKey.of(entry.timestamp)] ?? index
        }
        var seenIncoming = Set<Int64>()

        for entry in incoming.sorted(by: { $0.timestamp < $1.timestamp }) {
            let key = EntryKey.of(entry.timestamp)
            guard seenIncoming.insert(key).inserted else {
                plan.duplicates += 1
                continue
            }
            guard let index = indexByKey[key] else {
                plan.inserts.append(entry)
                continue
            }
            let current = existing[index]
            let newType = current.bristolType == nil ? entry.bristolType.flatMap { (1...7).contains($0) ? $0 : nil } : nil
            let newNote = isBlank(current.note) && !isBlank(entry.note) ? entry.note : nil
            if newType != nil || newNote != nil {
                plan.fills.append(Fill(existingIndex: index, bristolType: newType, note: newNote))
            } else {
                plan.duplicates += 1
            }
        }
        return plan
    }

    private static func isBlank(_ text: String?) -> Bool {
        text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
    }

    var summary: String {
        var parts = ["新增 \(inserts.count) 条"]
        if !fills.isEmpty { parts.append("补充 \(fills.count) 条的形态或备注") }
        parts.append("跳过 \(duplicates) 条重复")
        return parts.joined(separator: "，")
    }
}
