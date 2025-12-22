import Testing
import Foundation
@testable import DesignSystem
import Slipstream
import TestUtils

struct TabsTests {
    
    @Test("Tabs renders with correct HTML structure")
    func testTabsBasicStructure() throws {
        let tabs = Tabs(id: "test", tabs: [
            TabItem(title: "Tab 1") {
                Text("Content 1")
            },
            TabItem(title: "Tab 2") {
                Text("Content 2")
            }
        ])
        
        let html = try TestUtils.renderHTML(tabs)
        
        // Verify basic structure
        #expect(html.contains("<div"))
        #expect(html.contains("Tab 1"))
        #expect(html.contains("Tab 2"))
        #expect(html.contains("Content 1"))
        #expect(html.contains("Content 2"))
        #expect(html.contains("</div>"))
    }
    
    @Test("Tabs generates radio inputs with correct names and IDs")
    func testTabsRadioInputs() throws {
        let tabs = Tabs(id: "install", tabs: [
            TabItem(title: "Swift PM") {
                Text("Swift Package Manager code")
            },
            TabItem(title: "CocoaPods") {
                Text("CocoaPods code")
            }
        ])
        
        let html = try TestUtils.renderHTML(tabs)
        
        // Verify radio inputs
        #expect(html.contains("type=\"radio\""))
        #expect(html.contains("name=\"install-tabs\""))
        #expect(html.contains("id=\"install-tab-0\""))
        #expect(html.contains("id=\"install-tab-1\""))
        #expect(html.contains("sr-only")) // Hidden radio inputs
    }
    
    @Test("Tabs first tab is checked by default")
    func testTabsFirstTabChecked() throws {
        let tabs = Tabs(id: "test", tabs: [
            TabItem(title: "Default") {
                Text("Default content")
            },
            TabItem(title: "Second") {
                Text("Second content")
            }
        ])
        
        let html = try TestUtils.renderHTML(tabs)
        
        // First tab should be checked
        #expect(html.contains("checked"))
        // Should only have one checked attribute
        let checkedCount = html.components(separatedBy: "checked").count - 1
        #expect(checkedCount == 1)
    }
    
    @Test("Tabs generates labels with correct for attributes")
    func testTabsLabels() throws {
        let tabs = Tabs(id: "code", tabs: [
            TabItem(title: "JavaScript") {
                Code("console.log('hello')")
            },
            TabItem(title: "Python") {
                Code("print('hello')")
            }
        ])
        
        let html = try TestUtils.renderHTML(tabs)
        
        // Verify labels
        #expect(html.contains("<label"))
        #expect(html.contains("for=\"code-tab-0\""))
        #expect(html.contains("for=\"code-tab-1\""))
        #expect(html.contains("JavaScript"))
        #expect(html.contains("Python"))
    }
    
    @Test("Tabs renders tab content with correct IDs")
    func testTabsContentIds() throws {
        let tabs = Tabs(id: "example", tabs: [
            TabItem(title: "One") {
                Paragraph("First paragraph")
            },
            TabItem(title: "Two") {
                Paragraph("Second paragraph")
            }
        ])
        
        let html = try TestUtils.renderHTML(tabs)
        
        // Verify content container IDs
        #expect(html.contains("id=\"example-content-0\""))
        #expect(html.contains("id=\"example-content-1\""))
        #expect(html.contains("First paragraph"))
        #expect(html.contains("Second paragraph"))
    }
    
    @Test("Tabs CSS generation includes correct selectors")
    func testTabsCSSGeneration() throws {
        let tabs = Tabs(id: "install", tabs: [
            TabItem(title: "Swift PM") { Text("Content 1") },
            TabItem(title: "CocoaPods") { Text("Content 2") }
        ])
        
        let css = tabs.style
        
        // Verify CSS contains tab-specific selectors
        #expect(css.contains("install Tabs Component Styles"))
        #expect(css.contains(".tab-content"))
        #expect(css.contains("#install-tab-0"))
        #expect(css.contains("#install-tab-1"))
        #expect(css.contains("#install-content-0"))
        #expect(css.contains("#install-content-1"))
        #expect(css.contains("display: block"))
        #expect(css.contains("display: none"))
        #expect(css.contains("border-bottom-color: #ea580c"))
    }
    
