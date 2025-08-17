import SwiftUI

@main
struct ExpenseBuddyApp: App {
    @StateObject private var auth = AuthService.shared
    @StateObject private var theme = AppTheme.shared
    @State private var showOnboarding = false
    @State private var initialized = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !initialized {
                    // 🎯 BEAUTIFUL LOTTIE LOADING VIEW
                   // LottieLoadingView()
                    AnimatedLoadingView()
                        .transition(.opacity)
                } else if auth.isAuthenticated {
                    MainTabView()
                        .onAppear {
                            if !UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
                                showOnboarding = true
                            }
                        }
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    AuthContainerView()
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.6), value: initialized)
            .animation(.easeInOut(duration: 0.6), value: auth.isAuthenticated)
            .task {
                // Add a minimum loading time for better UX
                async let authCheck = auth.checkAuthState()
                async let minimumDelay = Task.sleep(nanoseconds: 2_500_000_000) // 2.5 seconds
                
                // Wait for both to complete
                await authCheck
                await (try? minimumDelay)
                
                withAnimation(.easeOut(duration: 0.8)) {
                    initialized = true
                }
            }
            .sheet(isPresented: $showOnboarding, onDismiss: {
                UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
            }) {
                WelcomeSheetView(isShowing: $showOnboarding)
            }
        }
    }
}
