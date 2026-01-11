//
//  GoogleAuthServiceTests.swift
//  UtilLibTests
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Testing
@testable import UtilLib

// MARK: - GoogleAuthError Tests

@Suite("GoogleAuthError Tests")
struct GoogleAuthErrorTests {
    
    @Test("GoogleAuthError.invalidServiceAccountJSON has descriptive message")
    func invalidServiceAccountJSONMessage() {
        let error = GoogleAuthError.invalidServiceAccountJSON("Missing client_email")
        let description = error.errorDescription ?? ""
        
        #expect(description.contains("service account"))
        #expect(description.contains("Missing client_email"))
    }
    
    @Test("GoogleAuthError.signingFailed has descriptive message")
    func signingFailedMessage() {
        let error = GoogleAuthError.signingFailed("RSA error")
        let description = error.errorDescription ?? ""
        
        #expect(description.contains("sign"))
        #expect(description.contains("RSA error"))
    }
    
    @Test("GoogleAuthError.tokenExchangeFailed has descriptive message")
    func tokenExchangeFailedMessage() {
        let error = GoogleAuthError.tokenExchangeFailed("Invalid grant")
        let description = error.errorDescription ?? ""
        
        #expect(description.contains("token"))
        #expect(description.contains("Invalid grant"))
    }
    
    @Test("GoogleAuthError is Equatable")
    func equatable() {
        #expect(GoogleAuthError.noCredentialsProvided == GoogleAuthError.noCredentialsProvided)
        #expect(GoogleAuthError.signingFailed("A") == GoogleAuthError.signingFailed("A"))
        #expect(GoogleAuthError.signingFailed("A") != GoogleAuthError.signingFailed("B"))
    }
}

// MARK: - ServiceAccountCredentials Tests

@Suite("ServiceAccountCredentials Tests")
struct ServiceAccountCredentialsTests {
    
    // Valid test service account JSON (not a real key)
    static let validJSON = """
    {
        "type": "service_account",
        "project_id": "test-project",
        "private_key_id": "key123",
        "private_key": "-----BEGIN PRIVATE KEY-----\\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC7...\\n-----END PRIVATE KEY-----\\n",
        "client_email": "test@test-project.iam.gserviceaccount.com",
        "client_id": "123456789",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token"
    }
    """
    
    @Test("parseServiceAccountJSON extracts client_email")
    func extractsClientEmail() throws {
        let credentials = try GoogleAuthService.parseServiceAccountJSON(Self.validJSON)
        
        #expect(credentials.clientEmail == "test@test-project.iam.gserviceaccount.com")
    }
    
    @Test("parseServiceAccountJSON extracts private_key")
    func extractsPrivateKey() throws {
        let credentials = try GoogleAuthService.parseServiceAccountJSON(Self.validJSON)
        
        #expect(credentials.privateKey.contains("BEGIN PRIVATE KEY"))
        #expect(credentials.privateKey.contains("END PRIVATE KEY"))
    }
    
    @Test("parseServiceAccountJSON throws for missing client_email")
    func throwsForMissingClientEmail() {
        let json = """
        {
            "type": "service_account",
            "private_key": "-----BEGIN PRIVATE KEY-----\\ntest\\n-----END PRIVATE KEY-----\\n"
        }
        """
        
        #expect(throws: GoogleAuthError.self) {
            _ = try GoogleAuthService.parseServiceAccountJSON(json)
        }
    }
    
    @Test("parseServiceAccountJSON throws for missing private_key")
    func throwsForMissingPrivateKey() {
        let json = """
        {
            "type": "service_account",
            "client_email": "test@test.iam.gserviceaccount.com"
        }
        """
        
        #expect(throws: GoogleAuthError.self) {
            _ = try GoogleAuthService.parseServiceAccountJSON(json)
        }
    }
    
    @Test("parseServiceAccountJSON throws for invalid JSON")
    func throwsForInvalidJSON() {
        let json = "not valid json"
        
        #expect(throws: GoogleAuthError.self) {
            _ = try GoogleAuthService.parseServiceAccountJSON(json)
        }
    }
}

// MARK: - JWT Creation Tests

@Suite("GoogleAuthService JWT Tests")
struct JWTCreationTests {
    
    @Test("createJWTHeader returns correct structure")
    func jwtHeaderStructure() throws {
        let header = GoogleAuthService.createJWTHeader()
        let data = try JSONSerialization.jsonObject(with: header.data(using: .utf8)!) as! [String: String]
        
        #expect(data["alg"] == "RS256")
        #expect(data["typ"] == "JWT")
    }
    
