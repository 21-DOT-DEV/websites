//
//  CredentialStoreSecurityCLITests.swift
//  UtilLibTests
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

#if os(macOS)
import Foundation
import Testing
import UtilLib

/// `SecurityCLIKeychainBackend` internals — the `security(1)` transport's
/// pure surface (`CLIResult` classification, `-g` output parsing, `-i`
/// quoting, the ASCII guard) exercised through `package` access, plus the
/// env-gated live check against a throwaway keychain that covers the real
/// subprocess path a fake can't.
@Suite("Vitals — CredentialStore SecurityCLI backend")
struct VitalsCredentialStoreSecurityCLITests {

    @Test("quote escapes the characters that break out of a quoted span")
    func quoteEscapes() {
        #expect(SecurityCLIKeychainBackend.quote(#"a "b" c\d"#) == #""a \"b\" c\\d""#)
        #expect(SecurityCLIKeychainBackend.quote("plain") == #""plain""#)
    }

    @Test("not-found classification keys on exit 44 only, never the item phrase")
    func notFoundClassifier() {
        // Exit 44 = errSecItemNotFound — not-found even with empty stderr.
        #expect(
            SecurityCLIKeychainBackend.CLIResult(
                succeeded: false, exitCode: 44, standardOutput: "", standardError: ""
            ).notFound == true
        )
        // The item-specific stderr phrase alone is NOT absent — a
        // non-44 exit with the phrase is a can't-answer state, not
        // "not stored". Absent must never be a guess.
        #expect(
            SecurityCLIKeychainBackend.CLIResult(
                succeeded: false, exitCode: 1, standardOutput: "",
                standardError: "The specified item could not be found in the keychain."
            ).notFound == false
        )
        // The *keychain* variant of the phrase is couldn't-answer, not
        // absent. A missing keychain FILE reports the item phrase + exit
        // 44 instead (verified) — `requireKeychainFile` screens that
        // before this classifier ever runs; see missingKeychainFile.
        #expect(
            SecurityCLIKeychainBackend.CLIResult(
                succeeded: false, exitCode: 50, standardOutput: "",
                standardError: "The specified keychain could not be found."
            ).notFound == false
        )
        // A locked keychain is couldn't-answer.
        #expect(
            SecurityCLIKeychainBackend.CLIResult(
                succeeded: false, exitCode: 51, standardOutput: "",
                standardError: "User interaction is not allowed"
            ).notFound == false
        )
    }

    @Test("printable-ASCII guard rejects control and non-ASCII input")
    func printableASCIIGuard() async throws {
        #expect(SecurityCLIKeychainBackend.isPrintableASCII("cf-token_123") == true)
        #expect(SecurityCLIKeychainBackend.isPrintableASCII("with space") == true)
        #expect(SecurityCLIKeychainBackend.isPrintableASCII("café") == false)
        #expect(SecurityCLIKeychainBackend.isPrintableASCII("line\nbreak") == false)
        // DEL is control, not printable — the upper bound is 0x7E.
        #expect(SecurityCLIKeychainBackend.isPrintableASCII("a\u{7f}") == false)

        // Rejected before any subprocess — the real backend is never invoked.
        let backend = SecurityCLIKeychainBackend()
        await #expect(throws: CredentialError.self) {
            try await backend.store("café", for: .googleAPIKey)
        }
        let badService = SecurityCLIKeychainBackend(service: "svc\ninject")
        await #expect(throws: CredentialError.self) {
            try await badService.store("ok", for: .googleAPIKey)
        }

        // A newline in the keychain path would break the `-i` line into
        // a second interpreter command — the path gets the same guard.
        // The file must exist or `requireKeychainFile` fires first.
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let nlKeychain = dir.appendingPathComponent("k\ninject.keychain-db").path
        _ = FileManager.default.createFile(atPath: nlKeychain, contents: nil)
        let badPath = SecurityCLIKeychainBackend(service: "ok", keychain: nlKeychain)
        await #expect(throws: CredentialError.self) {
            try await badPath.store("ok", for: .googleAPIKey)
        }
    }

    @Test("a configured but missing keychain file is can't-answer, not absent")
    func missingKeychainFile() async throws {
        // Real `security` reports a missing keychain file as exit 44
        // with the *item* not-found phrase — without the file-existence
        // pre-check, read would lie "absent", exists "false", and delete
        // "success" on a store it never reached.
        let backend = SecurityCLIKeychainBackend(
            service: "dev.21.websites.util.check",
            keychain: "/nonexistent/missing.keychain-db"
        )
        await #expect(throws: CredentialError.self) {
            _ = try await backend.read(.googleAPIKey)
        }
        await #expect(throws: CredentialError.self) {
            _ = try await backend.exists(.googleAPIKey)
        }
        await #expect(throws: CredentialError.self) {
            try await backend.delete(.googleAPIKey)
        }
        await #expect(throws: CredentialError.self) {
            try await backend.store("v", for: .googleAPIKey)
        }
    }

    @Test("parsePassword decodes quoted and hex password lines")
    func parsePasswordForms() throws {
        // The plain-text form.
        #expect(
            try SecurityCLIKeychainBackend.parsePassword(
                stderr: "password: \"s3cr3t!\"\n"
            ) == "s3cr3t!"
        )
        // The hex+display form — out-of-band non-ASCII items decode.
        #expect(
            try SecurityCLIKeychainBackend.parsePassword(
                stderr: "password: 0x636166C3A9  \"caf\\303\\251\"\n"
            ) == "café"
        )
        // Metadata lines around the password line are skipped, and an
        // embedded quote stays raw inside the quoted form — first/last
        // quote are the delimiters (verified against real -g output).
        #expect(
            try SecurityCLIKeychainBackend.parsePassword(
                stderr: "keychain: \"/tmp/k\"\npassword: \"say\"hi\"\n"
            ) == "say\"hi"
        )
        // Non-UTF-8 hex is can't-answer — resolve degrades to the file.
        #expect(throws: CredentialError.self) {
            try SecurityCLIKeychainBackend.parsePassword(stderr: "password: 0xFFFF00\n")
        }
        // Odd-length hex is malformed output — throw, don't trap on the
        // unbounded index advance.
        #expect(throws: CredentialError.self) {
            try SecurityCLIKeychainBackend.parsePassword(stderr: "password: 0xFFF\n")
        }
        // An unquoted, non-hex payload is can't-answer.
        #expect(throws: CredentialError.self) {
            try SecurityCLIKeychainBackend.parsePassword(stderr: "password: <opaque>\n")
        }
        // No password line at all is can't-answer.
        #expect(throws: CredentialError.self) {
            try SecurityCLIKeychainBackend.parsePassword(stderr: "keychain: \"/tmp/k\"\n")
        }
    }

    /// Drives `security` for keychain lifecycle — the live check creates
    /// and deletes a throwaway keychain, never touching login.
    private static func runSecurity(_ arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        process.arguments = arguments
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw CredentialError.storeFailed(
                "security \(arguments.first ?? "") exited \(process.terminationStatus)"
            )
        }
    }

    /// The documented live check — a full round-trip against a throwaway
    /// keychain covering the `-i` write path, `-g` read parse, `exists`,
    /// and `delete`. Set RUN_LIVE_KEYCHAIN_CHECK=1 to run it.
    @Test(
        "live keychain round-trip on a throwaway keychain",
        .enabled(
            if: ProcessInfo.processInfo.environment["RUN_LIVE_KEYCHAIN_CHECK"] == "1",
            "live check — set RUN_LIVE_KEYCHAIN_CHECK=1 (creates/deletes a temp keychain)"
        )
    )
    func liveKeychainRoundTrip() async throws {
        let keychain = FileManager.default.temporaryDirectory
            .appendingPathComponent("vitals-check-\(UUID().uuidString).keychain-db")
        defer { _ = try? Self.runSecurity(["delete-keychain", keychain.path]) }
        try Self.runSecurity(["create-keychain", "-p", "test", keychain.path])
        try Self.runSecurity(["unlock-keychain", "-p", "test", keychain.path])
        try Self.runSecurity(["set-keychain-settings", keychain.path])

        let backend = SecurityCLIKeychainBackend(
            service: "dev.21.websites.util.check", keychain: keychain.path
        )
        try await backend.store("s3cr3t!", for: .googleAPIKey)
        #expect(try await backend.exists(.googleAPIKey) == true)
        #expect(try await backend.read(.googleAPIKey) == "s3cr3t!")
        try await backend.delete(.googleAPIKey)
        #expect(try await backend.exists(.googleAPIKey) == false)
        #expect(try await backend.read(.googleAPIKey) == nil)

        // Duplicates of one -a/-s can't exist inside a single keychain —
        // `add-generic-password` answers errSecDuplicateItem (exit 45,
        // verified). They only arise across the default search list
        // (login + others), which this check can't touch without
        // mutating real user state; `delete` still loops until notFound
        // for that case (RubyGems' delete_all precedent) — exercised
        // here by the single-item delete above, which iterates once to
        // delete and once more to observe notFound.

        // `security -i`'s exit status can't be trusted to report the
        // inner add — the post-write read must surface the failure. A
        // keychain path that exists but is not a keychain file exercises
        // that path (a *missing* file is refused earlier by
        // requireKeychainFile).
        let notAKeychain = FileManager.default.temporaryDirectory
            .appendingPathComponent("not-a-keychain-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: notAKeychain) }
        _ = FileManager.default.createFile(atPath: notAKeychain.path, contents: Data("junk".utf8))
        let bogus = SecurityCLIKeychainBackend(
            service: "dev.21.websites.util.check", keychain: notAKeychain.path
        )
        await #expect(throws: CredentialError.self) {
            try await bogus.store("x", for: .googleAPIKey)
        }
    }
}
#endif
