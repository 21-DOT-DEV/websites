//
//  SecurityCLIKeychainBackend.swift
//  UtilLib
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

#if os(macOS)
import Foundation
import Subprocess
#if canImport(System)
import System
#endif

/// `KeychainBackend` over `/usr/bin/security` — generic-password CRUD through
/// Apple's command-line interface to the file-based keychain.
///
/// Chosen over the `Security` framework for a deliberately ad-hoc-signed
/// binary: `SecItemAdd` binds each item's ACL to the *creating binary's
/// cdhash*, so every `swift run` rebuild would re-prompt on read. Items
/// written by `security(1)` instead trust `/usr/bin/security` — a stable,
/// Apple-signed binary — so reads are prompt-free from any parent process.
/// The trade-off is per-app isolation: any same-UID process can read or
/// overwrite these items via `security`, exactly as it could a 0600 file —
/// the store is encrypted at rest and OS-brokered, not sandboxed.
/// Precedent: RubyGems' `Gem::CredentialStore::MacOSBackend`, Fastlane's
/// `security` gem, and the spec's own research (`Development/Specs/
/// 009-cwv-baseline/research.md` D4).
///
/// Writes go through `security -i`, the stdin-fed command interpreter —
/// `add-generic-password -w` is the only non-interactive write path and it
/// would place the secret in argv, visible to `ps`; the interpreter keeps it
/// on the stdin stream instead (the same technique RubyGems documents).
public struct SecurityCLIKeychainBackend: KeychainBackend {

    /// The `kSecAttrService` equivalent — `-s` on every command.
    public let service: String

    /// Keychain to act on — a `.keychain-db` path passed as the trailing
    /// keychain argument on every command, or `nil` for the default
    /// search list (the login keychain). Settable so checks can run
    /// against a throwaway keychain instead of the real one — the
    /// `keychain:` model the fastlane-community `security` gem takes.
    public let keychainPath: String?

    /// - Parameters:
    ///   - service: Keychain service name items are stored under.
    ///   - keychain: Keychain file to act on; `nil` for the default list.
    public init(service: String = CredentialStore.keychainService, keychain: String? = nil) {
        self.service = service
        self.keychainPath = keychain
    }

    /// The trailing keychain positional argument, when one is set.
    private var keychainArguments: [String] {
        keychainPath.map { [$0] } ?? []
    }

    /// A configured keychain file that doesn't exist is a can't-answer
    /// error, not an absent item — `security` reports a missing keychain
    /// file as exit 44 with the *item* not-found phrase (verified), which
    /// the classifier would otherwise mistake for "not stored" and let
    /// `delete` claim success on a store it never reached.
    private func requireKeychainFile() throws {
        // Only a caller-supplied path is screened — the default search
        // list's login keychain exists in every live user session.
        if let keychainPath,
           !FileManager.default.fileExists(atPath: keychainPath) {
            throw CredentialError.storeFailed("keychain file does not exist: \(keychainPath)")
        }
    }

    public func read(_ key: CredentialKey) async throws -> String? {
        try requireKeychainFile()
        // `-g` prints `password: "…"` to stderr for plain text, or
        // `password: 0x<hex> "<display>"` for values containing backslashes
        // or non-printable bytes. `-w` would hand back a bare-hex blob as
        // a "secret"
        // and shadow a correct file-store entry, so parse the `-g` form
        // and treat undecodable output as can't-answer (degrade to file).
        let result = try await Self.security(
            ["find-generic-password", "-a", key.rawValue, "-s", service, "-g"] + keychainArguments
        )
        guard result.succeeded else {
            if result.notFound { return nil }
            throw CredentialError.storeFailed("security find-generic-password: \(result.standardError)")
        }
        return try Self.parsePassword(stderr: result.standardError)
    }

