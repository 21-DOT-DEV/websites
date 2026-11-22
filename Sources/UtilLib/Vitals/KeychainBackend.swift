//
//  KeychainBackend.swift
//  UtilLib
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

/// The OS credential-store boundary `CredentialStore` resolves against.
///
/// The injectable seam SC-004 requires (spec 009): unit tests substitute a
/// fake that returns stored values, proving each resolution layer wins over
/// the next — a `Bool` skip flag could only prove the layer is absent, never
/// that the layer below it loses.
///
/// Implementations distinguish *not found* (`nil` / `false` — fall through to
/// the next layer) from *couldn't answer* (thrown — a locked or unreachable
/// store degrades like an empty one during `resolve`, but surfaces from
/// `credentials` management commands).
public protocol KeychainBackend: Sendable {

    /// Reads a stored secret.
    /// - Parameter key: Which credential.
    /// - Returns: The stored value, or `nil` when no item exists.
    /// - Throws: `CredentialError.storeFailed` when the store can't answer.
    func read(_ key: CredentialKey) async throws -> String?

    /// Writes a secret, replacing any existing item for `key`.
    /// - Parameters:
    ///   - value: The secret — never argv-visible to the backend's transport.
    ///   - key: Which credential.
    func store(_ value: String, for key: CredentialKey) async throws

    /// Removes a stored secret; absent items are not an error.
    /// - Parameter key: Which credential.
    func delete(_ key: CredentialKey) async throws

    /// Whether a non-empty value exists — for `credentials show`, which
    /// never prints values. An empty item counts as absent, matching how
    /// `resolve` and the file store treat empty values.
    /// - Parameter key: Which credential.
    /// - Throws: `CredentialError.storeFailed` when the store can't answer.
    func exists(_ key: CredentialKey) async throws -> Bool
}
