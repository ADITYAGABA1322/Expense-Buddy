import Foundation

// MARK: - Main Expense Model
struct Expense: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let amount: Double
    let category: String
    let currency: String
    let date: Date
    let description: String?
    let syncedAt: Date?
    
    // Custom coding keys if needed
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case amount
        case category
        case currency
        case date
        case description
        case syncedAt
    }
    
    // Custom decoder to handle string dates
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        amount = try container.decode(Double.self, forKey: .amount)
        category = try container.decode(String.self, forKey: .category)
        currency = try container.decode(String.self, forKey: .currency)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        
        // Handle date - try different formats
        if let dateString = try? container.decode(String.self, forKey: .date) {
            date = Self.parseDate(from: dateString)
        } else if let dateTimestamp = try? container.decode(Double.self, forKey: .date) {
            date = Date(timeIntervalSince1970: dateTimestamp)
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .date,
                in: container,
                debugDescription: "Date could not be decoded from string or timestamp"
            )
        }
        
        // Handle syncedAt - Corrected version
        if let syncedAtString = try container.decodeIfPresent(String.self, forKey: .syncedAt) {
            syncedAt = Self.parseDate(from: syncedAtString)
        } else if let syncedAtTimestamp = try container.decodeIfPresent(Double.self, forKey: .syncedAt) {
            syncedAt = Date(timeIntervalSince1970: syncedAtTimestamp)
        } else {
            syncedAt = nil
        }
    }
    
    // Custom encoder to ensure consistent format
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(amount, forKey: .amount)
        try container.encode(category, forKey: .category)
        try container.encode(currency, forKey: .currency)
        try container.encodeIfPresent(description, forKey: .description)
        
        // Encode dates as ISO8601 strings
        try container.encode(ISO8601DateFormatter().string(from: date), forKey: .date)
        
        if let syncedAt = syncedAt {
            try container.encode(ISO8601DateFormatter().string(from: syncedAt), forKey: .syncedAt)
        }
    }
    
    // Regular initializer
    init(
        id: String,
        title: String,
        amount: Double,
        category: String,
        currency: String,
        date: Date,
        description: String? = nil,
        syncedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.currency = currency
        self.date = date
        self.description = description
        self.syncedAt = syncedAt
    }
    
    // Date parsing helper that handles multiple formats - MADE PUBLIC
    static func parseDate(from string: String) -> Date {
        // Try ISO8601 format first
        if let date = ISO8601DateFormatter().date(from: string) {
            return date
        }
        
        // Try common date formats
        let formatters: [DateFormatter] = [
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter
            }()
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: string) {
                return date
            }
        }
        
        // If all else fails, return current date
        print("Warning: Could not parse date string '\(string)', using current date")
        return Date()
    }
}

// MARK: - Response Models
struct ExpenseResponse: Codable {
    let expenses: [Expense]
    let totalCount: Int?
    let page: Int?
    let limit: Int?
    
    enum CodingKeys: String, CodingKey {
        case expenses
        case totalCount = "total_count"
        case page
        case limit
    }
}

struct CreateExpenseRequest: Codable {
    let title: String
    let amount: Double
    let category: String
    let currency: String
    let date: String // Send as string to backend
    let description: String?
    
    init(title: String, amount: Double, category: String, currency: String, date: Date, description: String? = nil) {
        self.title = title
        self.amount = amount
        self.category = category
        self.currency = currency
        self.date = ISO8601DateFormatter().string(from: date)
        self.description = description
    }
}

struct EmptyResponse: Codable {}

// MARK: - Summary Models
struct ExpenseSummary: Codable {
    let totalAmount: Double
    let totalCount: Int
    let categoryBreakdown: [CategoryBreakdown]
    let monthlyTrend: [MonthlyTrend]
}

struct CategoryBreakdown: Codable, Identifiable {
    let id = UUID()
    let category: String
    let _sum: AmountSum
    let _count: Int
    
    enum CodingKeys: String, CodingKey {
        case category
        case _sum
        case _count
    }
}

struct MonthlyTrend: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let _sum: AmountSum
    let _count: Int
    
    enum CodingKeys: String, CodingKey {
        case date
        case _sum
        case _count
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        _sum = try container.decode(AmountSum.self, forKey: ._sum)
        _count = try container.decode(Int.self, forKey: ._count)
        
        // Handle date parsing
        if let dateString = try? container.decode(String.self, forKey: .date) {
            date = Expense.parseDate(from: dateString)
        } else if let dateTimestamp = try? container.decode(Double.self, forKey: .date) {
            date = Date(timeIntervalSince1970: dateTimestamp)
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .date,
                in: container,
                debugDescription: "Date could not be decoded"
            )
        }
    }
    
    init(date: Date, _sum: AmountSum, _count: Int) {
        self.date = date
        self._sum = _sum
        self._count = _count
    }
}

struct AmountSum: Codable {
    let amount: Double
}

// MARK: - Helper Extensions
extension Expense {
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}

