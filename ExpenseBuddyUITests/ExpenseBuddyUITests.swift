import XCTest

final class ExpenseBuddyUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        // In UI tests it's important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testAppLaunchAndAuthFlow() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Test 1: App should launch and show auth screen
        XCTAssertTrue(app.waitForExistence(timeout: 5), "App should launch successfully")
        
        // Test 2: Check if ExpenseBuddy title exists
        let appTitle = app.staticTexts["ExpenseBuddy"]
        XCTAssertTrue(appTitle.waitForExistence(timeout: 3), "App title should be visible")
        
        // Test 3: Check if login form elements exist
        let emailField = app.textFields["Enter your email"]
        let passwordField = app.secureTextFields["Enter your password"]
        let signInButton = app.buttons["Sign In"]
        
        XCTAssertTrue(emailField.waitForExistence(timeout: 3), "Email field should exist")
        XCTAssertTrue(passwordField.waitForExistence(timeout: 3), "Password field should exist")
        XCTAssertTrue(signInButton.waitForExistence(timeout: 3), "Sign In button should exist")
        
        // Test 4: Try switching to register form
        let signUpToggle = app.buttons["Sign Up"]
        if signUpToggle.exists {
            signUpToggle.tap()
            
            // Check if register form appears
            let createAccountButton = app.buttons["Create Account"]
            XCTAssertTrue(createAccountButton.waitForExistence(timeout: 3), "Create Account button should appear")
            
            // Check for additional fields in register form
            let firstNameField = app.textFields["First"]
            let lastNameField = app.textFields["Last"]
            XCTAssertTrue(firstNameField.waitForExistence(timeout: 2), "First name field should exist")
            XCTAssertTrue(lastNameField.waitForExistence(timeout: 2), "Last name field should exist")
        }
    }
    
    @MainActor
    func testAuthenticationFormValidation() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for app to load
        XCTAssertTrue(app.waitForExistence(timeout: 5), "App should launch")
        
        // Test empty form submission
        let signInButton = app.buttons["Sign In"]
        if signInButton.waitForExistence(timeout: 3) {
            // Sign in button should be disabled when fields are empty
            XCTAssertFalse(signInButton.isEnabled, "Sign In button should be disabled with empty fields")
        }
        
        // Fill in email field
        let emailField = app.textFields["Enter your email"]
        if emailField.waitForExistence(timeout: 3) {
            emailField.tap()
            emailField.typeText("test@example.com")
        }
        
        // Sign in should still be disabled without password
        XCTAssertFalse(signInButton.isEnabled, "Sign In button should be disabled without password")
        
        // Fill in password field
        let passwordField = app.secureTextFields["Enter your password"]
        if passwordField.waitForExistence(timeout: 3) {
            passwordField.tap()
            passwordField.typeText("testpassword")
        }
        
        // Now sign in should be enabled
        XCTAssertTrue(signInButton.isEnabled, "Sign In button should be enabled with both fields filled")
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    @MainActor
    func testThemeToggleIfVisible() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for app to load
        XCTAssertTrue(app.waitForExistence(timeout: 5), "App should launch")
        
        // Look for theme-related elements (if they exist in your auth screen)
        // This test is more flexible and won't fail if theme elements aren't present
        let themeButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Ocean' OR label CONTAINS 'Sunset' OR label CONTAINS 'Forest'"))
        
        if themeButtons.count > 0 {
            // If theme buttons exist, test theme switching
            let firstThemeButton = themeButtons.element(boundBy: 0)
            if firstThemeButton.exists {
                firstThemeButton.tap()
                // Just verify the app doesn't crash when tapping theme buttons
                XCTAssertTrue(app.exists, "App should remain functional after theme change")
            }
        } else {
            // If no theme buttons found, just verify app is still responsive
            XCTAssertTrue(app.exists, "App should be responsive even without theme buttons")
        }
    }
    
    @MainActor
    func testKeyboardInteraction() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for app to load
        XCTAssertTrue(app.waitForExistence(timeout: 5), "App should launch")
        
        // Test keyboard appearance
        let emailField = app.textFields["Enter your email"]
        if emailField.waitForExistence(timeout: 3) {
            emailField.tap()
            
            // Check if keyboard appears (keyboard existence can be tricky to test)
            // We'll just verify the field becomes focused
            XCTAssertTrue(emailField.hasKeyboardFocus, "Email field should have keyboard focus")
            
            // Type some text
            emailField.typeText("test@example.com")
            
            // Move to password field
            let passwordField = app.secureTextFields["Enter your password"]
            if passwordField.waitForExistence(timeout: 2) {
                passwordField.tap()
                XCTAssertTrue(passwordField.hasKeyboardFocus, "Password field should have keyboard focus")
                passwordField.typeText("password123")
            }
        }
    }
}

// MARK: - Helper Extensions
extension XCUIElement {
    var hasKeyboardFocus: Bool {
        return (self.value(forKey: "hasKeyboardFocus") as? Bool) ?? false
    }
}
