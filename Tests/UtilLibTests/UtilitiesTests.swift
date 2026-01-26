//
//  UtilitiesTests.swift
//  UtilitiesTests
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Testing
@testable import UtilLib

@Suite("Utilities Library Tests")
struct UtilitiesTests {
    @Test("Library version is set")
    func libraryVersion() {
        #expect(Utilities.version == "0.1.0")
    }
}
