import Testing
import Foundation

@testable import DesignSystem

@Suite("Git LastMod Integration Tests")
struct GitLastModTests {
    
    @Test("getGitLastModDate returns ISO8601 date for committed file")
    func testGitLastModDateForCommittedFile() async throws {
        // Get a known committed file from the repository
        let testFilePath = "Sources/21-dev/SiteGenerator.swift"
        
        // Call the function
        let lastModDate = try await getGitLastModDate(filePath: testFilePath)
        
        // Verify it's a valid ISO8601 date string
        #expect(lastModDate.contains("T"))
        #expect(lastModDate.contains("-"))
        #expect(lastModDate.count >= 19) // Minimum: YYYY-MM-DDTHH:MM:SS
        
        // Verify it can be parsed as a date
        let formatter = ISO8601DateFormatter()
        let parsedDate = formatter.date(from: lastModDate)
        #expect(parsedDate != nil)
    }
    
    @Test("getGitLastModDate returns current timestamp for uncommitted file")
    func testGitLastModDateForUncommittedFile() async throws {
        // Create a temporary uncommitted file
        let tempFileName = "temp-test-file-\(UUID().uuidString).txt"
        let tempFilePath = tempFileName
        let fileURL = URL(fileURLWithPath: tempFilePath)
        
        // Write temporary file
        try "test content".write(to: fileURL, atomically: true, encoding: .utf8)
        
        defer {
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        // Call the function - should fallback to current timestamp
        let lastModDate = try await getGitLastModDate(filePath: tempFilePath)
        
        // Verify it's today's date
        let formatter = ISO8601DateFormatter()
        let parsedDate = formatter.date(from: lastModDate)
        #expect(parsedDate != nil)
        
        let calendar = Calendar.current
        let today = Date()
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: parsedDate!)
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: today)
        
        #expect(dateComponents.year == todayComponents.year)
        #expect(dateComponents.month == todayComponents.month)
        #expect(dateComponents.day == todayComponents.day)
    }
    
    @Test("getGitLastModDate returns current timestamp for non-existent file")
    func testGitLastModDateForNonExistentFile() async throws {
        // Use a file path that doesn't exist
        let nonExistentPath = "does-not-exist-\(UUID().uuidString).swift"
        
        // Call the function - should fallback to current timestamp
        let lastModDate = try await getGitLastModDate(filePath: nonExistentPath)
        
        // Verify it's today's date (fallback behavior)
        let formatter = ISO8601DateFormatter()
        let parsedDate = formatter.date(from: lastModDate)
        #expect(parsedDate != nil)
        
        let calendar = Calendar.current
        let today = Date()
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: parsedDate!)
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: today)
        
        #expect(dateComponents.year == todayComponents.year)
        #expect(dateComponents.month == todayComponents.month)
        #expect(dateComponents.day == todayComponents.day)
    }
    
    @Test("getGitLastModDate formats date correctly")
    func testGitLastModDateFormat() async throws {
        // Test with a known file
        let testFilePath = "Package.swift"
        
        let lastModDate = try await getGitLastModDate(filePath: testFilePath)
        
        // Verify ISO8601 format with timezone
        // Format should be: YYYY-MM-DDTHH:MM:SS+HH:MM or YYYY-MM-DDTHH:MM:SSZ
        let iso8601Pattern = #"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}$|^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$"#
        
        let regex = try! NSRegularExpression(pattern: iso8601Pattern)
        let range = NSRange(lastModDate.startIndex..., in: lastModDate)
        let matches = regex.numberOfMatches(in: lastModDate, range: range)
        
        #expect(matches == 1, "Date should match ISO8601 format with timezone")
    }
}
