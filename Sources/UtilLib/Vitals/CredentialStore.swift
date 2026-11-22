//
//  CredentialStore.swift
//  UtilLib
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

// MARK: - CredentialKey

/// Named secrets the vitals feature resolves.
public enum CredentialKey: String, CaseIterable, Codable, Sendable {
    /// Cloudflare API token (Zone Settings Write + Zone Analytics Read).
    case cloudflareAPIToken = "cloudflare-api-token"
    /// Google API key (PageSpeed Insights + Chrome UX Report enabled).
    case googleAPIKey = "google-api-key"
    /// Cloudflare zone ID for the site zone — not secret, stored for convenience.
    case cloudflareZoneID = "cloudflare-zone-id"

    /// Environment variable consulted before the persistent stores.
    public var environmentVariable: String {
        switch self {
        case .cloudflareAPIToken: return "CLOUDFLARE_API_TOKEN"
        case .cloudflareZoneID: return "CLOUDFLARE_ZONE_ID"
        case .googleAPIKey: return "GOOGLE_API_KEY"
        }
    }
}

// MARK: - CredentialError

/// Errors from credential resolution or storage.
public enum CredentialError: Error, Equatable, Sendable, LocalizedError {
    /// No store or environment provided the key; `checkedFile` is the
    /// file-store path actually consulted (which may differ from the
    /// default when the caller overrode it).
    case notFound(CredentialKey, checkedFile: URL)
    /// A credentials file or its containing directory is more permissive
    /// than owner-only; the mode named in `requiredMode` repairs it.
    case insecurePermissions(path: String, requiredMode: Int)
    /// A credentials path is owned by a different user — `chmod` cannot
    /// repair that; the remedy is `chown` or removing the path.
    case foreignOwnership(path: String)
    /// An explicit `--…-file` input contained no secret.
    case emptySecretFile(path: String)
    /// Keychain access is unavailable on this platform.
    case keychainUnavailable
    /// A store operation failed (backend message attached).
    case storeFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notFound(let key, let checkedFile):
            return "No credential for '\(key.rawValue)'. Provision via `util vitals credentials store`, "
                + "set $\(key.environmentVariable), or write \(checkedFile.path)."
        case .insecurePermissions(let path, let requiredMode):
            let mode = String(requiredMode, radix: 8)
            return "Credentials at \(path) must be mode 0\(mode) — run: chmod \(mode) \"\(path)\""
        case .foreignOwnership(let path):
            return "Credentials path \(path) is owned by a different user — remove it or run: sudo chown \"$USER\" \"\(path)\""
        case .emptySecretFile(let path):
            return "Credential file at \(path) is empty."
        case .keychainUnavailable:
            return "macOS Keychain is unavailable on this platform — provide the secret via a --…-file flag or an environment variable."
        case .storeFailed(let detail):
            return "Credential store operation failed: \(detail)"
        }
    }
}

// MARK: - CredentialStore

/// Resolves and stores named secrets across four layers, in order:
/// explicit file → environment → macOS Keychain → file store.
///
/// The encrypted store outranks the plaintext one (SE-0378's model — OS
/// store by default, file for automation where the OS store can't answer;
/// research.md D4). A Keychain layer that can't *answer* — locked keychain
/// on a headless run, no `security` binary — degrades to the file layer
/// rather than failing, so unattended runs still reach their provisioned
/// file. The file store (`~/.config/util/credentials.json`, mode 0600,
/// containing directory 0700) is refused on insecure permissions.
///
/// Secrets are never accepted as arguments or printed by callers.
public enum CredentialStore {

    /// Keychain service identifier (`-s` on `security` commands).
    public static let keychainService = "dev.21.websites.util"

    /// The platform's real Keychain backend — `security(1)` on macOS,
    /// `nil` elsewhere. Injected everywhere it is used so tests substitute
    /// a fake (SC-004).
    public static var platformKeychainBackend: (any KeychainBackend)? {
        #if os(macOS)
        return SecurityCLIKeychainBackend()
        #else
        return nil
        #endif
    }

