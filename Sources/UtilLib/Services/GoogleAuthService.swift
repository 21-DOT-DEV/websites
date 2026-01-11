//
//  GoogleAuthService.swift
//  UtilLib
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Subprocess

// MARK: - GoogleAuthError

/// Errors that can occur during Google authentication operations.
public enum GoogleAuthError: Error, Equatable, Sendable {
    /// The service account JSON is invalid or missing required fields.
    case invalidServiceAccountJSON(String)
    
    /// Failed to sign the JWT.
    case signingFailed(String)
    
    /// Failed to exchange JWT for access token.
    case tokenExchangeFailed(String)
    
    /// No credentials provided (neither file nor JSON string).
    case noCredentialsProvided
    
    /// The credentials file could not be read.
    case credentialsFileNotFound(String)
}

extension GoogleAuthError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidServiceAccountJSON(let reason):
            return "Invalid service account JSON: \(reason)"
        case .signingFailed(let reason):
            return "Failed to sign JWT: \(reason)"
        case .tokenExchangeFailed(let reason):
            return "Failed to exchange token: \(reason)"
        case .noCredentialsProvided:
            return "No credentials provided. Set GOOGLE_SERVICE_ACCOUNT_JSON, GOOGLE_APPLICATION_CREDENTIALS, or use --credentials-file"
        case .credentialsFileNotFound(let path):
            return "Credentials file not found: \(path)"
        }
    }
}

// MARK: - ServiceAccountCredentials

/// Parsed service account credentials from JSON.
public struct ServiceAccountCredentials: Sendable {
    public let clientEmail: String
    public let privateKey: String
    
    public init(clientEmail: String, privateKey: String) {
        self.clientEmail = clientEmail
        self.privateKey = privateKey
    }
}

// MARK: - GoogleAuthService

/// Service for Google OAuth 2.0 authentication using service account credentials.
public enum GoogleAuthService {
    
    /// Google OAuth token endpoint.
    public static let tokenEndpoint = "https://oauth2.googleapis.com/token"
    
    /// Scope for Google Search Console / Webmasters API.
    public static let webmastersScope = "https://www.googleapis.com/auth/webmasters"
    
    // MARK: - Credential Resolution
    
    /// Resolves credentials from file path, JSON string, or environment variables.
    /// Priority: filePath > jsonString > GOOGLE_APPLICATION_CREDENTIALS > GOOGLE_SERVICE_ACCOUNT_JSON
    public static func resolveCredentials(
        filePath: String? = nil,
        jsonString: String? = nil
    ) throws -> ServiceAccountCredentials {
        // 1. Explicit file path
        if let filePath = filePath {
            guard FileManager.default.fileExists(atPath: filePath) else {
                throw GoogleAuthError.credentialsFileNotFound(filePath)
            }
            let json = try String(contentsOfFile: filePath, encoding: .utf8)
            return try parseServiceAccountJSON(json)
        }
        
        // 2. Explicit JSON string
        if let jsonString = jsonString {
            return try parseServiceAccountJSON(jsonString)
        }
        
        // 3. GOOGLE_APPLICATION_CREDENTIALS env var (file path)
        if let envFilePath = ProcessInfo.processInfo.environment["GOOGLE_APPLICATION_CREDENTIALS"] {
            guard FileManager.default.fileExists(atPath: envFilePath) else {
                throw GoogleAuthError.credentialsFileNotFound(envFilePath)
            }
            let json = try String(contentsOfFile: envFilePath, encoding: .utf8)
            return try parseServiceAccountJSON(json)
        }
        
        // 4. GOOGLE_SERVICE_ACCOUNT_JSON env var (raw JSON)
        if let envJSON = ProcessInfo.processInfo.environment["GOOGLE_SERVICE_ACCOUNT_JSON"] {
            return try parseServiceAccountJSON(envJSON)
        }
        
        throw GoogleAuthError.noCredentialsProvided
    }
    
    // MARK: - JSON Parsing
    
