import SwiftUI

struct MainTabView: View {
    @StateObject private var theme = AppTheme.shared
    @State private var selectedTab = 0
    @State private var showSplash: Bool = true
    var body: some View {
        ZStack {
            GradientBackgroundView()
                
                TabView(selection: $selectedTab) {
                    ExpenseListView(selectedTab: $selectedTab)
                        .tabItem {
                            Image(systemName: "list.bullet")
                            Text("Expenses")
                        }
                        .tag(0)
                    
                    ChartsView()
                        .tabItem {
                            Image(systemName: "chart.pie")
                            Text("Analytics")
                        }
                        .tag(1)
                    
                    ProfileView()
                        .tabItem {
                            Image(systemName: "person.circle")
                            Text("Profile")
                        }
                        .tag(2)
                }
                .accentColor(theme.currentGradient.accentColor)
        }
        .onAppear{
            DispatchQueue.main.asyncAfter(deadline: .now() + 2){
                withAnimation{
                    showSplash = false
                }
            }
        }
    }
}


#Preview {
    MainTabView()
}

