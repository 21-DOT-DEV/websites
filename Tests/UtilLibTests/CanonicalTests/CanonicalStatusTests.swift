//
//  CanonicalStatusTests.swift
//  UtilitiesTests
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Testing
@testable import UtilLib

@Suite("CanonicalStatus Tests")
struct CanonicalStatusTests {
    
    @Test("All status cases exist")
    func allCasesExist() {
        let valid = CanonicalStatus.valid
        let mismatch = CanonicalStatus.mismatch
        let missing = CanonicalStatus.missing
        let error = CanonicalStatus.error
        
        #expect(valid == .valid)
        #expect(mismatch == .mismatch)
        #expect(missing == .missing)
        #expect(error == .error)
    }
    
    @Test("Raw values are correct strings")
    func rawValuesAreStrings() {
        #expect(CanonicalStatus.valid.rawValue == "valid")
        #expect(CanonicalStatus.mismatch.rawValue == "mismatch")
        #expect(CanonicalStatus.missing.rawValue == "missing")
        #expect(CanonicalStatus.error.rawValue == "error")
    }
    
    @Test("Status is Sendable")
    func isSendable() {
        let status: any Sendable = CanonicalStatus.valid
        #expect(status as? CanonicalStatus == .valid)
    }
    
    @Test("Status can be created from raw value")
    func initFromRawValue() {
        #expect(CanonicalStatus(rawValue: "valid") == .valid)
        #expect(CanonicalStatus(rawValue: "mismatch") == .mismatch)
        #expect(CanonicalStatus(rawValue: "missing") == .missing)
        #expect(CanonicalStatus(rawValue: "error") == .error)
        #expect(CanonicalStatus(rawValue: "invalid") == nil)
    }
}