    /// Default credentials file: `$XDG_CONFIG_HOME/util/credentials.json`.
    public static func defaultFileURL(environment: [String: String] = ProcessInfo.processInfo.environment) -> URL {
        // The XDG spec requires absolute paths — empty or relative values
        // are unset: fall back to ~/.config rather than resolving a
        // cwd-relative store.
        let config = environment["XDG_CONFIG_HOME"]
            .flatMap { $0.hasPrefix("/") ? $0 : nil }
            .map { URL(fileURLWithPath: $0, isDirectory: true) }
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".config", isDirectory: true)
        return config.appendingPathComponent("util/credentials.json")
    }

    // MARK: Resolution

    /// Resolves a secret through the layered chain.
    /// - Parameters:
    ///   - key: Which credential.
    ///   - explicitFile: `--…-file` flag path — raw file contents win first.
    ///   - fileURL: Override for the file store (tests). Must be absolute —
    ///     `URL(fileURLWithPath:)` resolves relative paths against the
    ///     process working directory.
    ///   - environment: Override for `ProcessInfo` (tests).
    ///   - keychain: Override for the Keychain backend (tests); `nil` skips
    ///     the layer entirely.
    /// - Returns: The secret value, never logged.
    public static func resolve(
        _ key: CredentialKey,
        explicitFile: String? = nil,
        fileURL: URL? = nil,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        keychain: (any KeychainBackend)? = CredentialStore.platformKeychainBackend
    ) async throws -> String {
        if let explicitFile {
            return try readSecretFile(at: URL(fileURLWithPath: explicitFile))
        }
        if let value = environment[key.environmentVariable], !value.isEmpty {
            return value
        }
        // Encrypted store first; a backend that can't answer degrades like
        // an empty one so headless runs still reach the file layer —
        // cancellation propagates rather than silently re-routing.
        if let keychain {
            do {
                if let value = try await keychain.read(key), !value.isEmpty {
                    return value
                }
            } catch is CancellationError {
                throw CancellationError()
            } catch {}
        }
        // `readStore` canonicalizes internally — pass the path as given
        // so its dangling-link screen sees the link components (a
        // pre-resolved path would substitute them textually). On absent,
        // `checkedFile` still names the canonical path consulted.
        let storeURL = fileURL ?? defaultFileURL(environment: environment)
        if let stored = try readStore(at: storeURL)[key.rawValue],
           !stored.isEmpty {
            return stored
        }
        throw CredentialError.notFound(key, checkedFile: storeURL.resolvingSymlinksInPath())
    }

    /// Reads a UTF-8 secret file, trimmed of surrounding whitespace.
    /// Shared by `--…-file` resolution flags and `credentials store
    /// --from-file` — public because callers live in the `util` target.
    public static func readSecretFile(at url: URL) throws -> String {
        let raw: String
        do {
            raw = try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw CredentialError.storeFailed("\(url.path) could not be read: \(error.localizedDescription)")
        }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else {
            throw CredentialError.emptySecretFile(path: url.path)
        }
        return value
    }

    // MARK: File store

    /// Reads the file store as a raw key→value map. Returns empty when
    /// absent; throws `.insecurePermissions` when the file or its
    /// containing directory is accessible beyond the owner or lacks the
    /// owner bits the mode contract requires, `.storeFailed` on a
    /// dangling symlink. Symlinks are resolved first — the checks apply
    /// to the target (ssh's StrictModes and gpg both expand links before
    /// enforcing; `attributesOfItem` is lstat-like, so checking the link
    /// itself would refuse 0755 forever while the `chmod` remedy follows
    /// the link and can never clear it).
    public static func readStore(at url: URL) throws -> [String: String] {
        let url = try resolvedStoreURL(url)
        guard FileManager.default.fileExists(atPath: url.path) else {
            // An existing ancestor that can't be traversed makes the
            // probe lie "absent" — a miss is only honest when every
            // existing ancestor can be walked. Absent dirs are the
            // normal no-store case.
            try enforceReachableStoreDir(url.deletingLastPathComponent())
            return [:]
        }
        try enforceOwnerOnly(url.deletingLastPathComponent(), requiredMode: 0o700)
        // A directory masquerading as the store file is can't-answer —
        // chmod can't repair it. `isDirectory` follows links.
        var isDirectory: ObjCBool = false
        _ = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
        if isDirectory.boolValue {
            throw CredentialError.storeFailed("\(url.path) is a directory, not a store file")
        }
        try enforceOwnerOnly(url, requiredMode: 0o600)
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw CredentialError.storeFailed("\(url.path) could not be read: \(error.localizedDescription)")
        }
        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw CredentialError.storeFailed("\(url.path) is not valid JSON")
        }
        guard let dict = object as? [String: String] else {
            throw CredentialError.storeFailed("\(url.path) is not a JSON object of string values")
        }
        return dict
    }

    /// Writes one key into the file store — file mode 0600, containing
    /// directory mode 0700.
    ///
    /// A directory the store creates or finds loose is tightened to 0700
    /// (gpg's tighten-what-we-own posture — `util/` is ours alone, never
    /// `~/.config`) — healed *before* the existing store is read, so a
    /// compliant file inside a loose directory is repaired, not refused.
    /// A pre-existing store file that is itself loose or malformed is
    /// *refused*, not silently clobbered — `readStore` throws and the
    /// maintainer repairs or removes it explicitly.
    ///
    /// `url` must be absolute. Symlinks resolve first, so the heal,
    /// checks, and atomic write all act on the canonical path — writing
    /// through the link would replace the link itself.
    public static func storeInFile(_ value: String, for key: CredentialKey, at url: URL) throws {
        let url = try resolvedStoreURL(url)
        let dir = url.deletingLastPathComponent()
        do {
            // Created 0700 at birth — a default-mode window between
            // mkdir and chmod is a plant-symlink race.
            try FileManager.default.createDirectory(
                at: dir, withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )
        } catch {
            throw CredentialError.storeFailed("\(dir.path) is not a usable directory: \(error.localizedDescription)")
        }
        // A foreign-owned dir can't be healed — chmod would fail EPERM.
        // Refuse with the typed error the read path produces for the same
        // state rather than leaking Cocoa's raw error.
        try enforceOwner(dir)
        try setMode(0o700, at: dir)
        // An untraversable ancestor makes every later probe lie — refuse
        // before the write, not after. `dir` gets the full contract;
        // ancestors only need traversal.
        try enforceReachableStoreDir(dir)
        var dict: [String: String] = [:]
        if FileManager.default.fileExists(atPath: url.path) {
            dict = try readStore(at: url)
        }
        dict[key.rawValue] = value
        let data = try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])
        try writeAtomically(data, to: url)
        // Atomic rewrites create the temp file with default permissions —
        // re-assert 0600 rather than assume it survived.
        try setMode(0o600, at: url)
    }

    /// Removes one key from the file store; absent store is a no-op.
    /// Symlinks resolve first (same canonical-path rule as `readStore`).
    public static func deleteFromFile(_ key: CredentialKey, at url: URL) throws {
        let url = try resolvedStoreURL(url)
        guard FileManager.default.fileExists(atPath: url.path) else {
            // The same honesty rule as readStore — an untraversable
            // ancestor makes fileExists lie "absent", and delete must not
            // claim success on a store it never saw.
            try enforceReachableStoreDir(url.deletingLastPathComponent())
            return
        }
        var dict = try readStore(at: url)
        dict.removeValue(forKey: key.rawValue)
        let data = try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])
        try writeAtomically(data, to: url)
        try setMode(0o600, at: url)
    }

    /// Canonical path for every store operation. A link component whose
    /// target is missing can't be reported as absent: `delete` would
    /// claim success while the secret survives on the unmounted target,
    /// and `store`'s atomic write would silently replace the link
    /// itself. `resolvingSymlinksInPath` can't be trusted to surface
    /// that — it substitutes a mid-path link textually even when the
    /// target is gone — so every link component of the path *given*
    /// must point at something that exists.
    private static func resolvedStoreURL(_ url: URL) throws -> URL {
        var component = url
        // Bound by path length, not "stop at /" — a non-absolute URL
        // (contract violation, but don't hang on it) shrinks to "" and
        // would never equal "/".
        while component.path.count > 1 {
            if let dest = try? FileManager.default.destinationOfSymbolicLink(atPath: component.path) {
                let target = URL(fileURLWithPath: dest, relativeTo: component.deletingLastPathComponent())
                guard FileManager.default.fileExists(atPath: target.path) else {
                    throw CredentialError.storeFailed(
                        "\(component.path) is a dangling symlink — its target is missing"
                    )
                }
            }
            component.deleteLastPathComponent()
        }
        return url.resolvingSymlinksInPath()
    }

    /// An existing directory whose owner can't traverse it — foreign
    /// ownership throws `.foreignOwnership`, a missing owner-execute bit
    /// throws `.insecurePermissions`. Used when the store file probes
    /// absent: the miss is only trustworthy if the dir can be walked.
    /// `fileExists` lies "absent" for anything beneath a directory the
    /// process can't search, so a miss is only honest when every
    /// existing ancestor can be walked. The store's own directory gets
    /// the full owner + owner-execute contract; ancestors only need
    /// traversal — `access(X_OK)` follows links and answers for *this*
    /// process on foreign-owned dirs, where owner-bit arithmetic can't.
    private static func enforceReachableStoreDir(_ dir: URL) throws {
        var component = dir
        if FileManager.default.fileExists(atPath: component.path) {
            try enforceTraversable(component)
        }
        while component.path.count > 1 {
            component.deleteLastPathComponent()
            if FileManager.default.fileExists(atPath: component.path) {
                try enforceSearchable(component)
            }
        }
    }

    /// `access(dir, X_OK)` — the process's own search permission on an
    /// ancestor, which owner-bit arithmetic can't answer for
    /// foreign-owned dirs (we traverse root-owned dirs on the other-exec
    /// bit, not theirs).
    private static func enforceSearchable(_ dir: URL) throws {
        guard access(dir.path, X_OK) == 0 else {
            throw CredentialError.insecurePermissions(path: dir.path, requiredMode: 0o700)
        }
    }

    private static func enforceTraversable(_ dir: URL) throws {
        try enforceOwner(dir)
        // `attributesOfItem` is lstat-like — a symlinked directory reads
        // as `.typeSymbolicLink`. `isDirectory` follows links and answers
        // the real question: can this path be walked as a directory.
        var isDirectory: ObjCBool = false
        _ = FileManager.default.fileExists(atPath: dir.path, isDirectory: &isDirectory)
        if !isDirectory.boolValue {
            throw CredentialError.storeFailed("\(dir.path) exists but is not a directory")
        }
        let attrs = try attributes(of: dir)
        if let perms = attrs[.posixPermissions] as? NSNumber, perms.intValue & 0o100 == 0 {
            throw CredentialError.insecurePermissions(path: dir.path, requiredMode: 0o700)
        }
    }

    /// Throws `.insecurePermissions` when `url`'s mode isn't exactly
    /// `requiredMode` — the spec's contract is literal (file `0600`,
    /// dir `0700`): a `0600` directory makes every lookup fail closed
    /// as "absent", a `000` file surfaces a raw read error, and `0700`
    /// on a *file* is still not `0600`. `chmod` repairs. Throws
    /// `.foreignOwnership` when owned by a different user — the same
    /// checks as ssh's StrictModes. POSIX ACLs are not inspected; mode
    /// bits plus ownership are the enforcement contract.
    private static func enforceOwnerOnly(_ url: URL, requiredMode: Int) throws {
        try enforceOwner(url)
        let attrs = try attributes(of: url)
        if let perms = attrs[.posixPermissions] as? NSNumber,
           perms.intValue & 0o777 != requiredMode {
            throw CredentialError.insecurePermissions(path: url.path, requiredMode: requiredMode)
        }
    }

    /// Throws `.foreignOwnership` when `url` is owned by a different
    /// user — `chmod` can't repair ownership, so it gets its own remedy.
    /// Used alone where the mode is about to be healed anyway
    /// (`storeInFile`'s directory tighten), so only ownership can refuse.
    private static func enforceOwner(_ url: URL) throws {
        let attrs = try attributes(of: url)
        if let owner = attrs[.ownerAccountID] as? NSNumber, owner.intValue != getuid() {
            throw CredentialError.foreignOwnership(path: url.path)
        }
    }

    /// Filesystem calls surface raw Cocoa errors — wrap each so every
    /// failure leaves as the `CredentialError` callers switch on.
    private static func attributes(of url: URL) throws -> [FileAttributeKey: Any] {
        do {
            return try FileManager.default.attributesOfItem(atPath: url.path)
        } catch {
            throw CredentialError.storeFailed("\(url.path) could not be inspected: \(error.localizedDescription)")
        }
    }

    private static func setMode(_ mode: Int, at url: URL) throws {
        do {
            try FileManager.default.setAttributes([.posixPermissions: mode], ofItemAtPath: url.path)
        } catch {
            throw CredentialError.storeFailed("could not set mode on \(url.path): \(error.localizedDescription)")
        }
    }

    private static func writeAtomically(_ data: Data, to url: URL) throws {
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw CredentialError.storeFailed("could not write \(url.path): \(error.localizedDescription)")
        }
    }

    // MARK: Persistent stores

    /// Which persistent store `credentials` subcommands act on.
    public enum StoreTarget: String, Sendable {
        /// macOS Keychain via the `security(1)` backend.
        case keychain
        /// `~/.config/util/credentials.json`, mode 0600.
        case file
    }

    /// Stores a secret in the requested store. Empty values are rejected —
    /// every resolver treats them as absent, so storing one would produce a
    /// store `exists` reports present while `resolve` finds nothing.
    /// - Parameter fileURL: Override for the file store; must be absolute.
    public static func store(
        _ value: String,
        for key: CredentialKey,
        target: StoreTarget,
        fileURL: URL? = nil,
        keychain: (any KeychainBackend)? = platformKeychainBackend
    ) async throws {
        guard !value.isEmpty else {
            throw CredentialError.storeFailed("credential value must not be empty")
        }
        switch target {
        case .file:
            try storeInFile(value, for: key, at: fileURL ?? defaultFileURL())
        case .keychain:
            guard let keychain else { throw CredentialError.keychainUnavailable }
            try await keychain.store(value, for: key)
        }
    }

    /// Deletes a secret from the requested store.
    /// - Parameter fileURL: Override for the file store; must be absolute.
    public static func delete(
        _ key: CredentialKey,
        target: StoreTarget,
        fileURL: URL? = nil,
        keychain: (any KeychainBackend)? = CredentialStore.platformKeychainBackend
    ) async throws {
        switch target {
        case .file:
            try deleteFromFile(key, at: fileURL ?? defaultFileURL())
        case .keychain:
            guard let keychain else { throw CredentialError.keychainUnavailable }
            try await keychain.delete(key)
        }
    }

    /// Whether a non-empty value exists in the requested store — for
    /// `credentials show`, which reports presence only. A store that can't
    /// answer *throws* rather than reporting absent: "not set" and
    /// "can't check" (locked keychain, insecure store file) are different
    /// answers a status command should distinguish.
    /// - Parameter fileURL: Override for the file store; must be absolute.
    public static func exists(
        _ key: CredentialKey,
        target: StoreTarget,
        fileURL: URL? = nil,
        keychain: (any KeychainBackend)? = platformKeychainBackend
    ) async throws -> Bool {
        switch target {
        case .file:
            let stored = try readStore(at: fileURL ?? defaultFileURL())[key.rawValue]
            return !(stored ?? "").isEmpty
        case .keychain:
            guard let keychain else { throw CredentialError.keychainUnavailable }
            return try await keychain.exists(key)
        }
    }
}
