//
//  UtilitiesTests.swift
//  UtilitiesTests
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Testing
@testable import Utilities

@Suite("Utilities Library Tests")
struct UtilitiesTests {
    @Test("Library version is set")
    func libraryVersion() {
        #expect(Utilities.version == "0.1.0")
    }
}
