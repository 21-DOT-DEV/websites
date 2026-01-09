//
//  CopyIconTests.swift
//  DesignSystemTests
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Testing
import Foundation
@testable import DesignSystem
import Slipstream
import TestUtils

@Suite("CopyIcon Tests")
struct CopyIconTests {
    
    @Test("CopyIcon renders SVG element")
    func testCopyIconRendersSVG() throws {
        let icon = CopyIcon()
        let html = try TestUtils.renderHTML(icon)
        
        #expect(html.contains("<svg"))
        #expect(html.contains("</svg>"))
    }
    
    @Test("CopyIcon has correct viewBox")
    func testCopyIconViewBox() throws {
        let icon = CopyIcon()
        let html = try TestUtils.renderHTML(icon)
        
        #expect(html.contains("viewBox=\"0 0 24 24\""))
    }
    
    @Test("CopyIcon renders rect element for clipboard")
    func testCopyIconRendersRect() throws {
        let icon = CopyIcon()
        let html = try TestUtils.renderHTML(icon)
        
        #expect(html.contains("<rect"))
        #expect(html.contains("width=\"14\""))
        #expect(html.contains("height=\"14\""))
    }
    
    @Test("CopyIcon renders path element")
    func testCopyIconRendersPath() throws {
        let icon = CopyIcon()
        let html = try TestUtils.renderHTML(icon)
        
        #expect(html.contains("<path"))
        #expect(html.contains("M4 16c-1.1 0-2-.9-2-2V4"))
    }
    
    @Test("CopyIcon has stroke styling attributes")
    func testCopyIconStrokeStyling() throws {
        let icon = CopyIcon()
        let html = try TestUtils.renderHTML(icon)
        
        #expect(html.contains("stroke=\"currentColor\""))
        #expect(html.contains("stroke-width=\"2\""))
        #expect(html.contains("stroke-linecap=\"round\""))
        #expect(html.contains("stroke-linejoin=\"round\""))
    }
    
    @Test("CopyIcon has fill none attribute")
    func testCopyIconFillNone() throws {
        let icon = CopyIcon()
        let html = try TestUtils.renderHTML(icon)
        
        #expect(html.contains("fill=\"none\""))
    }
    
    @Test("CopyIcon has size class")
    func testCopyIconSizeClass() throws {
        let icon = CopyIcon()
        let html = try TestUtils.renderHTML(icon)
        
        #expect(html.contains("h-4"))
        #expect(html.contains("w-4"))
    }
}
