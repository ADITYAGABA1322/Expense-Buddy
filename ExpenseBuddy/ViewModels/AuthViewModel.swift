import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var isAuthenticated = false
    
    private let authService = AuthService.shared
    
    init() {
        isAuthenticated = authService.isAuthenticated
    }
    
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = ""
        
        do {
            try await AuthService.shared.login(email: email, password: password)
            isAuthenticated = authService.isAuthenticated
        } catch let authErr as AuthError {
            errorMessage = authErr.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func register(email: String, password: String, firstName: String, lastName: String) async {
        isLoading = true
        errorMessage = ""
        
        do {
            try await authService.register(
                email: email,
                password: password,
                firstName: firstName,
                lastName: lastName
            )
            isAuthenticated = authService.isAuthenticated
        } catch {
            errorMessage = "Registration failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func logout() {
        authService.signOut()
        isAuthenticated = false
    }
}
