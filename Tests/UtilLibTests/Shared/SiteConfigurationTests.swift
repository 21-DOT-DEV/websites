//
//  SiteConfigurationTests.swift
//  UtilitiesTests
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Testing
@testable import UtilLib

@Suite("SiteName Enum Tests")
struct SiteNameTests {
    
    // MARK: - Raw Value Tests
    
    @Test("SiteName raw values match expected site identifiers")
    func rawValues() {
        #expect(SiteName.dev21.rawValue == "21-dev")
        #expect(SiteName.docs21dev.rawValue == "docs-21-dev")
    }
    
    @Test("SiteName can be initialized from raw value")
    func initFromRawValue() {
        #expect(SiteName(rawValue: "21-dev") == .dev21)
        #expect(SiteName(rawValue: "docs-21-dev") == .docs21dev)
        #expect(SiteName(rawValue: "invalid") == nil)
    }
    
    // MARK: - Base URL Tests
    
    @Test("SiteName baseURL returns correct URLs")
    func baseURLs() {
        #expect(SiteName.dev21.baseURL == "https://21.dev")
        #expect(SiteName.docs21dev.baseURL == "https://docs.21.dev")
    }
    
    // MARK: - Output Directory Tests
    
    @Test("SiteName outputDirectory returns correct paths")
    func outputDirectories() {
        #expect(SiteName.dev21.outputDirectory == "Websites/21-dev")
        #expect(SiteName.docs21dev.outputDirectory == "Websites/docs-21-dev")
    }
    
    // MARK: - CaseIterable Tests
    
    @Test("SiteName allCases contains all sites")
    func allCases() {
        #expect(SiteName.allCases.count == 2)
        #expect(SiteName.allCases.contains(.dev21))
        #expect(SiteName.allCases.contains(.docs21dev))
    }
}

@Suite("URLDiscoveryStrategy Tests")
struct URLDiscoveryStrategyTests {
    
    @Test("htmlFiles strategy stores directory path")
    func htmlFilesStrategy() {
        let strategy = URLDiscoveryStrategy.htmlFiles(directory: "Websites/21-dev")
        if case .htmlFiles(let dir) = strategy {
            #expect(dir == "Websites/21-dev")
        } else {
            Issue.record("Expected htmlFiles strategy")
        }
    }
    
    @Test("markdownFiles strategy stores directory path")
    func markdownFilesStrategy() {
        let strategy = URLDiscoveryStrategy.markdownFiles(directory: "Websites/example")
        if case .markdownFiles(let dir) = strategy {
            #expect(dir == "Websites/example")
        } else {
            Issue.record("Expected markdownFiles strategy")
        }
    }
    
    @Test("sitemapDictionary strategy exists")
    func sitemapDictionaryStrategy() {
        let strategy = URLDiscoveryStrategy.sitemapDictionary
        if case .sitemapDictionary = strategy {
            // Pass
        } else {
            Issue.record("Expected sitemapDictionary strategy")
        }
    }
}

@Suite("SiteConfiguration Tests")
struct SiteConfigurationTests {
    
    @Test("SiteConfiguration.for returns correct config for dev21")
    func configForDev21() {
        let config = SiteConfiguration.for(.dev21)
        
        #expect(config.name == .dev21)
        #expect(config.baseURL == "https://21.dev")
        #expect(config.outputDirectory == "Websites/21-dev")
        
        if case .htmlFiles = config.urlDiscoveryStrategy {
            // Pass - 21.dev uses HTML files
        } else {
            Issue.record("Expected htmlFiles strategy for dev21")
        }
    }
    
    @Test("SiteConfiguration.for returns correct config for docs21dev")
    func configForDocs21dev() {
        let config = SiteConfiguration.for(.docs21dev)
        
        #expect(config.name == .docs21dev)
        #expect(config.baseURL == "https://docs.21.dev")
        #expect(config.outputDirectory == "Websites/docs-21-dev")
        
        if case .htmlFiles(let dir) = config.urlDiscoveryStrategy {
            #expect(dir == "Websites/docs-21-dev/documentation")
        } else {
            Issue.record("Expected htmlFiles strategy for docs21dev")
        }
    }
    
}
