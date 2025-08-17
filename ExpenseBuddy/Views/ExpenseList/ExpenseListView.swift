import SwiftUI

struct ExpenseListView: View {
    @StateObject private var viewModel = ExpenseListViewModel()
    @StateObject private var theme = AppTheme.shared
    @ObservedObject private var currencyService = CurrencyService.shared
    @ObservedObject private var networkService = NetworkService.shared
    @ObservedObject private var syncService = OfflineSyncService.shared
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showingAddExpense = false
    @State private var showWelcomeSheet = false
    @State private var selectedCategory: String? = nil
    @State private var editingExpense: Expense? = nil
    @State private var showGuide = false
    
    // Add this for tab navigation
    @Binding var selectedTab: Int
    
    private let categories = ["All", "Food", "Transport", "Shopping", "Entertainment", "Bills", "Health", "Other"]
    
    // Update initializer to accept selectedTab binding
    init(selectedTab: Binding<Int> = .constant(0)) {
        self._selectedTab = selectedTab
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                GradientBackgroundView()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Enhanced Status Banner - Always visible
                        EnhancedStatusBanner()
                        
                        // Quick Guide Section
                        QuickGuideCard(showGuide: $showGuide)
                        
                        // Header Cards Section
                        headerSection
                        
                        // Budget Overview Card
                        BudgetOverviewCard(expenses: viewModel.expenses)
                        
                        // Quick Actions - UPDATED
                        QuickActionsCard(
                            onAddExpense: { showingAddExpense = true },
                            onViewAnalytics: {
                                // Navigate to Analytics tab
                                selectedTab = 1
                            }
                        )
                        
                        // Category Filter
                        CategoryFilterCard(
                            selectedCategory: $selectedCategory,
                            categories: categories,
                            onCategoryChange: { category in
                                viewModel.selectedCategory = category
                                Task { await viewModel.loadExpenses() }
                            }
                        )
                        
                        // Expenses List
                        if viewModel.expenses.isEmpty {
                            EmptyStateCard {
                                showingAddExpense = true
                            }
                        } else {
                            ExpensesListCard(
                                groupedExpenses: groupedExpenses,
                                onEdit: { editingExpense = $0 },
                                onDelete: { expense in
                                    Task {
                                        await viewModel.deleteExpense(expense)
                                        NotificationCenter.default.post(name: .expensesUpdated, object: nil)
                                    }
                                }
                            )
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Expenses")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                // LEFT SIDE - Welcome Sheet Button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showWelcomeSheet = true
                    } label: {
                        Image(systemName: "sparkles")
                            .font(.title2)
                            .foregroundColor(theme.currentGradient.accentColor)
                    }
                }
                
