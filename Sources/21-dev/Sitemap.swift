//
//  Sitemap.swift
//  21-DOT-DEV/Sitemap.swift
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

@main
struct SiteGenerator {
    static func main() throws {
        let sitemap: Sitemap = [
            "index.html": Homepage.page
        ]
        
        // Assumes this file is located in a Sources/ sub-directory of a Swift package.
        let projectURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        
        let outputURL = projectURL.appending(path: "../Websites/21-dev")
        
        try renderSitemap(sitemap, to: outputURL)
    }
}
