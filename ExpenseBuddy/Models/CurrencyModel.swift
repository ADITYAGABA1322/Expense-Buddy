import Foundation

enum Currency: String, CaseIterable {
    case usd = "USD"
    case eur = "EUR"
    case jpy = "JPY"
    case inr = "INR"
    
    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .jpy: return "¥"
        case .inr: return "₹"
        }
    }
    
    var name: String {
        switch self {
        case .usd: return "US Dollar"
        case .eur: return "Euro"
        case .jpy: return "Japanese Yen"
        case .inr: return "Indian Rupee"
        }
    }
    
    var defaultRate: Double {
        switch self {
        case .usd: return 1.0
        case .eur: return 0.85
        case .jpy: return 110.0
        case .inr: return 74.0
        }
    }

}

struct ExchangeRate: Codable {
    let base: String
    let rates: [String: Double]
    let timestamp: Date
}
