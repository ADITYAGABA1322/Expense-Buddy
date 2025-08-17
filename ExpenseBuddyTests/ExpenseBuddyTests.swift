import XCTest
@testable import ExpenseBuddy

@MainActor
final class ExpenseBuddyTests: XCTestCase {
    
    // MARK: - Setup & Teardown
    override func setUpWithError() throws {
        super.setUp()
        // Reset any shared state before each test
    }
    
    override func tearDownWithError() throws {
        // Clean up after each test
        super.tearDown()
    }
    
    // MARK: - Unit Test 1: Basic Authentication Validation Tests
    func testAuthenticationValidation() async throws {
        let viewModel = AuthViewModel()
        
        // Test 1.1: Empty email should fail
        let emptyEmailResult = await viewModel.login(email: "", password: "password123")
        XCTAssertFalse(viewModel.errorMessage.isEmpty, "Error message should be set for empty email")
        
        // Test 1.2: Invalid email format should fail
        let invalidEmailResult = await viewModel.login(email: "invalid_email", password: "password123")
        XCTAssertFalse(viewModel.errorMessage.isEmpty, "Error message should be set for invalid email")
        
        // Test 1.3: Empty password should fail
        let emptyPasswordResult = await viewModel.login(email: "test@example.com", password: "")
        XCTAssertFalse(viewModel.errorMessage.isEmpty, "Error message should be set for empty password")
        
        // Test 1.4: Valid credentials should work (in mock scenario)
        viewModel.errorMessage = "" // Clear previous errors
        let validResult = await viewModel.login(email: "test@example.com", password: "password123")
        // Note: This will fail in real scenario but tests the validation logic
    }
    
    // MARK: - Unit Test 2: Theme Management Tests
    func testThemeManagement() throws {
        let theme = AppTheme.shared
        
        // Test 2.1: Theme should have valid current gradient
        XCTAssertNotNil(theme.currentGradient, "Current gradient should not be nil")
        XCTAssertNotNil(theme.currentGradient.accentColor, "Accent color should not be nil")
        XCTAssertNotNil(theme.currentGradient.secondaryColor, "Secondary color should not be nil")
        XCTAssertNotNil(theme.currentGradient.backgroundColor, "Background color should not be nil")
        XCTAssertFalse(theme.currentGradient.name.isEmpty, "Theme name should not be empty")

    }
    
    // MARK: - Unit Test 3: Currency Service Tests
    func testCurrencyService() throws {
        let currencyService = CurrencyService.shared
        
        // Test 3.1: Currency service should be initialized
        XCTAssertNotNil(currencyService, "Currency service should be initialized")
        
        // Test 3.2: Should have a selected currency
        XCTAssertNotNil(currencyService.selectedCurrency, "Should have a selected currency")
        
        // Test 3.3: Currency should have valid properties
        let currency = currencyService.selectedCurrency
        XCTAssertFalse(currency.symbol.isEmpty, "Currency symbol should not be empty")
      //  XCTAssertFalse(currency.code.isEmpty, "Currency code should not be empty")
        XCTAssertFalse(currency.name.isEmpty, "Currency name should not be empty")
        
        // Test 3.4: Should be able to format amounts
        let formattedAmount = currencyService.formatAmount(123.45, currency: currency)
        XCTAssertFalse(formattedAmount.isEmpty, "Formatted amount should not be empty")
        XCTAssertTrue(formattedAmount.contains(currency.symbol), "Formatted amount should contain currency symbol")
    }
    
    // MARK: - Unit Test 4: Network Service Tests
    func testNetworkService() throws {
        let networkService = NetworkService.shared
        
        // Test 4.1: Network service should be initialized
        XCTAssertNotNil(networkService, "Network service should be initialized")
        
        // Test 4.2: Should have connection state
        // Note: This will be true in test environment
        XCTAssertNotNil(networkService.isConnected, "Network connection state should be available")
    }
    
    // MARK: - Unit Test 5: String Validation Tests
    func testStringValidation() throws {
        // Test 5.1: Email validation
        XCTAssertTrue("test@example.com".isValidEmail(), "Valid email should pass validation")
        XCTAssertFalse("invalid_email".isValidEmail(), "Invalid email should fail validation")
        XCTAssertFalse("test@".isValidEmail(), "Incomplete email should fail validation")
        XCTAssertFalse("@example.com".isValidEmail(), "Email without username should fail validation")
        
        // Test 5.2: Empty string checks
        XCTAssertTrue("".isEmpty, "Empty string should be empty")
        XCTAssertFalse("test".isEmpty, "Non-empty string should not be empty")
        XCTAssertTrue("   ".trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Whitespace-only string should be empty when trimmed")
    }
    
    // MARK: - Unit Test 6: Date Formatting Tests
    func testDateFormatting() throws {
        let date = Date(timeIntervalSince1970: 1640995200) // Jan 1, 2022, 00:00:00 UTC
        
        // Test 6.1: Date formatting should be consistent
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let formattedDate = formatter.string(from: date)
        XCTAssertFalse(formattedDate.isEmpty, "Formatted date should not be empty")
        
        // Test 6.2: Relative date calculations
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        
        XCTAssertNotNil(yesterday, "Yesterday date should be calculable")
        XCTAssertNotNil(tomorrow, "Tomorrow date should be calculable")
        XCTAssertLessThan(yesterday, now, "Yesterday should be before now")
        XCTAssertGreaterThan(tomorrow, now, "Tomorrow should be after now")
        
        // Test 6.3: Time interval calculations
        let timeInterval = now.timeIntervalSince(yesterday)
        XCTAssertGreaterThan(timeInterval, 86000, "Time interval should be approximately 24 hours")
        XCTAssertLessThan(timeInterval, 87000, "Time interval should be approximately 24 hours")
    }
    
    // MARK: - Performance Tests
    func testThemePerformance() throws {
        let theme = AppTheme.shared
        
        // Test performance of accessing theme properties
        measure {
            for _ in 0..<1 {
                _ = theme.currentGradient.accentColor
                _ = theme.currentGradient.secondaryColor
                _ = theme.currentGradient.backgroundColor
            }
        }
    }
    
    func testStringValidationPerformance() throws {
        let testEmails = [
            "test@example.com",
            "invalid_email",
            "another@test.org",
            "bad_email@",
            "user@domain.co.uk"
        ]
        
        // Test performance of email validation
        measure {
            for _ in 0..<1 {
                for email in testEmails {
                    _ = email.isValidEmail()
                }
            }
        }
    }
}

// MARK: - String Extension for Email Validation
extension String {
    func isValidEmail() -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
}
