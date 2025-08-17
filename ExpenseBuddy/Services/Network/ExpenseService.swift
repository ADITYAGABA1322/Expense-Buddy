import Foundation
import Combine

class ExpenseService: ObservableObject {
    static let shared = ExpenseService()
    private let networkService = NetworkService.shared
    
    private init() {}
    
    func createExpense(_ expense: CreateExpenseRequest) async throws -> Expense {
        return try await networkService.request(
            endpoint: "/expenses",
            method: "POST",
            body: expense,
            responseType: Expense.self,
            requiresAuth: true
        )
    }
    
    func getExpenses(page: Int = 1, limit: Int = 50, category: String? = nil) async throws -> ExpenseResponse {
        var endpoint = "/expenses?page=\(page)&limit=\(limit)"
        if let category = category {
            endpoint += "&category=\(category)"
        }
        
        return try await networkService.request(
            endpoint: endpoint,
            responseType: ExpenseResponse.self,
            requiresAuth: true
        )
    }
    
    func updateExpense(id: String, expense: CreateExpenseRequest) async throws -> Expense {
        return try await networkService.request(
            endpoint: "/expenses/\(id)",
            method: "PATCH",
            body: expense,
            responseType: Expense.self,
            requiresAuth: true
        )
    }
    
    func deleteExpense(id: String) async throws {
        let _: EmptyResponse = try await networkService.request(
            endpoint: "/expenses/\(id)",
            method: "DELETE",
            responseType: EmptyResponse.self,
            requiresAuth: true
        )
    }
    
    func getSummary(startDate: String? = nil, endDate: String? = nil) async throws -> ExpenseSummary {
        var endpoint = "/expenses/summary"
        var queryParams: [String] = []
        
        if let startDate = startDate {
            queryParams.append("startDate=\(startDate)")
        }
        if let endDate = endDate {
            queryParams.append("endDate=\(endDate)")
        }
        
        if !queryParams.isEmpty {
            endpoint += "?" + queryParams.joined(separator: "&")
        }
        
        return try await networkService.request(
            endpoint: endpoint,
            responseType: ExpenseSummary.self,
            requiresAuth: true
        )
    }
}