                // RIGHT SIDE - Theme Button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        theme.nextGradient()
                    } label: {
                        Image(systemName: "circle.lefthalf.filled")
                            .font(.title2)
                            .foregroundColor(theme.currentGradient.accentColor)
                    }
                }
            }
            .sheet(item: $editingExpense) { expense in
                EditExpenseView(expense: expense) {
                    Task {
                        await viewModel.loadExpenses()
                        NotificationCenter.default.post(name: .expensesUpdated, object: nil)
                    }
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView {
                    Task {
                        await viewModel.loadExpenses()
                        NotificationCenter.default.post(name: .expensesUpdated, object: nil)
                    }
                }
            }
            .sheet(isPresented: $showWelcomeSheet) {
                WelcomeSheetView(isShowing: $showWelcomeSheet)
            }
            .task {
                await viewModel.loadExpenses()
                if networkService.isConnected {
                    await syncService.performSync()
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(spacing: 16) {
            // Currency Card
            CurrencyCard()
            
            // Status Card
           // StatusCard()
            // Quick Stats Card (replaces StatusCard)
                   QuickStatsCard(expenses: viewModel.expenses)
        }
    }
    
    private var groupedExpenses: [String: [Expense]] {
        Dictionary(grouping: viewModel.expenses) {
            DateFormatter.dayFormatter.string(from: $0.date)
        }
    }
}



// MARK: - Quick Stats Card (Redesigned - more compact and balanced)
struct QuickStatsCard: View {
    let expenses: [Expense]
    @StateObject private var currencyService = CurrencyService.shared
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    private var todayExpenses: Double {
        let today = Calendar.current.startOfDay(for: Date())
        return expenses.filter {
            Calendar.current.isDate($0.date, inSameDayAs: today)
        }.reduce(0) { $0 + $1.amount }
    }
    
    private var thisWeekExpenses: Double {
        let calendar = Calendar.current
        let now = Date()
        return expenses.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .weekOfYear)
        }.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Today's Stats Icon
            ZStack {
                Circle()
                    .fill(theme.currentGradient.accentColor.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 16))
                    .foregroundColor(theme.currentGradient.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Today")
                        .font(.caption)
                        .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                    
                    Spacer()
                    
                    Text(currencyService.formatAmount(todayExpenses, currency: currencyService.selectedCurrency))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                }
                
                // Week comparison in smaller text
                HStack {
                    Text("This Week")
                        .font(.caption2)
                        .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                    
                    Spacer()
                    
                    Text(currencyService.formatAmount(thisWeekExpenses, currency: currencyService.selectedCurrency))
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(theme.currentGradient.secondaryColor)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.adaptiveCardBackground(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    theme.currentGradient.accentColor.opacity(0.2),
                                    theme.currentGradient.secondaryColor.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Enhanced Budget Overview Card (Much Better Design)
struct BudgetOverviewCard: View {
    let expenses: [Expense]
    @StateObject private var currencyService = CurrencyService.shared
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateProgress = false
    
    private var totalThisMonth: Double {
        let calendar = Calendar.current
        let now = Date()
        let thisMonth = expenses.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }
        return thisMonth.reduce(0) { $0 + $1.amount }
    }
    
    private var transactionCount: Int {
        let calendar = Calendar.current
        let now = Date()
        return expenses.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }.count
    }
    
    private var lastWeekTotal: Double {
        let calendar = Calendar.current
        let now = Date()
        let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        let lastWeekExpenses = expenses.filter {
            calendar.isDate($0.date, equalTo: lastWeek, toGranularity: .weekOfYear)
        }
        return lastWeekExpenses.reduce(0) { $0 + $1.amount }
    }
    
    private var categoryBreakdown: [(String, Double, Color)] {
        let categories = ["Food", "Transport", "Shopping", "Entertainment"]
        return categories.map { category in
            let amount = expenses.filter { $0.category == category }.reduce(0) { $0 + $1.amount }
            return (category, amount, categoryColor(for: category))
        }.sorted { $0.1 > $1.1 }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Enhanced Header with comparison
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundColor(theme.currentGradient.accentColor)
                            
                            Text("This Month")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                        }
                        
                        Text(currencyService.formatAmount(totalThisMonth, currency: currencyService.selectedCurrency))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                    }
                    
                    Spacer()
                    
                    // Enhanced transaction count with trend
                    VStack(alignment: .trailing, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.right")
                                .font(.caption2)
                                .foregroundColor(totalThisMonth > lastWeekTotal ? .green : .red)
                            
                            Text("\(transactionCount)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(theme.currentGradient.accentColor)
                        }
                        
                        Text("Transactions")
                            .font(.caption)
                            .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(theme.currentGradient.accentColor.opacity(0.1))
                            )
                    }
                }
                
                // Trend comparison
                if lastWeekTotal > 0 {
                    HStack {
                        let percentageChange = ((totalThisMonth - lastWeekTotal) / lastWeekTotal) * 100
                        let isIncrease = percentageChange > 0
                        
                        Image(systemName: isIncrease ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2)
                            .foregroundColor(isIncrease ? .red : .green)
                        
                        Text("\(abs(Int(percentageChange)))% \(isIncrease ? "more" : "less") than last week")
                            .font(.caption)
                            .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                        
                        Spacer()
                    }
                }
            }
            
            // Enhanced Category Breakdown
            VStack(spacing: 16) {
                HStack {
                    Text("Top Categories")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                    
                    Spacer()
                    
                    // Theme indicator with animation
                    Circle()
                        .fill(theme.currentGradient.accentColor)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animateProgress ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateProgress)
                }
                
                // Enhanced category rows
                VStack(spacing: 12) {
                    ForEach(Array(categoryBreakdown.enumerated()), id: \.offset) { index, item in
                        let (category, amount, color) = item
                        let percentage = totalThisMonth > 0 ? amount / totalThisMonth : 0
                        
                        HStack(spacing: 12) {
                            // Category icon
                            ZStack {
                                Circle()
                                    .fill(color.opacity(0.1))
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: categoryIcon(for: category))
                                    .font(.system(size: 14))
                                    .foregroundColor(color)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(category)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                                    
                                    Spacer()
                                    
                                    Text("\(Int(percentage * 100))%")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(color)
                                }
                                
                                HStack {
                                    // Enhanced progress bar
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(theme.adaptiveCardBackground(for: colorScheme).opacity(0.3))
                                            .frame(height: 6)
                                        
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(
                                                LinearGradient(
                                                    colors: [color, color.opacity(0.6)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: animateProgress ? percentage * 200 : 0, height: 6)
                                            .animation(.spring(response: 1.0, dampingFraction: 0.8).delay(Double(index) * 0.1), value: animateProgress)
                                    }
                                    .frame(width: 200)
                                    
                                    Spacer()
                                    
                                    Text(currencyService.formatAmount(amount, currency: currencyService.selectedCurrency))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.adaptiveCardBackground(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    theme.currentGradient.accentColor.opacity(0.3),
                                    theme.currentGradient.secondaryColor.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(
                    color: theme.currentGradient.accentColor.opacity(0.15),
                    radius: 15,
                    x: 0,
                    y: 8
                )
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3)) {
                animateProgress = true
            }
        }
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "food": return .orange
        case "transport": return .blue
        case "shopping": return .purple
        case "entertainment": return .pink
        default: return theme.currentGradient.accentColor
        }
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "food": return "fork.knife"
        case "transport": return "car.fill"
        case "shopping": return "bag.fill"
        case "entertainment": return "gamecontroller.fill"
        default: return "circle.fill"
        }
    }
}

