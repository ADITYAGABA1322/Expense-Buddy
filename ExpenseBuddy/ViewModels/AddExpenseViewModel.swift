import Foundation
import Combine

@MainActor
class AddExpenseViewModel: ObservableObject {
    @Published var title = ""
    @Published var amount = ""
    @Published var category = "Food"
    @Published var date = Date()
    @Published var description = ""
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let expenseService = ExpenseService.shared
    private let coreDataService = CoreDataService.shared
    private let currencyService = CurrencyService.shared
    private let networkService = NetworkService.shared
    
    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !amount.isEmpty &&
        Double(amount) != nil &&
        Double(amount)! > 0
    }
    
    func saveExpense() async -> Bool {
        guard isFormValid else {
            errorMessage = "Please fill all required fields with valid data"
            return false
        }
        
        guard let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "Please enter a valid amount"
            return false
        }
        
        isLoading = true
        errorMessage = ""
        
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Always save locally first for offline support
        let localId = coreDataService.createOfflineExpense(
            title: trimmedTitle,
            amount: amountValue,
            category: category,
            currency: currencyService.selectedCurrency.rawValue,
            date: date,
            description: trimmedDescription.isEmpty ? nil : trimmedDescription
        )
        
        // Try to sync to server if online
        if networkService.isConnected {
            do {
                let expenseRequest = CreateExpenseRequest(
                    title: trimmedTitle,
                    amount: amountValue,
                    category: category,
                    currency: currencyService.selectedCurrency.rawValue,
                    date: date,
                    description: trimmedDescription.isEmpty ? nil : trimmedDescription
                )
                
                let serverExpense = try await expenseService.createExpense(expenseRequest)
                
                // Update local expense with server data
                coreDataService.markExpenseAsSynced(localId: localId, serverData: serverExpense)
                
            } catch {
                // If server save fails, keep the local version for later sync
                print("Failed to save to server, will sync later: \(error)")
            }
        }
        
        // After saving expense
        NotificationCenter.default.post(name: .expensesUpdated, object: nil)
        
        clearForm()
        isLoading = false
        return true
    }
    
    private func clearForm() {
        title = ""
        amount = ""
        category = "Food"
        date = Date()
        description = ""
        errorMessage = ""
    }
}
