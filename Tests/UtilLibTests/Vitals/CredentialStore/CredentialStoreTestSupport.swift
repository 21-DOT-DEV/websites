//
//  CredentialStoreTestSupport.swift
//  UtilLibTests
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import UtilLib

// Shared fixtures for the `CredentialStore` suites: an in-memory
// `KeychainBackend` — the seam that proves precedence — plus the temp-dir
// store builders every suite uses. The backend's pure logic is exercised
// through `package` access (no `@testable` — ADR-0007), and an env-gated
// check in CredentialStoreSecurityCLITests covers the live `security(1)`
// subprocess path a fake can't exercise.

actor FakeKeychain: KeychainBackend {
    var values: [CredentialKey: String] = [:]
    var failure: (any Error)?

    func read(_ key: CredentialKey) async throws -> String? {
        if let failure { throw failure }
        return values[key]
    }
    func store(_ value: String, for key: CredentialKey) async throws {
        if let failure { throw failure }
        values[key] = value
    }
    func delete(_ key: CredentialKey) async throws {
        if let failure { throw failure }
        values.removeValue(forKey: key)
    }
    func exists(_ key: CredentialKey) async throws -> Bool {
        if let failure { throw failure }
        return !(values[key] ?? "").isEmpty
    }
    func setFailure(_ error: (any Error)?) { failure = error }
}

/// A 0700 temp directory — the compliant fixture each test then breaks
/// exactly one thing about. Resolved up front so paths match the
/// canonicalized URLs the store reports (`checkedFile` and friends
/// resolve `/var` → `/private/var` on macOS).
func makeTempDir() throws -> URL {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("credential-store-tests-\(UUID().uuidString)", isDirectory: true)
        .resolvingSymlinksInPath()
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    try chmod(0o700, at: dir)
    return dir
}

/// A compliant 0600 store file inside an already-compliant directory.
func writeStore(_ dict: [String: String], at url: URL) throws {
    try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(), withIntermediateDirectories: true
    )
    let data = try JSONSerialization.data(withJSONObject: dict)
    try data.write(to: url)
    try chmod(0o600, at: url)
}

func chmod(_ mode: Int, at url: URL) throws {
    try FileManager.default.setAttributes([.posixPermissions: mode], ofItemAtPath: url.path)
}

func mode(of url: URL) throws -> Int {
    let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
    return (attrs[.posixPermissions] as? NSNumber)?.intValue ?? -1
}