// MARK: - Alternative Header Card Ideas (Choose one of these instead of StatusCard)

// Option 1: Savings Goal Card
struct SavingsGoalCard: View {
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    private let monthlyGoal: Double = 1000.0 // You can make this configurable
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "target")
                    .font(.caption)
                    .foregroundColor(theme.currentGradient.accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Monthly Goal")
                        .font(.caption2)
                        .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                    
                    Text("$\(Int(monthlyGoal))")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(theme.currentGradient.accentColor)
                }
                
                Spacer()
            }
            
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.caption)
                    .foregroundColor(theme.currentGradient.secondaryColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Progress")
                        .font(.caption2)
                        .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                    
                    Text("65%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.adaptiveCardBackground(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    theme.currentGradient.accentColor.opacity(0.2),
                                    theme.currentGradient.secondaryColor.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// Option 2: Time-based Quick Stats
struct TimeStatsCard: View {
    let expenses: [Expense]
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    private var thisWeekExpenses: Double {
        let calendar = Calendar.current
        let now = Date()
        return expenses.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .weekOfYear)
        }.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .font(.caption)
                    .foregroundColor(theme.currentGradient.accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("This Week")
                        .font(.caption2)
                        .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                    
                    Text("$\(Int(thisWeekExpenses))")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                }
                
                Spacer()
            }
            
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.caption)
                    .foregroundColor(theme.currentGradient.secondaryColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Avg/Day")
                        .font(.caption2)
                        .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                    
                    Text("$\(Int(thisWeekExpenses / 7))")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(theme.currentGradient.accentColor)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.adaptiveCardBackground(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    theme.currentGradient.accentColor.opacity(0.2),
                                    theme.currentGradient.secondaryColor.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
        )
    }
}


struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 16)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
            
            Spacer()
            
            Text(value)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