    @Test("Tabs CSS generation adapts to tab count")
    func testTabsCSSAdaptsToTabCount() throws {
        let twoTabs = Tabs(id: "two", tabs: [
            TabItem(title: "A") { Text("A") },
            TabItem(title: "B") { Text("B") }
        ])
        
        let threeTabs = Tabs(id: "three", tabs: [
            TabItem(title: "A") { Text("A") },
            TabItem(title: "B") { Text("B") },
            TabItem(title: "C") { Text("C") }
        ])
        
        let twoTabsCSS = twoTabs.style
        let threeTabsCSS = threeTabs.style
        
        // Two tabs CSS should not contain third tab selectors
        #expect(twoTabsCSS.contains("#two-tab-0"))
        #expect(twoTabsCSS.contains("#two-tab-1"))
        #expect(!twoTabsCSS.contains("#two-tab-2"))
        
        // Three tabs CSS should contain all three selectors
        #expect(threeTabsCSS.contains("#three-tab-0"))
        #expect(threeTabsCSS.contains("#three-tab-1"))
        #expect(threeTabsCSS.contains("#three-tab-2"))
    }
    
    @Test("Tabs static CSS generation works correctly")
    func testTabsStaticCSSGeneration() throws {
        let css = Tabs.generateCSS(id: "static-test", numberOfTabs: 3)
        
        #expect(css.contains("static-test Tabs Component Styles"))
        #expect(css.contains("#static-test-tab-0"))
        #expect(css.contains("#static-test-tab-1"))
        #expect(css.contains("#static-test-tab-2"))
        #expect(!css.contains("#static-test-tab-3"))
    }
    
    @Test("Tabs StyleModifier conformance")
    func testTabsStyleModifierConformance() throws {
        let tabs = Tabs(id: "css-test", tabs: [
            TabItem(title: "Test") { Text("Content") }
        ])
        
        // Should implement StyleModifier protocol
        #expect(tabs.componentName == "Tabs[css-test]")
        #expect(!tabs.style.isEmpty)
    }
    
    @Test("Tabs builder pattern with Tab function")
    func testTabsBuilderPattern() throws {
        let tabs = Tabs(id: "builder") {
            Tab("First") {
                Div {
                    Text("First content")
                }
            }
            Tab("Second") {
                Div {
                    Text("Second content")
                }
            }
        }
        
        let html = try TestUtils.renderHTML(tabs)
        
        #expect(html.contains("First"))
        #expect(html.contains("Second"))
        #expect(html.contains("First content"))
        #expect(html.contains("Second content"))
    }
    
    @Test("Tabs handles empty tabs array")
    func testTabsEmptyArray() throws {
        let tabs = Tabs(id: "empty", tabs: [])
        
        let html = try TestUtils.renderHTML(tabs)
        let css = tabs.style
        
        // Should render without errors
        #expect(html.contains("<div"))
        #expect(css.contains("empty Tabs Component Styles"))
    }
    
    @Test("Tabs handles single tab")
    func testTabsSingleTab() throws {
        let tabs = Tabs(id: "single", tabs: [
            TabItem(title: "Only Tab") {
                Text("Only content")
            }
        ])
        
        let html = try TestUtils.renderHTML(tabs)
        
        #expect(html.contains("Only Tab"))
        #expect(html.contains("Only content"))
        #expect(html.contains("checked")) // Single tab should be checked
        #expect(html.contains("id=\"single-tab-0\""))
    }
    
    @Test("Tabs handles complex content")
    func testTabsComplexContent() throws {
        let tabs = Tabs(id: "complex") {
            Tab("Code Example") {
                Div {
                    Code("let example = \"test\"")
                        .fontDesign(.monospaced)
                    Button(action: "copy()") {
                        Text("Copy")
                    }
                }
            }
            Tab("Documentation") {
                Div {
                    H3("Usage")
                    Paragraph("This is how you use it...")
                }
            }
        }
        
        let html = try TestUtils.renderHTML(tabs)
        
        #expect(html.contains("Code Example"))
        #expect(html.contains("Documentation"))
        #expect(html.contains("let example"))
        #expect(html.contains("Copy"))
        #expect(html.contains("Usage"))
        #expect(html.contains("This is how you use it"))
    }
    
    @Test("Tabs CSS contains all required styling rules")
    func testTabsCSSCompleteness() throws {
        let tabs = Tabs(id: "complete", tabs: [
            TabItem(title: "Test") { Text("Test") }
        ])
        
        let css = tabs.style
        
        // Verify essential CSS rules are present (allowing for whitespace differences)
        #expect(css.contains("complete Tabs Component Styles"))
        #expect(css.contains(".tab-content"))
        #expect(css.contains("display: none"))
        #expect(css.contains(":checked ~ div"))
        #expect(css.contains("display: block !important"))
        #expect(css.contains("color: #ea580c !important"))
        #expect(css.contains("border-bottom-color: #ea580c !important"))
    }
}
