//
//  SchemaTests.swift
//  DesignSystemTests
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Testing
import Foundation
@testable import DesignSystem
import SchemaLib
import Slipstream

@Suite("Schema DesignSystem Bridging Tests")
struct SchemaTests {
    
    // MARK: - FAQPageSchema + FAQItem Bridging
    
    @Test("FAQPageSchema filters by includeInJSONLD")
    func testFAQPageSchemaFiltering() throws {
        let items = [
            FAQItem(question: "Included?", includeInJSONLD: true) { Text("Yes.") },
            FAQItem(question: "Excluded?") { Text("No.") }
        ]
        
        let schema = FAQPageSchema(items: items)
        let graph = SchemaGraph(schema)
        let json = try graph.render()
        
        #expect(json.contains("Included?"))
        #expect(!json.contains("Excluded?"))
    }
}
