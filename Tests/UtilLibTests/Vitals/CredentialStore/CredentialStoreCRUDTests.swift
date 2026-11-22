//
//  CredentialStoreCRUDTests.swift
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

/// `CredentialStore` operations — `store`/`delete`/`exists` against both
/// targets, `storeInFile`/`deleteFromFile`/`readStore` semantics (healing,
/// refusal to clobber malformed stores, absent no-ops), and
/// `readSecretFile`. Keychain-target tests go through `FakeKeychain`.
@Suite("Vitals — CredentialStore CRUD")
struct VitalsCredentialStoreCRUDTests {

    @Test("storeInFile heals the directory to 0700 and writes 0600")
    func storeHealsPermissions() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        try chmod(0o755, at: dir)
        let storeURL = dir.appendingPathComponent("credentials.json")

        try CredentialStore.storeInFile("value", for: .googleAPIKey, at: storeURL)

        #expect(try mode(of: dir) == 0o700)
        #expect(try mode(of: storeURL) == 0o600)
        #expect(try CredentialStore.readStore(at: storeURL) == ["google-api-key": "value"])
    }

    @Test("storeInFile heals a loose directory around an existing store")
    func storeHealsExistingDir() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let storeURL = dir.appendingPathComponent("credentials.json")
        try writeStore(["cloudflare-zone-id": "existing"], at: storeURL)
        try chmod(0o755, at: dir)

        try CredentialStore.storeInFile("new", for: .googleAPIKey, at: storeURL)

        #expect(try mode(of: dir) == 0o700)
        #expect(try CredentialStore.readStore(at: storeURL) == [
            "cloudflare-zone-id": "existing",
            "google-api-key": "new",
        ])
    }

    @Test("store rejects empty values on both targets")
    func storeRejectsEmpty() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let storeURL = dir.appendingPathComponent("credentials.json")

        let fileError = await #expect(throws: CredentialError.self) {
            try await CredentialStore.store("", for: .googleAPIKey, target: .file, fileURL: storeURL)
        }
        #expect(fileError == .storeFailed("credential value must not be empty"))

        let keychainError = await #expect(throws: CredentialError.self) {
            try await CredentialStore.store(
                "", for: .googleAPIKey, target: .keychain, keychain: FakeKeychain()
            )
        }
        #expect(keychainError == .storeFailed("credential value must not be empty"))
        // Nothing reached the file layer either.
        #expect(!FileManager.default.fileExists(atPath: storeURL.path))
    }

    @Test("storeInFile refuses to clobber a malformed existing store")
    func storeRefusesMalformed() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let storeURL = dir.appendingPathComponent("credentials.json")
        try "not json {".write(to: storeURL, atomically: true, encoding: .utf8)
        try chmod(0o600, at: storeURL)

        #expect(throws: CredentialError.self) {
            try CredentialStore.storeInFile("value", for: .googleAPIKey, at: storeURL)
        }
        // The malformed content survives — repair is the maintainer's call.
        #expect(try String(contentsOf: storeURL, encoding: .utf8) == "not json {")
    }

    @Test("malformed credentials JSON fails readStore")
    func malformedRead() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let storeURL = dir.appendingPathComponent("credentials.json")
        try "not json {".write(to: storeURL, atomically: true, encoding: .utf8)
        try chmod(0o600, at: storeURL)

        let error = #expect(throws: CredentialError.self) {
            try CredentialStore.readStore(at: storeURL)
        }
        #expect(error == .storeFailed("\(storeURL.path) is not valid JSON"))
    }

    @Test("deleteFromFile removes the key and preserves 0600")
    func deleteRemoves() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let storeURL = dir.appendingPathComponent("credentials.json")
        try CredentialStore.storeInFile("a", for: .googleAPIKey, at: storeURL)
        try CredentialStore.storeInFile("b", for: .cloudflareZoneID, at: storeURL)

        try CredentialStore.deleteFromFile(.googleAPIKey, at: storeURL)

        #expect(try CredentialStore.readStore(at: storeURL) == ["cloudflare-zone-id": "b"])
        #expect(try mode(of: storeURL) == 0o600)
    }

    @Test("file exists reports presence for stored values only")
    func existsFile() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let storeURL = dir.appendingPathComponent("credentials.json")

        #expect(try await CredentialStore.exists(.googleAPIKey, target: .file, fileURL: storeURL) == false)

        try CredentialStore.storeInFile("value", for: .googleAPIKey, at: storeURL)
        try CredentialStore.storeInFile("", for: .cloudflareZoneID, at: storeURL)

        #expect(try await CredentialStore.exists(.googleAPIKey, target: .file, fileURL: storeURL) == true)
        #expect(try await CredentialStore.exists(.cloudflareZoneID, target: .file, fileURL: storeURL) == false)

        // A store it can't read is an error, not "not set" — `credentials
        // show` must distinguish absent from can't-answer.
        try chmod(0o644, at: storeURL)
        let error = await #expect(throws: CredentialError.self) {
            try await CredentialStore.exists(.googleAPIKey, target: .file, fileURL: storeURL)
        }
        #expect(error == .insecurePermissions(path: storeURL.path, requiredMode: 0o600))
    }

    @Test("deleteFromFile on an absent store is a no-op")
    func deleteAbsentNoOp() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let storeURL = dir.appendingPathComponent("credentials.json")

        try CredentialStore.deleteFromFile(.googleAPIKey, at: storeURL)

        #expect(!FileManager.default.fileExists(atPath: storeURL.path))
    }

    // MARK: secret-file input + store/delete/exists targets

    @Test("readSecretFile trims surrounding whitespace")
    func secretFileTrimmed() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("secret.txt")
        try "  token-with-newline\n".write(to: file, atomically: true, encoding: .utf8)

        #expect(try CredentialStore.readSecretFile(at: file) == "token-with-newline")
    }

    @Test("a missing secret file fails typed, not raw")
    func missingSecretFile() {
        // A --…-file flag pointing nowhere must surface CredentialError,
        // not a raw NSCocoaError 260.
        let missing = URL(fileURLWithPath: "/nonexistent/secret-\(UUID().uuidString)")
        let error = #expect(throws: CredentialError.self) {
            try CredentialStore.readSecretFile(at: missing)
        }
        guard case .storeFailed = error else {
            Issue.record("expected .storeFailed, got \(String(describing: error))")
            return
        }
    }

    @Test("an empty secret file names the file, not a key")
    func emptySecretFile() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("empty.txt")
        try "\n".write(to: file, atomically: true, encoding: .utf8)

        let error = #expect(throws: CredentialError.self) {
            try CredentialStore.readSecretFile(at: file)
        }
        #expect(error == .emptySecretFile(path: file.path))
    }

    @Test("store/delete/exists route to the injected keychain backend")
    func storeTargetsKeychain() async throws {
        let fake = FakeKeychain()

        try await CredentialStore.store("secret", for: .googleAPIKey, target: .keychain, keychain: fake)
        #expect(try await fake.exists(.googleAPIKey) == true)
        #expect(try await CredentialStore.exists(.googleAPIKey, target: .keychain, keychain: fake) == true)

        try await CredentialStore.delete(.googleAPIKey, target: .keychain, keychain: fake)
        #expect(try await CredentialStore.exists(.googleAPIKey, target: .keychain, keychain: fake) == false)
    }

    @Test("an empty keychain item written out-of-band reports absent, matching resolve")
    func existsKeychainEmptyItem() async throws {
        // An item `store` would reject but a foreign write could leave —
        // `exists` must agree with `resolve`, which skips empty values.
        let fake = FakeKeychain()
        try await fake.store("", for: .googleAPIKey)

        #expect(try await CredentialStore.exists(.googleAPIKey, target: .keychain, keychain: fake) == false)
    }

    @Test("keychain target without a backend reports unavailable")
    func keychainUnavailable() async throws {
        let error = await #expect(throws: CredentialError.self) {
            try await CredentialStore.store("v", for: .googleAPIKey, target: .keychain, keychain: nil)
        }
        #expect(error == .keychainUnavailable)
        let existsError = await #expect(throws: CredentialError.self) {
            try await CredentialStore.exists(.googleAPIKey, target: .keychain, keychain: nil)
        }
        #expect(existsError == .keychainUnavailable)
    }
}
