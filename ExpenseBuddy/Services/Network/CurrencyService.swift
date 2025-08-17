import Foundation
import Combine
import SwiftUI

class CurrencyService: ObservableObject {
    static let shared = CurrencyService()
    
    @Published var selectedCurrency: Currency = .usd {
        didSet {
            UserDefaults.standard.set(selectedCurrency.rawValue, forKey: "selected_currency")
            NotificationCenter.default.post(name: .currencyChanged, object: nil)
        }
    }
    
    @Published var exchangeRates: [String: Double] = [:]
    
    private let exchangeRateCache = NSCache<NSString, NSNumber>()
    
    private init() {
        loadSelectedCurrency()
        loadExchangeRates()
    }
    
    private func loadSelectedCurrency() {
        if let currencyString = UserDefaults.standard.string(forKey: "selected_currency"),
           let currency = Currency(rawValue: currencyString) {
            selectedCurrency = currency
        }
    }
    
    // Add this method that was missing
    func updateCurrency(_ currency: Currency) {
        selectedCurrency = currency
    }
    
    func formatAmount(_ amount: Double, currency: Currency, showSymbol: Bool = true) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.rawValue
        formatter.currencySymbol = showSymbol ? currency.symbol : ""
        formatter.maximumFractionDigits = 2
        
        // Handle large numbers
        if amount >= 1_000_000 {
            formatter.maximumFractionDigits = 1
            return "\(currency.symbol)\(String(format: "%.1fM", amount / 1_000_000))"
        } else if amount >= 1_000 {
            formatter.maximumFractionDigits = 0
            return "\(currency.symbol)\(String(format: "%.0fK", amount / 1_000))"
        }
        
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currency.symbol)\(amount)"
    }
    
    func convertAmount(_ amount: Double, from: Currency, to: Currency) -> Double {
        guard from != to else { return amount }
        
        // Use cached rates or default rates
        let fromRate = exchangeRates[from.rawValue] ?? from.defaultRate
        let toRate = exchangeRates[to.rawValue] ?? to.defaultRate
        
        return (amount / fromRate) * toRate
    }
    
    private func loadExchangeRates() {
        // Load from cache first
        for currency in Currency.allCases {
            if let cachedRate = exchangeRateCache.object(forKey: NSString(string: currency.rawValue)) {
                exchangeRates[currency.rawValue] = cachedRate.doubleValue
            } else {
                exchangeRates[currency.rawValue] = currency.defaultRate
            }
        }
        
        // Fetch fresh rates in background
        Task {
            await fetchExchangeRates()
        }
    }
    
    private func fetchExchangeRates() async {
        // Implementation for fetching real exchange rates
        // For now, using default rates
        await MainActor.run {
            for currency in Currency.allCases {
                exchangeRates[currency.rawValue] = currency.defaultRate
                exchangeRateCache.setObject(
                    NSNumber(value: currency.defaultRate),
                    forKey: NSString(string: currency.rawValue)
                )
            }
        }
    }
}


extension Notification.Name {
    static let currencyChanged = Notification.Name("currencyChanged")
}