// MARK: - Quick Guide Card
struct QuickGuideCard: View {
    @Binding var showGuide: Bool
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(theme.currentGradient.accentColor)
                    
                    Text("Quick Guide")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring()) {
                        showGuide.toggle()
                    }
                }) {
                    Image(systemName: showGuide ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(theme.currentGradient.accentColor)
                }
            }
            
            if showGuide {
                VStack(spacing: 8) {
                    GuideItem(
                        icon: "plus.circle.fill",
                        title: "Add Expense",
                        description: "Tap 'Add Expense' or use the + button in toolbar"
                    )
                    
                    GuideItem(
                        icon: "pencil",
                        title: "Edit & Delete",
                        description: "Long press any expense to edit or delete it"
                    )
                    
                    GuideItem(
                        icon: "chart.pie.fill",
                        title: "View Analytics",
                        description: "Tap 'Analytics' to see your spending insights"
                    )
                    
                    GuideItem(
                        icon: "circle.lefthalf.filled",
                        title: "Change Theme",
                        description: "Use the theme button to switch colors"
                    )
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.adaptiveCardBackground(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(theme.currentGradient.accentColor.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct GuideItem: View {
    let icon: String
    let title: String
    let description: String
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(theme.currentGradient.accentColor)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.currentGradient.accentColor.opacity(0.05))
        )
    }
}

// MARK: - Updated Components with Theme Support

struct QuickActionsCard: View {
    let onAddExpense: () -> Void
    let onViewAnalytics: () -> Void
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Add Expense Button
            Button(action: onAddExpense) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                    Text("Add Expense")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [
                            theme.currentGradient.accentColor,
                            theme.currentGradient.secondaryColor
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
            }
            
            // Analytics Button - UPDATED
            Button(action: onViewAnalytics) {
                HStack {
                    Image(systemName: "chart.pie.fill")
                        .font(.title2)
                        .foregroundColor(theme.currentGradient.accentColor)
                    Text("Analytics")
                        .fontWeight(.semibold)
                        .foregroundColor(theme.currentGradient.accentColor)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.adaptiveCardBackground(for: colorScheme))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(theme.currentGradient.accentColor.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
    }
}

// MARK: - All other components remain the same but with theme-adaptive colors

struct CurrencyCard: View {
    @StateObject private var currencyService = CurrencyService.shared
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Menu {
            ForEach(Currency.allCases, id: \.self) { currency in
                Button {
                    currencyService.updateCurrency(currency)
                    NotificationCenter.default.post(name: .currencyChanged, object: nil)
                } label: {
                    HStack {
                        Text("\(currency.symbol) \(currency.name)")
                        if currency == currencyService.selectedCurrency {
                            Image(systemName: "checkmark")
                                .foregroundColor(theme.currentGradient.accentColor)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 12) {
                // Currency Symbol
                ZStack {
                    Circle()
                        .fill(theme.currentGradient.accentColor.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Text(currencyService.selectedCurrency.symbol)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(theme.currentGradient.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Currency")
                        .font(.caption)
                        .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                    
                    Text(currencyService.selectedCurrency.rawValue.uppercased())
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                }
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.adaptiveCardBackground(for: colorScheme))
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
            )
        }
    }
}

struct StatusCard: View {
    @ObservedObject private var networkService = NetworkService.shared
    @ObservedObject private var syncService = OfflineSyncService.shared
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            // Connection Status
            HStack(spacing: 8) {
                Circle()
                    .fill(networkService.isConnected ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                
                Text(networkService.isConnected ? "Online" : "Offline")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
            }
            
            // Sync Status
            if syncService.isSyncing {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(theme.currentGradient.accentColor)
                    
                    Text("Syncing")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.adaptiveCardBackground(for: colorScheme))
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
        )
    }
}



struct CategoryFilterCard: View {
    @Binding var selectedCategory: String?
    let categories: [String]
    let onCategoryChange: (String?) -> Void
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(categories, id: \.self) { category in
                        CategoryChip(
                            category: category,
                            isSelected: selectedCategory == (category == "All" ? nil : category)
                        ) {
                            let newCategory = category == "All" ? nil : category
                            selectedCategory = newCategory
                            onCategoryChange(newCategory)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.adaptiveCardBackground(for: colorScheme))
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct CategoryChip: View {
    let category: String
    let isSelected: Bool
    let action: () -> Void
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: categoryIcon(for: category))
                    .font(.caption)
                
                Text(category)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? theme.currentGradient.accentColor : Color.clear)
                    .overlay(
                        Capsule()
                            .stroke(
                                isSelected ? Color.clear : theme.currentGradient.accentColor.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            )
            .foregroundColor(
                isSelected ? .white : theme.currentGradient.accentColor
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "all": return "square.grid.2x2"
        case "food": return "fork.knife"
        case "transport": return "car.fill"
        case "shopping": return "bag.fill"
        case "entertainment": return "gamecontroller.fill"
        case "bills": return "doc.text.fill"
        case "health": return "heart.fill"
        default: return "questionmark"
        }
    }
}

struct ExpensesListCard: View {
    let groupedExpenses: [String: [Expense]]
    let onEdit: (Expense) -> Void
    let onDelete: (Expense) -> Void
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Expenses")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
            
            LazyVStack(spacing: 16) {
                ForEach(groupedExpenses.keys.sorted().reversed(), id: \.self) { dateKey in
                    VStack(alignment: .leading, spacing: 12) {
                        // Date Header
                        HStack {
                            Text(dateKey)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                            
                            Spacer()
                            
                            Text(CurrencyService.shared.formatAmount(
                                (groupedExpenses[dateKey] ?? []).reduce(0) { $0 + $1.amount },
                                currency: CurrencyService.shared.selectedCurrency
                            ))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.currentGradient.accentColor)
                        }
                        
                        // Expenses for this date
                        LazyVStack(spacing: 8) {
                            ForEach(groupedExpenses[dateKey] ?? []) { expense in
                                ModernExpenseRow(
                                    expense: expense,
                                    onEdit: { onEdit(expense) },
                                    onDelete: { onDelete(expense) }
                                )
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.adaptiveCardBackground(for: colorScheme))
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct ModernExpenseRow: View {
    let expense: Expense
    let onEdit: () -> Void
    let onDelete: () -> Void
    @StateObject private var currencyService = CurrencyService.shared
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Category Icon with theme-adaptive background
            ZStack {
                Circle()
                    .fill(theme.currentGradient.accentColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: categoryIcon(for: expense.category))
                    .font(.system(size: 18))
                    .foregroundColor(theme.currentGradient.accentColor)
            }
            
            // Expense Details
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(expense.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(theme.currentGradient.accentColor.opacity(0.1))
                        )
                        .foregroundColor(theme.currentGradient.accentColor)
                    
                    Text(DateFormatter.timeFormatter.string(from: expense.date))
                        .font(.caption)
                        .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                }
            }
            
            Spacer()
            
            // Amount
            Text(currencyService.formatAmount(expense.amount, currency: currencyService.selectedCurrency))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.adaptiveCardBackground(for: colorScheme).opacity(0.5))
        )
        .contextMenu {
            Button("Edit", systemImage: "pencil") { onEdit() }
            Button("Delete", systemImage: "trash", role: .destructive) { onDelete() }
        }
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "food": return "fork.knife"
        case "transport": return "car.fill"
        case "shopping": return "bag.fill"
        case "entertainment": return "gamecontroller.fill"
        case "bills": return "doc.text.fill"
        case "health": return "heart.fill"
        default: return "questionmark.circle.fill"
        }
    }
}

struct EmptyStateCard: View {
    let onAddExpense: () -> Void
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(theme.currentGradient.accentColor.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "tray")
                        .font(.system(size: 32))
                        .foregroundColor(theme.currentGradient.accentColor)
                }
                
                VStack(spacing: 8) {
                    Text("No expenses yet")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                    
                    Text("Start tracking your expenses by adding your first one")
                        .font(.subheadline)
                        .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                        .multilineTextAlignment(.center)
                }
            }
            
            Button(action: onAddExpense) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add First Expense")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [
                            theme.currentGradient.accentColor,
                            theme.currentGradient.secondaryColor
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(25)
                .shadow(color: theme.currentGradient.accentColor.opacity(0.4), radius: 12, x: 0, y: 6)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.adaptiveCardBackground(for: colorScheme))
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
        )
    }
}




