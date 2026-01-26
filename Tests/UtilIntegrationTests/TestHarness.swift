//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Subprocess
import System

/// Test harness for executing the util CLI in integration tests
///
/// Provides utilities for:
/// - Running CLI commands with arguments
/// - Capturing stdout and stderr
/// - Checking exit codes
/// - Running commands in specific working directories
struct TestHarness {
    /// Path to the util executable
    let executablePath: FilePath
    
    /// Result of a CLI command execution
    struct CommandResult {
        let stdout: String
        let stderr: String
        let exitCode: Int
        
        var succeeded: Bool {
            exitCode == 0
        }
    }
    
    /// Initialize the test harness with default debug build path
    init() {
        let currentDirectory = FileManager.default.currentDirectoryPath
        self.executablePath = FilePath("\(currentDirectory)/.build/debug/util")
    }
    
    /// Initialize with custom executable path
    init(executablePath: String) {
        self.executablePath = FilePath(executablePath)
    }
    
    /// Run the CLI with the given arguments
    ///
    /// - Parameters:
    ///   - arguments: Command-line arguments to pass to util
    ///   - workingDirectory: Optional working directory for command
    /// - Returns: Command result with stdout, stderr, and exit code
    func run(arguments: [String], workingDirectory: FilePath? = nil) async throws -> CommandResult {
        let result = try await Subprocess.run(
            .path(executablePath),
            arguments: .init(arguments),
            workingDirectory: workingDirectory,
            output: .string(limit: 65536),
            error: .string(limit: 65536)
        )
        
        let exitCode: Int
        if case .exited(let code) = result.terminationStatus {
            exitCode = Int(code)
        } else {
            exitCode = -1
        }
        
        return CommandResult(
            stdout: result.standardOutput ?? "",
            stderr: result.standardError ?? "",
            exitCode: exitCode
        )
    }
}