    public func store(_ value: String, for key: CredentialKey) async throws {
        try requireKeychainFile()
        // The `-i` stream tokenizes on whitespace and `find` renders
        // non-printable bytes as hex — control or non-ASCII input would
        // either break out of the quoted span or round-trip corrupted.
        // Printable ASCII only (RubyGems' constraint); the file store
        // keeps full UTF-8 for secrets this transport can't carry.
        guard Self.isPrintableASCII(value), Self.isPrintableASCII(service),
              keychainPath.map(Self.isPrintableASCII) ?? true else {
            throw CredentialError.storeFailed(
                "secret, service, and keychain path must be a single printable-ASCII line — use --target file otherwise"
            )
        }
        var command = "add-generic-password -U -a \(Self.quote(key.rawValue))"
            + " -s \(Self.quote(service)) -w \(Self.quote(value))"
        if let keychainPath { command += " \(Self.quote(keychainPath))" }
        command += "\n"
        // The `-i` interpreter's line-length limit is undocumented —
        // refuse outsized commands rather than risk a truncated write.
        guard command.utf8.count <= 1024 else {
            throw CredentialError.storeFailed("secret is too long for the security transport — use --target file")
        }
        let result = try await Self.security(["-i"], input: command)
        guard result.succeeded else {
            throw CredentialError.storeFailed("security add-generic-password: \(result.standardError)")
        }
        // `-i`'s exit status can't be trusted to report the inner add —
        // observed exiting 0 despite an inner failure on some systems.
        // Verify the write landed rather than trust the interpreter;
        // a can't-answer read surfaces its own error.
        guard try await read(key) == value else {
            throw CredentialError.storeFailed("security add-generic-password: write did not land")
        }
    }

    public func delete(_ key: CredentialKey) async throws {
        try requireKeychainFile()
        // One invocation removes only the FIRST match — a duplicate
        // written out of band (or on another keychain in the default
        // search list) survives a "successful" delete and keeps
        // resolving. Repeat until absent; each success consumes one.
        // Bounded — a `security` that reports success without removing
        // anything (corrupted or read-only keychain) must not spin.
        for _ in 0..<64 {
            let result = try await Self.security(
                ["delete-generic-password", "-a", key.rawValue, "-s", service] + keychainArguments
            )
            if result.notFound { return }
            guard result.succeeded else {
                throw CredentialError.storeFailed("security delete-generic-password: \(result.standardError)")
            }
        }
        throw CredentialError.storeFailed(
            "security delete-generic-password: item survives repeated deletes"
        )
    }

    public func exists(_ key: CredentialKey) async throws -> Bool {
        try requireKeychainFile()
        let result = try await Self.security(
            ["find-generic-password", "-a", key.rawValue, "-s", service, "-w"] + keychainArguments
        )
        if result.notFound { return false }
        guard result.succeeded else {
            throw CredentialError.storeFailed("security find-generic-password: \(result.standardError)")
        }
        // `-w` prints the secret plus a trailing newline — presence means
        // a *non-empty* value so `show` agrees with `resolve` even for
        // items written outside `store` (which rejects empty).
        var output = result.standardOutput
        if output.hasSuffix("\n") { output.removeLast() }
        return !output.isEmpty
    }

    // MARK: - security(1) transport

    /// A collected `security` invocation: exit status, stdout, stderr.
    /// `package` — tests exercise the classifier without `@testable`
    /// (ADR-0007).
    package struct CLIResult {
        package let succeeded: Bool
        package let exitCode: CInt?
        package let standardOutput: String
        package let standardError: String

        package init(succeeded: Bool, exitCode: CInt?, standardOutput: String, standardError: String) {
            self.succeeded = succeeded
            self.exitCode = exitCode
            self.standardOutput = standardOutput
            self.standardError = standardError
        }

        /// An absent item is reported by exit code 44
        /// (`errSecItemNotFound` — the locale-independent signal,
        /// verified against live `security` output). The stderr phrase
        /// alone is *not* sufficient: can't-answer states can emit it
        /// with other codes, and "absent" is the one answer that must
        /// never be a guess. A *missing keychain file* produces the same
        /// 44 + phrase pair — `requireKeychainFile` screens the
        /// configured-path case before this runs.
        package var notFound: Bool {
            exitCode == 44
        }
    }

