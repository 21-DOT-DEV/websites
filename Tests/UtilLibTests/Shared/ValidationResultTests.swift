//
//  ValidationResultTests.swift
//  UtilitiesTests
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Testing
@testable import UtilLib

@Suite("ValidationError Tests")
struct ValidationErrorTests {
    
    @Test("ValidationError stores code and message")
    func basicError() {
        let error = ValidationError(code: "INVALID_URL", message: "URL is malformed")
        
        #expect(error.code == "INVALID_URL")
        #expect(error.message == "URL is malformed")
        #expect(error.location == nil)
    }
    
    @Test("ValidationError stores optional location")
    func errorWithLocation() {
        let error = ValidationError(
            code: "MISSING_HEADER",
            message: "X-Frame-Options required",
            location: "line 15"
        )
        
        #expect(error.code == "MISSING_HEADER")
        #expect(error.message == "X-Frame-Options required")
        #expect(error.location == "line 15")
    }
    
    @Test("ValidationError description formats correctly without location")
    func descriptionWithoutLocation() {
        let error = ValidationError(code: "INVALID_URL", message: "URL is malformed")
        
        #expect(error.description == "[INVALID_URL] URL is malformed")
    }
    
    @Test("ValidationError description formats correctly with location")
    func descriptionWithLocation() {
        let error = ValidationError(
            code: "MISSING_HEADER",
            message: "X-Frame-Options required",
            location: "line 15"
        )
        
        #expect(error.description == "[MISSING_HEADER] X-Frame-Options required at line 15")
    }
}

@Suite("ValidationResult Tests")
struct ValidationResultTests {
    
    @Test("ValidationResult.success creates valid result")
    func successResult() {
        let result = ValidationResult.success()
        
        #expect(result.isValid == true)
        #expect(result.errors.isEmpty)
        #expect(result.warnings.isEmpty)
    }
    
    @Test("ValidationResult.success with warnings")
    func successWithWarnings() {
        let result = ValidationResult.success(warnings: ["Consider adding priority"])
        
        #expect(result.isValid == true)
        #expect(result.errors.isEmpty)
        #expect(result.warnings.count == 1)
        #expect(result.warnings.first == "Consider adding priority")
    }
    
    @Test("ValidationResult.failure creates invalid result")
    func failureResult() {
        let errors = [
            ValidationError(code: "INVALID_URL", message: "Bad URL"),
            ValidationError(code: "MISSING_FIELD", message: "Required field missing")
        ]
        let result = ValidationResult.failure(errors)
        
        #expect(result.isValid == false)
        #expect(result.errors.count == 2)
        #expect(result.warnings.isEmpty)
    }
    
    @Test("ValidationResult can be created with all fields")
    func fullInitializer() {
        let errors = [ValidationError(code: "E1", message: "Error 1")]
        let warnings = ["Warning 1", "Warning 2"]
        
        let result = ValidationResult(isValid: false, errors: errors, warnings: warnings)
        
        #expect(result.isValid == false)
        #expect(result.errors.count == 1)
        #expect(result.warnings.count == 2)
    }
}
