import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthService.shared
    @State private var showOnboarding = false
    @State private var isInitialized = false
    
    var body: some View {
        ZStack {
            GradientBackgroundView()
            
            Group {
                if !isInitialized {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                } else if authService.isAuthenticated {
                    MainTabView()
                        .onAppear {
                            checkFirstLaunch()
                        }
                } else {
                    AuthContainerView()
                }
            }
        }
        .task {
            await initializeApp()
        }
        .sheet(isPresented: $showOnboarding, onDismiss: {
            UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        }) {
            WelcomeSheetView(isShowing: $showOnboarding)
        }
    }
    
    private func initializeApp() async {
        await authService.checkAuthState()
        isInitialized = true
    }
    
    private func checkFirstLaunch() {
        if !UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showOnboarding = true
            }
        }
    }
}

#Preview {
    ContentView()
}
