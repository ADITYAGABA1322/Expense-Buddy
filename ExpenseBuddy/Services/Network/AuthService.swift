 import Foundation
 import Combine
 
 enum AuthError: LocalizedError {
     case invalidCredentials
     case unknown(String)
     var errorDescription: String? {
         switch self {
         case .invalidCredentials: return "Invalid email or password"
         case .unknown(let msg): return msg
         }
     }
 }
 
 final class AuthService: ObservableObject {
     static let shared = AuthService()
     
     private let networkService = NetworkService.shared
     private let tokenKey = "auth_token"
     private let userKey = "current_user"
     
     @Published private(set) var isAuthenticated = false
     @Published private(set) var currentUser: User?
     
     var user: User? { currentUser }
     
     private init() {
         // Check saved auth state immediately
         loadSavedAuthState()
     }
     
     private func loadSavedAuthState() {
         guard let token = UserDefaults.standard.string(forKey: tokenKey), !token.isEmpty else {
             return
         }
         
         // Load saved user data
         if let userData = UserDefaults.standard.data(forKey: userKey),
            let user = try? JSONDecoder().decode(User.self, from: userData) {
             self.currentUser = user
             self.isAuthenticated = true
         }
     }
     
     func checkAuthState() async {
         await MainActor.run {
             loadSavedAuthState()
         }
         
         // If we have a token, verify it's still valid
         guard let token = UserDefaults.standard.string(forKey: tokenKey), !token.isEmpty else {
             await MainActor.run {
                 signOut(silent: true)
             }
             return
         }
         
         do {
             let profile: User = try await networkService.request(
                 endpoint: "/auth/profile",
                 responseType: User.self,
                 requiresAuth: true
             )
             await MainActor.run {
                 self.currentUser = profile
                 self.isAuthenticated = true
                 // Update saved user data
                 if let userData = try? JSONEncoder().encode(profile) {
                     UserDefaults.standard.set(userData, forKey: userKey)
                 }
             }
         } catch {
                // If we fail to get profile, assume token is invalid
                print("Failed to fetch profile: \(error)")
         }
     }
     
     func login(email: String, password: String) async throws {
         let req = LoginRequest(email: email, password: password)
         do {
             let response: AuthResponse = try await networkService.request(
                 endpoint: "/auth/login",
                 method: "POST",
                 body: req,
                 responseType: AuthResponse.self
             )
             await MainActor.run { saveAuthData(response: response) }
         } catch {
             if case NetworkService.NetworkError.serverError(401) = error {
                 throw AuthError.invalidCredentials
             } else {
                 throw error
             }
         }
     }
     
     func register(email: String, password: String, firstName: String, lastName: String) async throws {
         let req = RegisterRequest(email: email,
                                   password: password,
                                   firstName: firstName,
                                   lastName: lastName)
         let response: AuthResponse = try await networkService.request(
             endpoint: "/auth/register",
             method: "POST",
             body: req,
             responseType: AuthResponse.self
         )
         await MainActor.run { saveAuthData(response: response) }
     }
     
     private func saveAuthData(response: AuthResponse) {
         UserDefaults.standard.set(response.access_token, forKey: tokenKey)
         if let userData = try? JSONEncoder().encode(response.user) {
             UserDefaults.standard.set(userData, forKey: userKey)
         }
         currentUser = response.user
         isAuthenticated = true
     }
     
     func signOut(silent: Bool = false) {
         UserDefaults.standard.removeObject(forKey: tokenKey)
         UserDefaults.standard.removeObject(forKey: userKey)
         currentUser = nil
         isAuthenticated = false
         if !silent {
             // optional notification
         }
     }
 }

