//
//  main.swift
//  util
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import ArgumentParser
import UtilLib

/// CLI utilities for 21.dev websites.
///
/// Provides commands for sitemap generation, headers validation,
/// and state file management.
@main
struct Util: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "util",
        abstract: "CLI utilities for 21.dev websites",
        version: Utilities.version,
        subcommands: [
            SitemapCommand.self,
            HeadersCommand.self,
            StateCommand.self,
            CanonicalCommand.self,
            CommentCommand.self,
            SearchConsoleCommand.self,
        ]
    )
}