struct EnhancedStatusBanner: View {
    @ObservedObject private var networkService = NetworkService.shared
    @ObservedObject private var syncService = OfflineSyncService.shared
    @ObservedObject private var currencyService = CurrencyService.shared
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var showDetails = false
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main status bar with enhanced design
            HStack(spacing: 16) {
                // Left: Enhanced Status with Animation
                HStack(spacing: 12) {
                    statusIcon
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(statusTitle)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(statusColor)
                        
                        Text(statusMessage)
                            .font(.caption2)
                            .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                    }
                }
                
                Spacer()
                
                // Center: Enhanced Currency with Theme Colors
                HStack(spacing: 6) {
                    Text(currencyService.selectedCurrency.symbol)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            theme.currentGradient.accentColor,
                                            theme.currentGradient.secondaryColor
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                    
                    Text(currencyService.selectedCurrency.rawValue.uppercased())
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(theme.currentGradient.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(theme.currentGradient.accentColor.opacity(0.1))
                                .overlay(
                                    Capsule()
                                        .stroke(theme.currentGradient.accentColor.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                
                // Right: Action Button with Theme Colors
                if syncService.isSyncing {
                    ZStack {
                        Circle()
                            .stroke(theme.currentGradient.accentColor.opacity(0.3), lineWidth: 2)
                            .frame(width: 28, height: 28)
                        
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(theme.currentGradient.accentColor)
                    }
                } else {
                    Button(action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            showDetails.toggle()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(theme.currentGradient.accentColor.opacity(0.1))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(theme.currentGradient.accentColor.opacity(0.3), lineWidth: 1)
                                )
                            
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(theme.currentGradient.accentColor)
                                .rotationEffect(.degrees(showDetails ? 180 : 0))
                        }
                    }
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseAnimation)
                    .onAppear {
                        if !networkService.isConnected {
                            pulseAnimation = true
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                // 🎯 FIXED: Theme-adaptive rectangle background
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        theme.currentGradient.accentColor.opacity(0.3),
                                        theme.currentGradient.secondaryColor.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .overlay(
                        // Animated border for offline state - now uses theme colors
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                networkService.isConnected ?
                                    theme.currentGradient.accentColor.opacity(0) :
                                    theme.currentGradient.secondaryColor.opacity(0.5),
                                lineWidth: 2
                            )
                            .scaleEffect(pulseAnimation ? 1.02 : 1.0)
                            .opacity(pulseAnimation ? 0.7 : 1.0)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseAnimation)
                    )
            )
            
            // Enhanced Details section
            if showDetails {
                EnhancedDetailsView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
        }
        .shadow(
            color: theme.currentGradient.accentColor.opacity(0.2),
            radius: showDetails ? 12 : 8,
            x: 0,
            y: 4
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showDetails)
    }
    
