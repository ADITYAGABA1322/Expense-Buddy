import Foundation
import Combine
import SwiftUI


@MainActor
final class SummaryViewModel: ObservableObject {
//    @Published var summary: ExpenseSummary?
    @Published var summary: ExpenseSummary? {
           didSet {
               withAnimation(.easeInOut(duration: 0.3)) {}
           }
       }
    
    private let currencyService = CurrencyService.shared
    private let coreDataService = CoreDataService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private var currentStart: Date?
    private var currentEnd: Date?
    
    init() {
        // React to currency change
        NotificationCenter.default.publisher(for: Notification.Name.currencyChanged)
            .sink { [weak self] _ in
                self?.recompute()
            }
            .store(in: &cancellables)
        
        // React to expense updates
        NotificationCenter.default.publisher(for: Notification.Name.expensesUpdated)
            .sink { [weak self] _ in
                self?.recompute()
            }
            .store(in: &cancellables)
    }
    
    func setRange(start: Date?, end: Date?) {
        currentStart = start
        currentEnd = end
        recompute()
    }
    
    func recompute() {
        let expenses = coreDataService.fetchLocalExpenses()
        
        // Filter by range
        let filtered = expenses.filter { e in
            let afterStart = currentStart.map { e.date >= $0 } ?? true
            let beforeEnd  = currentEnd.map { e.date <= $0 } ?? true
            return afterStart && beforeEnd
        }
        
        // Convert amounts to selected currency
        let converted = filtered.map { e -> (Expense, Double) in
            let from = Currency(rawValue: e.currency) ?? .usd
            let amount = currencyService.convertAmount(e.amount, from: from, to: currencyService.selectedCurrency)
            return (e, amount)
        }
        
        // Totals
        let totalAmount = converted.reduce(0) { $0 + $1.1 }
        let totalCount = converted.count
        
        // Category breakdown
        let groupedByCategory = Dictionary(grouping: converted, by: { $0.0.category })
        let categoryBreakdown: [CategoryBreakdown] = groupedByCategory.map { (cat, items) in
            let sum = items.reduce(0) { $0 + $1.1 }
            return CategoryBreakdown(category: cat, _sum: AmountSum(amount: sum), _count: items.count)
        }.sorted { $0._sum.amount > $1._sum.amount }
        
        // Monthly trend (bucket by month start)
        let monthlyGroups = Dictionary(grouping: converted) { pair in
            Calendar.current.dateInterval(of: .month, for: pair.0.date)?.start ?? pair.0.date
        }
        let monthlyTrend: [MonthlyTrend] = monthlyGroups.map { (date, items) in
            let sum = items.reduce(0) { $0 + $1.1 }
            return MonthlyTrend(date: date, _sum: AmountSum(amount: sum), _count: items.count)
        }
        .sorted { $0.date < $1.date }
        
        summary = ExpenseSummary(
            totalAmount: totalAmount,
            totalCount: totalCount,
            categoryBreakdown: categoryBreakdown,
            monthlyTrend: monthlyTrend
        )
    }
}