    /// Extracts the secret from `-g`'s stderr `password:` line, which
    /// comes in two forms — `password: "value"` for plain text (embedded
    /// `"` emitted raw) and `password: 0x<hex>  "<display>"` whenever the
    /// bytes contain a backslash or non-printables. The hex form decodes
    /// to the real bytes, so out-of-band non-ASCII items still read
    /// correctly; only non-UTF-8 payloads or a missing line are
    /// can't-answer. `package` — pure parsing, unit-tested without
    /// `@testable`.
    package static func parsePassword(stderr: String) throws -> String {
        for line in stderr.split(separator: "\n", omittingEmptySubsequences: false) {
            guard line.hasPrefix("password: ") else { continue }
            let payload = line.dropFirst("password: ".count)
            if payload.hasPrefix("0x") {
                let hexEnd = payload.firstIndex(of: " ") ?? payload.endIndex
                let hex = payload[payload.index(payload.startIndex, offsetBy: 2)..<hexEnd]
                // Whole bytes only — an odd nibble count is malformed
                // output, and stepping by 2 past endIndex would trap.
                guard hex.count.isMultiple(of: 2) else {
                    throw CredentialError.storeFailed("keychain item holds non-text data — use --target file")
                }
                var bytes: [UInt8] = []
                var index = hex.startIndex
                while index < hex.endIndex {
                    guard let byte = UInt8(hex[index...].prefix(2), radix: 16) else {
                        throw CredentialError.storeFailed("keychain item holds non-text data — use --target file")
                    }
                    bytes.append(byte)
                    index = hex.index(index, offsetBy: 2)
                }
                guard let value = String(bytes: bytes, encoding: .utf8) else {
                    throw CredentialError.storeFailed("keychain item holds non-text data — use --target file")
                }
                return value
            }
            // The quoted form is literal — `security` emits embedded `"`
            // raw (`password: "say"hi"`), so the value is everything
            // between the first and last quote, with nothing to unescape.
            guard payload.count >= 2, payload.hasPrefix("\""), payload.hasSuffix("\"") else {
                throw CredentialError.storeFailed("keychain item holds non-text data — use --target file")
            }
            return String(payload.dropFirst().dropLast())
        }
        throw CredentialError.storeFailed("security find-generic-password: no password in output")
    }

    /// Runs `/usr/bin/security` by absolute path — never via `PATH` lookup,
    /// so a shadowed `security` can't intercept the secrets fed to `-i`.
    /// Bounded at 15s: a GUI unlock prompt can block `security`
    /// indefinitely, and a bounded wait still degrades to can't-answer
    /// rather than hanging resolution.
    private static func security(_ arguments: [String], input: String? = nil) async throws -> CLIResult {
        try await withThrowingTaskGroup(of: CLIResult.self) { group in
            group.addTask { try await invokeSecurity(arguments, input: input) }
            group.addTask {
                try await Task.sleep(for: .seconds(15))
                throw CredentialError.storeFailed("security timed out — the keychain may be locked")
            }
            defer { group.cancelAll() }
            return try await group.next()!
        }
    }

    private static func invokeSecurity(_ arguments: [String], input: String?) async throws -> CLIResult {
        do {
            let result = try await Subprocess.run(
                .path("/usr/bin/security"),
                arguments: .init(arguments),
                input: .data(input.map { Data($0.utf8) } ?? Data()),
                output: .string(limit: 64 * 1024),
                error: .string(limit: 64 * 1024)
            )
            let exitCode: CInt?
            if case .exited(let code) = result.terminationStatus {
                exitCode = code
            } else {
                exitCode = nil
            }
            return CLIResult(
                succeeded: result.terminationStatus.isSuccess,
                exitCode: exitCode,
                standardOutput: result.standardOutput ?? "",
                standardError: result.standardError ?? ""
            )
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            // Spawn/teardown/output-limit failures are can't-answer
            // conditions — surface the typed error the protocol
            // promises rather than leaking a SubprocessError.
            throw CredentialError.storeFailed("security could not run: \(error)")
        }
    }

    /// One line of printable ASCII (0x20–0x7E) — the `security -i`
    /// transport's constraint: control characters break tokenization and
    /// output renders non-printable bytes as hex. `package` — unit-tested
    /// without `@testable`.
    package static func isPrintableASCII(_ value: String) -> Bool {
        value.utf8.allSatisfy { (0x20...0x7E).contains($0) }
    }

    /// Double-quotes a value for the `security -i` command stream, escaping
    /// the two characters that would break out of the quoted span.
    /// `package` — unit-tested without `@testable`.
    package static func quote(_ value: String) -> String {
        "\"" + value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            + "\""
    }
}
#endif