    private var statusIcon: some View {
        ZStack {
            // Background circle with theme colors
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            statusColor.opacity(0.2),
                            statusColor.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 36, height: 36)
            
            // Icon with enhanced styling
            Group {
                if networkService.isConnected {
                    if syncService.isSyncing {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(theme.currentGradient.accentColor)
                            .rotationEffect(.degrees(pulseAnimation ? 360 : 0))
                            .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: pulseAnimation)
                            .onAppear { pulseAnimation = true }
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(theme.currentGradient.accentColor) // 🎯 FIXED: Now uses theme color
                            .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)
                            .onAppear { pulseAnimation = true }
                    }
                } else {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.orange)
                        .symbolEffect(.pulse)
                }
            }
        }
    }
    
    private var statusTitle: String {
        if networkService.isConnected {
            return syncService.isSyncing ? "Syncing..." : "Online"
        } else {
            return "Offline"
        }
    }
    
    private var statusMessage: String {
        if networkService.isConnected {
            return syncService.isSyncing ? "Updating expenses..." : "All data synchronized"
        } else {
            return syncService.pendingChanges > 0 ?
                "\(syncService.pendingChanges) changes pending" :
                "Data saved locally"
        }
    }
    
    private var statusColor: Color {
        if networkService.isConnected {
            return syncService.isSyncing ? theme.currentGradient.accentColor : theme.currentGradient.accentColor
        } else {
            return .orange
        }
    }
}

