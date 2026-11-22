//
//  CredentialStoreFileStoreTests.swift
//  UtilLibTests
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Testing
import UtilLib

/// The file store's security contract: owner-only modes are enforced on
/// read (`insecurePermissions`), foreign ownership gets its own remedy,
/// and a store that can't be *checked* never reports "absent". Includes
/// the `defaultFileURL` XDG-path rules — the path the contract applies to.
@Suite("Vitals — CredentialStore file store")
struct VitalsCredentialStoreFileStoreTests {

    @Test("a group/other-readable credentials file is refused")
    func looseFileRefused() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let storeURL = dir.appendingPathComponent("credentials.json")
        try writeStore(["google-api-key": "value"], at: storeURL)
        try chmod(0o644, at: storeURL)

        let error = await #expect(throws: CredentialError.self) {
            try await CredentialStore.resolve(
                .googleAPIKey,
                fileURL: storeURL,
                environment: [:],
                keychain: nil
            )
        }
        #expect(error == .insecurePermissions(path: storeURL.path, requiredMode: 0o600))
    }

    @Test("a 0700 credentials file is refused — the contract is exactly 0600")
    func executableFileRefused() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let storeURL = dir.appendingPathComponent("credentials.json")
        try writeStore(["google-api-key": "value"], at: storeURL)
        try chmod(0o700, at: storeURL)

        let error = await #expect(throws: CredentialError.self) {
            try await CredentialStore.resolve(
                .googleAPIKey,
                fileURL: storeURL,
                environment: [:],
                keychain: nil
            )
        }
        #expect(error == .insecurePermissions(path: storeURL.path, requiredMode: 0o600))
    }

    @Test("a group-only-readable credentials file is refused")
    func groupFileRefused() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let storeURL = dir.appendingPathComponent("credentials.json")
        try writeStore(["google-api-key": "value"], at: storeURL)
        try chmod(0o640, at: storeURL)

        let error = await #expect(throws: CredentialError.self) {
            try await CredentialStore.resolve(
                .googleAPIKey,
                fileURL: storeURL,
                environment: [:],
                keychain: nil
            )
        }
        #expect(error == .insecurePermissions(path: storeURL.path, requiredMode: 0o600))
    }

    @Test("a group-only-accessible containing directory is refused")
    func groupDirectoryRefused() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let storeURL = dir.appendingPathComponent("credentials.json")
        try writeStore(["google-api-key": "value"], at: storeURL)
        try chmod(0o750, at: dir)
        try chmod(0o600, at: storeURL)

        let error = await #expect(throws: CredentialError.self) {
            try await CredentialStore.resolve(
                .googleAPIKey,
                fileURL: storeURL,
                environment: [:],
                keychain: nil
            )
        }
        #expect(error == .insecurePermissions(path: dir.path, requiredMode: 0o700))
    }

    @Test("a group/other-accessible containing directory is refused")
    func looseDirectoryRefused() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let storeURL = dir.appendingPathComponent("credentials.json")
        try writeStore(["google-api-key": "value"], at: storeURL)
        try chmod(0o755, at: dir)
        try chmod(0o600, at: storeURL)

        let error = await #expect(throws: CredentialError.self) {
            try await CredentialStore.resolve(
                .googleAPIKey,
                fileURL: storeURL,
                environment: [:],
                keychain: nil
            )
        }
        #expect(error == .insecurePermissions(path: dir.path, requiredMode: 0o700))
    }

    @Test("a loose directory with no credentials file is not an error")
    func looseDirAbsentFileSkipped() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        try chmod(0o755, at: dir)

        let storeURL = dir.appendingPathComponent("credentials.json")
        let error = await #expect(throws: CredentialError.self) {
            try await CredentialStore.resolve(
                .googleAPIKey,
                fileURL: storeURL,
                environment: [:],
                keychain: nil
            )
        }
        #expect(error == .notFound(.googleAPIKey, checkedFile: storeURL))
    }

    @Test("an empty XDG_CONFIG_HOME falls back to ~/.config")
    func emptyXdgFallsBack() {
        #expect(
            CredentialStore.defaultFileURL(environment: ["XDG_CONFIG_HOME": ""])
                == CredentialStore.defaultFileURL(environment: [:])
        )
        #expect(
            CredentialStore.defaultFileURL(environment: ["XDG_CONFIG_HOME": "/tmp/xdg"])
                .path == "/tmp/xdg/util/credentials.json"
        )
    }

    @Test("a relative XDG_CONFIG_HOME falls back to ~/.config")
    func relativeXdgFallsBack() {
        // XDG requires absolute paths — "config" or ".config" must not
        // resolve a credential store under the working directory.
        #expect(
            CredentialStore.defaultFileURL(environment: ["XDG_CONFIG_HOME": ".config"])
                == CredentialStore.defaultFileURL(environment: [:])
        )
        #expect(
            CredentialStore.defaultFileURL(environment: ["XDG_CONFIG_HOME": "config"])
                == CredentialStore.defaultFileURL(environment: [:])
        )
    }

    // MARK: store mode edge cases

    @Test("a store directory missing owner-execute is refused, not absent")
    func readStoreDirMissingOwnerExec() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let storeDir = dir.appendingPathComponent("util", isDirectory: true)
        let storeURL = storeDir.appendingPathComponent("credentials.json")
        try writeStore(["google-api-key": "x"], at: storeURL)
        try chmod(0o700, at: storeDir)
        // 0600 dir: group/other are clean, but no owner-execute — every
        // probe inside fails closed, so "empty store" would be a lie.
        try chmod(0o600, at: storeDir)
        defer { try? chmod(0o700, at: storeDir) }
        let error = #expect(throws: CredentialError.self) {
            try CredentialStore.readStore(at: storeURL)
        }
        #expect(error == .insecurePermissions(path: storeDir.path, requiredMode: 0o700))
    }

    @Test("a store file missing owner-read is refused with the chmod remedy")
    func readStoreFileMissingOwnerRead() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let storeURL = dir.appendingPathComponent("credentials.json")
        try writeStore(["google-api-key": "x"], at: storeURL)
        // 000 file: no group/other access, but the read would surface a
        // raw Cocoa error — refuse with the typed error + remedy.
        try chmod(0o000, at: storeURL)
        defer { try? chmod(0o600, at: storeURL) }
        let error = #expect(throws: CredentialError.self) {
            try CredentialStore.readStore(at: storeURL)
        }
        #expect(error == .insecurePermissions(path: storeURL.path, requiredMode: 0o600))
    }

    @Test("delete refuses to silently succeed on an unreachable store")
    func deleteUnreachableStoreDir() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let storeDir = dir.appendingPathComponent("util", isDirectory: true)
        let storeURL = storeDir.appendingPathComponent("credentials.json")
        try writeStore(["google-api-key": "x"], at: storeURL)
        try chmod(0o700, at: storeDir)
        // A 0600 dir makes fileExists on the file lie "absent" — delete
        // must surface can't-answer, not claim success on a store it
        // never saw.
        try chmod(0o600, at: storeDir)
        defer { try? chmod(0o700, at: storeDir) }
        let error = #expect(throws: CredentialError.self) {
            try CredentialStore.deleteFromFile(.googleAPIKey, at: storeURL)
        }
        #expect(error == .insecurePermissions(path: storeDir.path, requiredMode: 0o700))
        // The credential is still on disk — nothing was deleted.
        try chmod(0o700, at: storeDir)
        #expect(try CredentialStore.readStore(at: storeURL) == ["google-api-key": "x"])
    }

    @Test("an untraversable ancestor makes 'absent' can't-answer, not not-found")
    func readStoreUntraversableAncestor() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let blocked = dir.appendingPathComponent("blocked", isDirectory: true)
        let storeDir = blocked.appendingPathComponent("util", isDirectory: true)
        try FileManager.default.createDirectory(at: storeDir, withIntermediateDirectories: true)
        try chmod(0o700, at: blocked)
        try chmod(0o700, at: storeDir)
        // No credentials.json — and `blocked` can't be walked, so the
        // fileExists probe would lie "absent" at any depth. The ancestor
        // walk must catch it, not report a clean miss.
        try chmod(0o600, at: blocked)
        defer { try? chmod(0o700, at: blocked) }
        let error = #expect(throws: CredentialError.self) {
            try CredentialStore.readStore(
                at: storeDir.appendingPathComponent("credentials.json")
            )
        }
        #expect(error == .insecurePermissions(path: blocked.path, requiredMode: 0o700))
    }

    @Test("a foreign-owned store directory gets the chown remedy, not chmod")
    func foreignOwnedStoreDir() throws {
        // A root-owned system directory gives the foreignOwnership branch
        // without chown fixtures: /private/etc is owned by root and
        // traversable, so "absent" would be a lie the owner check refuses.
        let storeURL = URL(fileURLWithPath: "/private/etc/credentials.json")
        let error = #expect(throws: CredentialError.self) {
            try CredentialStore.readStore(at: storeURL)
        }
        #expect(error == .foreignOwnership(path: "/private/etc"))
        // The same contract on delete — never a silent success.
        let deleteError = #expect(throws: CredentialError.self) {
            try CredentialStore.deleteFromFile(.googleAPIKey, at: storeURL)
        }
        #expect(deleteError == .foreignOwnership(path: "/private/etc"))
    }

    @Test("a file where the store directory belongs fails typed, not raw")
    func storeDirIsFile() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        // `<dir>/util` exists as a regular FILE — createDirectory can't
        // descend into it, and the raw Cocoa error must not leak.
        let blocker = dir.appendingPathComponent("util")
        try "not a dir".write(to: blocker, atomically: true, encoding: .utf8)

        let error = #expect(throws: CredentialError.self) {
            try CredentialStore.storeInFile(
                "v", for: .googleAPIKey,
                at: blocker.appendingPathComponent("credentials.json")
            )
        }
        guard case .storeFailed = error else {
            Issue.record("expected .storeFailed, got \(String(describing: error))")
            return
        }
    }

    @Test("a directory masquerading as the store file fails typed, not raw")
    func readStoreIsDirectory() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        // `credentials.json` is itself a 0700 directory — the mode check
        // passes (owner bits are satisfied) and the read must surface
        // .storeFailed, not NSCocoaError 257.
        let storeURL = dir.appendingPathComponent("credentials.json", isDirectory: true)
        try FileManager.default.createDirectory(at: storeURL, withIntermediateDirectories: true)
        try chmod(0o700, at: storeURL)

        let error = #expect(throws: CredentialError.self) {
            try CredentialStore.readStore(at: storeURL)
        }
        guard case .storeFailed = error else {
            Issue.record("expected .storeFailed, got \(String(describing: error))")
            return
        }
    }
}
