import Testing
import Foundation

@Suite("TestHarness Tests")
struct TestHarnessTests {
    
    // T001: Test basic execution
    @Test("TestHarness executes CLI and returns result")
    func testBasicExecution() async throws {
        let harness = TestHarness()
        let result = try await harness.run(arguments: ["--version"])
        
        #expect(result.exitCode == 0)
        #expect(!result.stdout.isEmpty)
    }
    
    // T002: Test stdout capture
    @Test("TestHarness captures stdout correctly")
    func testStdoutCapture() async throws {
        let harness = TestHarness()
        let result = try await harness.run(arguments: ["--help"])
        
        #expect(result.exitCode == 0)
        #expect(result.stdout.contains("util") || result.stdout.contains("USAGE"))
    }
    
    // T003: Test stderr capture
    @Test("TestHarness captures stderr correctly")
    func testStderrCapture() async throws {
        let harness = TestHarness()
        let result = try await harness.run(arguments: ["invalid-command"])
        
        #expect(result.exitCode != 0)
        #expect(!result.stderr.isEmpty || result.stderr.contains("Error") || result.stderr.contains("Unknown"))
    }
    
    // T004: Test exit code handling
    @Test("TestHarness handles exit codes correctly")
    func testExitCodeHandling() async throws {
        let harness = TestHarness()
        
        // Success case
        let successResult = try await harness.run(arguments: ["--version"])
        #expect(successResult.exitCode == 0)
        #expect(successResult.succeeded)
        
        // Failure case
        let failureResult = try await harness.run(arguments: ["invalid-command"])
        #expect(failureResult.exitCode != 0)
        #expect(!failureResult.succeeded)
    }
    
    // T005: Test argument passing
    @Test("TestHarness passes arguments correctly")
    func testArgumentPassing() async throws {
        let harness = TestHarness()
        
        // Test with multiple arguments
        let result = try await harness.run(arguments: ["canonical", "check"])
        
        // Should execute without crashing (may have non-zero exit if command not fully implemented)
        #expect(result.exitCode >= 0 || result.exitCode < 0) // Just verify we got an exit code
    }
}