    @Test("createJWTPayload includes required claims")
    func jwtPayloadClaims() throws {
        let payload = GoogleAuthService.createJWTPayload(
            clientEmail: "test@test.iam.gserviceaccount.com",
            scope: "https://www.googleapis.com/auth/webmasters"
        )
        
        let data = try JSONSerialization.jsonObject(with: payload.data(using: .utf8)!) as! [String: Any]
        
        #expect(data["iss"] as? String == "test@test.iam.gserviceaccount.com")
        #expect(data["scope"] as? String == "https://www.googleapis.com/auth/webmasters")
        #expect(data["aud"] as? String == "https://oauth2.googleapis.com/token")
        #expect(data["iat"] != nil)
        #expect(data["exp"] != nil)
    }
    
    @Test("createJWTPayload exp is 1 hour after iat")
    func jwtPayloadExpiration() throws {
        let payload = GoogleAuthService.createJWTPayload(
            clientEmail: "test@test.iam.gserviceaccount.com",
            scope: "https://www.googleapis.com/auth/webmasters"
        )
        
        let data = try JSONSerialization.jsonObject(with: payload.data(using: .utf8)!) as! [String: Any]
        let iat = data["iat"] as! Int
        let exp = data["exp"] as! Int
        
        #expect(exp - iat == 3600)
    }
}

// MARK: - Base64URL Encoding Tests

@Suite("GoogleAuthService Base64URL Tests")
struct Base64URLTests {
    
    @Test("base64URLEncode removes padding")
    func removesPadding() {
        let data = "test".data(using: .utf8)!
        let encoded = GoogleAuthService.base64URLEncode(data)
        
        #expect(!encoded.contains("="))
    }
    
    @Test("base64URLEncode replaces + with -")
    func replacesPlus() {
        // Data that produces + in standard base64
        let data = Data([251, 239]) // produces ++
        let encoded = GoogleAuthService.base64URLEncode(data)
        
        #expect(!encoded.contains("+"))
    }
    
    @Test("base64URLEncode replaces / with _")
    func replacesSlash() {
        // Data that produces / in standard base64
        let data = Data([255, 255]) // produces //
        let encoded = GoogleAuthService.base64URLEncode(data)
        
        #expect(!encoded.contains("/"))
    }
    
    @Test("base64URLEncode produces URL-safe output")
    func urlSafeOutput() {
        let data = "Hello, World!".data(using: .utf8)!
        let encoded = GoogleAuthService.base64URLEncode(data)
        
        // Should only contain URL-safe characters
        let urlSafeCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_")
        #expect(encoded.unicodeScalars.allSatisfy { urlSafeCharacters.contains($0) })
    }
}

// MARK: - Credential Resolution Tests

@Suite("GoogleAuthService Credential Resolution Tests")
struct CredentialResolutionTests {
    
    @Test("resolveCredentials prefers file path over env vars")
    func prefersFilePath() async throws {
        // Create temp file with test credentials
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("test-sa-\(UUID().uuidString).json")
        
        let json = """
        {
            "type": "service_account",
            "client_email": "file@test.iam.gserviceaccount.com",
            "private_key": "-----BEGIN PRIVATE KEY-----\\ntest\\n-----END PRIVATE KEY-----\\n"
        }
        """
        try json.write(to: tempFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempFile) }
        
        let credentials = try GoogleAuthService.resolveCredentials(
            filePath: tempFile.path,
            jsonString: nil
        )
        
        #expect(credentials.clientEmail == "file@test.iam.gserviceaccount.com")
    }
    
    @Test("resolveCredentials uses JSON string when no file path")
    func usesJSONString() throws {
        let json = """
        {
            "type": "service_account",
            "client_email": "json@test.iam.gserviceaccount.com",
            "private_key": "-----BEGIN PRIVATE KEY-----\\ntest\\n-----END PRIVATE KEY-----\\n"
        }
        """
        
        let credentials = try GoogleAuthService.resolveCredentials(
            filePath: nil,
            jsonString: json
        )
        
        #expect(credentials.clientEmail == "json@test.iam.gserviceaccount.com")
    }
    
    @Test("resolveCredentials throws when no credentials provided")
    func throwsWhenNoCredentials() {
        #expect(throws: GoogleAuthError.self) {
            _ = try GoogleAuthService.resolveCredentials(filePath: nil, jsonString: nil)
        }
    }
    
    @Test("resolveCredentials throws for non-existent file")
    func throwsForNonExistentFile() {
        #expect(throws: GoogleAuthError.self) {
            _ = try GoogleAuthService.resolveCredentials(
                filePath: "/nonexistent/path/to/file.json",
                jsonString: nil
            )
        }
    }
}
