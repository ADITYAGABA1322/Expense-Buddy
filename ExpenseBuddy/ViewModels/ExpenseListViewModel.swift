import Foundation
import Combine

@MainActor

class ExpenseListViewModel: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var selectedCategory: String?
    @Published var isServerAvailable = true
    
    private let expenseService = ExpenseService.shared
    private let coreDataService = CoreDataService.shared
    private let currencyService = CurrencyService.shared
    private let cacheService = CacheService.shared
    
    private var loadingTask: Task<Void, Never>?
    
    func loadExpenses() async {
        // Cancel any existing loading task
        loadingTask?.cancel()
        
        loadingTask = Task {
            await performLoad()
        }
        
        await loadingTask?.value
        NotificationCenter.default.post(name: .expensesUpdated, object: nil)
    }
    
    private func performLoad() async {
        // Show cached data immediately for better UX
        loadCachedData()
        
        isLoading = true
        errorMessage = ""
        
        do {
            if NetworkService.shared.isConnected {
                print("Loading expenses from network...")
                
                // Try to load from network
                let response = try await expenseService.getExpenses(category: selectedCategory)
                
                print("Received \(response.expenses.count) expenses from server")
                
                // Cache the response
                let cacheKey = "expenses_\(selectedCategory ?? "all")"
                cacheService.setMemoryCache(response, forKey: cacheKey, expiry: 60)
                cacheService.setDiskCache(response, forKey: cacheKey)
                
                // Update UI
                expenses = response.expenses.map { expense in
                    convertExpenseCurrency(expense)
                }
                
                print("UI updated with \(expenses.count) expenses")
                
                // Save to Core Data for offline access
                for expense in response.expenses {
                    coreDataService.saveExpenseLocally(expense)
                }
                isServerAvailable = true
                
                NotificationCenter.default.post(name: .expensesUpdated, object: nil)
                
            } else {
                print("No network connection, loading from local storage...")
                loadLocalExpenses()
            }
        } catch {
            let errorDescription = (error as? NetworkService.NetworkError)?.errorDescription ?? error.localizedDescription
            errorMessage = "Failed to load expenses: \(errorDescription)"
            print("Load expenses error: \(error)")
            
            // Fallback to local data
            print("Falling back to local data...")
            loadLocalExpenses()
        }
        
        isLoading = false
        print("Loading completed. Final expense count: \(expenses.count)")
    }
    
    
    private func loadCachedData() {
        let cacheKey = "expenses_\(selectedCategory ?? "all")"
        
        // Try memory cache first
        if let cachedResponse: ExpenseResponse = cacheService.getMemoryCache(ExpenseResponse.self, forKey: cacheKey) {
            expenses = cachedResponse.expenses.map { convertExpenseCurrency($0) }
            return
        }
        
        // Try disk cache
        if let cachedResponse: ExpenseResponse = cacheService.getDiskCache(ExpenseResponse.self, forKey: cacheKey) {
            expenses = cachedResponse.expenses.map { convertExpenseCurrency($0) }
            return
        }
        
        // Finally try Core Data
        loadLocalExpenses()
    }
    
    
    
    // In your ExpenseListViewModel deleteExpense method
    func deleteExpense(_ expense: Expense) async {
        await MainActor.run {
            expenses.removeAll { $0.id == expense.id }
        }
        
        if NetworkService.shared.isConnected {
            
            do {
                try await ExpenseService.shared.deleteExpense(id: expense.id)
                
                CoreDataService.shared.deleteExpenseCompletely(id: expense.id)
            } catch {
                
                CoreDataService.shared.markExpenseAsDeleted(id: expense.id)
            }
        } else {
            
            CoreDataService.shared.markExpenseAsDeleted(id: expense.id)
        }
        
        NotificationCenter.default.post(name: .expensesUpdated, object: nil)
    }
    
    func refreshExpenses() async {
        let cacheKey = "expenses_\(selectedCategory ?? "all")"
        cacheService.removeCacheForKey(cacheKey)
        
        await loadExpenses()
        NotificationCenter.default.post(name: .expensesUpdated, object: nil)
    }
    
    private func loadLocalExpenses() {
        let localExpenses = coreDataService.fetchLocalExpenses()
        
        expenses = localExpenses
            .filter { expense in
                guard let selectCategory = selectedCategory else { return true }
                return expense.category == selectCategory
            }
            .map { expense in
                convertExpenseCurrency(expense)
            }
        print("Loaded \(expenses.count) local expenses")
        NotificationCenter.default.post(name: .expensesUpdated , object: nil)
    }
    
    private func convertExpenseCurrency(_ expense: Expense) -> Expense {
        let originalCurrency = Currency(rawValue: expense.currency) ?? .usd
        let convertedAmount = currencyService.convertAmount(
            expense.amount,
            from: originalCurrency,
            to: currencyService.selectedCurrency
        )
        
        return Expense(
            id: expense.id,
            title: expense.title,
            amount: convertedAmount,
            category: expense.category,
            currency: currencyService.selectedCurrency.rawValue,
            date: expense.date,
            description: expense.description,
            syncedAt: expense.syncedAt
        )
    }
    
    
    
    deinit {
        loadingTask?.cancel()
    }
}
