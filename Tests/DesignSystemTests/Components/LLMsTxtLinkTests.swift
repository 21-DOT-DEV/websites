//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Testing
import Foundation
@testable import DesignSystem
import Slipstream
import TestUtils

struct LLMsTxtLinkTests {
    
    @Test("LLMsTxtLink renders link element with correct rel and href")
    func testLLMsTxtLinkRendersCorrectly() throws {
        let view = LLMsTxtLink(URL(string: "https://21.dev/llms.txt"))
        let html = try TestUtils.renderHTML(view)
        
        #expect(html.contains("<link"))
        #expect(html.contains("rel=\"llms-txt\""))
        #expect(html.contains("href=\"https://21.dev/llms.txt\""))
    }
    
    @Test("LLMsTxtLink renders nothing when URL is nil")
    func testLLMsTxtLinkNilURL() throws {
        let view = LLMsTxtLink(nil)
        let html = try TestUtils.renderHTML(view)
        
        #expect(!html.contains("llms-txt"))
        #expect(!html.contains("<link"))
    }
}