    /// Parses service account JSON and extracts required fields.
    public static func parseServiceAccountJSON(_ json: String) throws -> ServiceAccountCredentials {
        guard let data = json.data(using: .utf8) else {
            throw GoogleAuthError.invalidServiceAccountJSON("Invalid encoding")
        }
        
        let parsed: [String: Any]
        do {
            parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        } catch {
            throw GoogleAuthError.invalidServiceAccountJSON("Invalid JSON: \(error.localizedDescription)")
        }
        
        guard let clientEmail = parsed["client_email"] as? String else {
            throw GoogleAuthError.invalidServiceAccountJSON("Missing client_email")
        }
        
        guard let privateKey = parsed["private_key"] as? String else {
            throw GoogleAuthError.invalidServiceAccountJSON("Missing private_key")
        }
        
        return ServiceAccountCredentials(clientEmail: clientEmail, privateKey: privateKey)
    }
    
    // MARK: - JWT Creation
    
    /// Creates the JWT header.
    public static func createJWTHeader() -> String {
        return #"{"alg":"RS256","typ":"JWT"}"#
    }
    
    /// Creates the JWT payload with required claims.
    public static func createJWTPayload(clientEmail: String, scope: String) -> String {
        let now = Int(Date().timeIntervalSince1970)
        let exp = now + 3600 // 1 hour
        
        return """
        {"iss":"\(clientEmail)","scope":"\(scope)","aud":"\(tokenEndpoint)","iat":\(now),"exp":\(exp)}
        """
    }
    
    // MARK: - Base64URL Encoding
    
    /// Encodes data as base64url (URL-safe base64 without padding).
    public static func base64URLEncode(_ data: Data) -> String {
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    // MARK: - RS256 Signing
    
    /// Signs data with RS256 using openssl subprocess.
    /// Works on both macOS and Linux. Future: migrate to OpenSSL Swift package.
    public static func signRS256(data: Data, privateKeyPEM: String) async throws -> Data {
        // Write private key to temp file
        let tempDir = FileManager.default.temporaryDirectory
        let keyFile = tempDir.appendingPathComponent("gauth-key-\(UUID().uuidString).pem")
        
        defer {
            try? FileManager.default.removeItem(at: keyFile)
        }
        
        try privateKeyPEM.write(to: keyFile, atomically: true, encoding: .utf8)
        
        // Sign using openssl dgst
        let result = try await Subprocess.run(
            .name("openssl"),
            arguments: .init(["dgst", "-sha256", "-sign", keyFile.path]),
            input: .data(data),
            output: .data(limit: 1024 * 1024)
        )
        
        guard result.terminationStatus.isSuccess else {
            throw GoogleAuthError.signingFailed("openssl signing failed")
        }
        
        return result.standardOutput
    }
    
    // MARK: - JWT Assembly
    
    /// Creates a signed JWT for Google OAuth.
    public static func createSignedJWT(credentials: ServiceAccountCredentials, scope: String) async throws -> String {
        let header = createJWTHeader()
        let payload = createJWTPayload(clientEmail: credentials.clientEmail, scope: scope)
        
        let headerB64 = base64URLEncode(Data(header.utf8))
        let payloadB64 = base64URLEncode(Data(payload.utf8))
        
        let signatureInput = "\(headerB64).\(payloadB64)"
        
        let signature = try await signRS256(data: Data(signatureInput.utf8), privateKeyPEM: credentials.privateKey)
        let signatureB64 = base64URLEncode(signature)
        
        return "\(headerB64).\(payloadB64).\(signatureB64)"
    }
    
    // MARK: - Token Exchange
    
    /// Exchanges a signed JWT for an OAuth access token.
    public static func exchangeJWTForToken(jwt: String) async throws -> String {
        guard let url = URL(string: tokenEndpoint) else {
            throw GoogleAuthError.tokenExchangeFailed("Invalid token endpoint URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=\(jwt)"
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleAuthError.tokenExchangeFailed("Invalid response")
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GoogleAuthError.tokenExchangeFailed("HTTP \(httpResponse.statusCode): \(errorBody)")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String else {
            throw GoogleAuthError.tokenExchangeFailed("Missing access_token in response")
        }
        
        return accessToken
    }
    
    // MARK: - Full Authentication Flow
    
    /// Authenticates and returns an access token for the specified scope.
    public static func authenticate(
        credentials: ServiceAccountCredentials,
        scope: String = webmastersScope
    ) async throws -> String {
        let jwt = try await createSignedJWT(credentials: credentials, scope: scope)
        return try await exchangeJWTForToken(jwt: jwt)
    }
}