// MARK: - Enhanced Details View with Theme Colors
struct EnhancedDetailsView: View {
    @StateObject private var theme = AppTheme.shared
    @ObservedObject private var syncService = OfflineSyncService.shared
    @ObservedObject private var networkService = NetworkService.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Connection Details")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.currentGradient.accentColor)
                
                Spacer()
                
                if syncService.pendingChanges > 0 {
                    Text("\(syncService.pendingChanges) pending")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(theme.currentGradient.secondaryColor.opacity(0.2))
                        )
                        .foregroundColor(theme.currentGradient.secondaryColor)
                }
            }
            
            if networkService.isConnected {
                DetailRow(
                    icon: "checkmark.circle.fill",
                    title: "Network Status",
                    value: "Connected",
                    color: theme.currentGradient.accentColor
                )
                
                DetailRow(
                    icon: "icloud.and.arrow.up",
                    title: "Sync Status",
                    value: syncService.isSyncing ? "Syncing..." : "Up to date",
                    color: theme.currentGradient.secondaryColor
                )
            } else {
                DetailRow(
                    icon: "wifi.slash",
                    title: "Network Status",
                    value: "Offline Mode",
                    color: .orange
                )
                
                DetailRow(
                    icon: "externaldrive",
                    title: "Local Storage",
                    value: "Data saved locally",
                    color: theme.currentGradient.accentColor
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.adaptiveCardBackground(for: colorScheme).opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.currentGradient.accentColor.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}


struct EnhancedDetailRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let showBadge: Bool
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Enhanced icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 24, height: 24)
                
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
            
            Spacer()
            
            HStack(spacing: 6) {
                Text(value)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                if showBadge {
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.adaptiveCardBackground(for: colorScheme).opacity(0.5))
        )
    }
}


// MARK: - DateFormatter Extension
extension DateFormatter {
    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter
    }()
    
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}


extension View {
    func glassCard(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
    }
    
    func glassBackground(corner: CGFloat = 16) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: corner)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: corner)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
    }
}

struct GlassChip: View {
    let label: String
    let systemImage: String?
    let tint: Color
    
    init(label: String, systemImage: String? = nil, tint: Color) {
        self.label = label
        self.systemImage = systemImage
        self.tint = tint
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = systemImage {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(label)
                .font(.caption2.weight(.semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(tint.opacity(0.3), lineWidth: 0.8)
                )
        )
        .foregroundColor(tint)
    }
}

struct categoryColor: View {
    let category: String
    
    var body: some View {
        Circle()
            .fill(categoryColor.opacity(0.2))
            .frame(width: 40, height: 40)
            .overlay(
                Image(systemName: categoryIcon)
                    .font(.system(size: 18))
                    .foregroundColor(categoryColor)
            )
    }
    
    private var categoryIcon: String {
        switch category.lowercased() {
        case "food": return "fork.knife"
        case "transport": return "car.fill"
        case "shopping": return "bag.fill"
        case "entertainment": return "gamecontroller.fill"
        case "bills": return "doc.text.fill"
        case "health": return "heart.fill"
        default: return "questionmark"
        }
    }
    
    private var categoryColor: Color {
        switch category.lowercased() {
        case "food": return .orange
        case "transport": return .blue
        case "shopping": return .purple
        case "entertainment": return .pink
        case "bills": return .red
        case "health": return .green
        default: return .gray
        }
    }
}



#Preview {
    ExpenseListView()
        
}
