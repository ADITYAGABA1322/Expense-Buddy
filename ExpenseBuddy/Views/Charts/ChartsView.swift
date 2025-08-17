import SwiftUI
import Charts

struct ChartsView: View {
    @State private var summary: ExpenseSummary?
    @State private var selectedTimeRange: TimeRange = .thisMonth
    @StateObject private var currencyService = CurrencyService.shared
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    enum TimeRange: String, CaseIterable {
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case thisYear = "This Year"
        case allTime = "All Time"
    }
    
    enum ChartType: String, CaseIterable {
        case pie = "Pie Chart"
        case bar = "Bar Chart"
        case line = "Line Chart"
    }
    
    @State private var chartType: ChartType = .pie
    
    var body: some View {
        NavigationView {
            ZStack {
                GradientBackgroundView()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Enhanced Analytics Header
                        AnalyticsHeaderCard()
                        
                        // Time Range & Chart Type Selectors
                        ControlsCard(
                            selectedTimeRange: $selectedTimeRange,
                            chartType: $chartType
                        )
                        
                        if let summary = summary, summary.totalCount > 0 {
                            // Total Amount Card
                            EnhancedTotalAmountCard(summary: summary)
                            
                            // Main Chart
                            EnhancedChartContainerView(
                                summary: summary,
                                chartType: chartType
                            )
                            
                            // Category Breakdown
                            EnhancedCategoryBreakdownView(summary: summary)
                            
                            // Monthly Trend (if available)
                            if !summary.monthlyTrend.isEmpty && chartType == .line {
                                MonthlyTrendExplanationView()
                                EnhancedMonthlyTrendView(monthlyData: summary.monthlyTrend)
                            }
                        } else {
                            EmptyChartView()
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                // Theme Button (matching ExpenseListView)
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
        }
        .onAppear {
            computeSummary()
        }
        .onChange(of: selectedTimeRange) { _ in
            computeSummary()
        }
        .onChange(of: currencyService.selectedCurrency) { _ in
            computeSummary()
        }
        .onReceive(NotificationCenter.default.publisher(for: .expensesUpdated)) { _ in
            DispatchQueue.main.async {
                computeSummary()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .currencyChanged)) { _ in
            computeSummary()
        }
    }
    
    // MARK: - Local Summary (no network, no loading)
    private func computeSummary() {
        let (start, end) = dateRange(for: selectedTimeRange)
        let localExpenses = CoreDataService.shared.fetchLocalExpenses()
        
        print("📊 ChartsView: Found \(localExpenses.count) expenses")
        
        // Filter by range
        let filtered = localExpenses.filter { e in
            let afterStart = start.map { e.date >= $0 } ?? true
            let beforeEnd  = end.map { e.date <= $0 } ?? true
            return afterStart && beforeEnd
        }
        
        // Convert amounts to selected currency
        let converted: [(Expense, Double)] = filtered.map { e in
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
        
        // Monthly trend (bucket to month start)
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
    
    private func dateRange(for range: TimeRange) -> (Date?, Date?) {
        let cal = Calendar.current
        let now = Date()
        switch range {
        case .thisWeek:
            let start = cal.dateInterval(of: .weekOfYear, for: now)?.start
            return (start, now)
        case .thisMonth:
            let start = cal.dateInterval(of: .month, for: now)?.start
            return (start, now)
        case .thisYear:
            let start = cal.dateInterval(of: .year, for: now)?.start
            return (start, now)
        case .allTime:
            return (nil, nil)
        }
    }
}

// MARK: - Analytics Header Card (New)
struct AnalyticsHeaderCard: View {
    @StateObject private var theme = AppTheme.shared
    @StateObject private var currencyService = CurrencyService.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Analytics Icon
            ZStack {
                Circle()
                    .fill(theme.currentGradient.accentColor.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "chart.pie.fill")
                    .font(.title2)
                    .foregroundColor(theme.currentGradient.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Expense Analytics")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                
                HStack(spacing: 8) {
                    Text("Currency:")
                        .font(.caption)
                        .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                    
                    Text(currencyService.selectedCurrency.rawValue.uppercased())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.currentGradient.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(theme.currentGradient.accentColor.opacity(0.1))
                        )
                }
            }
            
            Spacer()
            
            // Real-time indicator
            VStack(spacing: 4) {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
                
                Text("Live")
                    .font(.caption2)
                    .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
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

// MARK: - Controls Card (New)
struct ControlsCard: View {
    @Binding var selectedTimeRange: ChartsView.TimeRange
    @Binding var chartType: ChartsView.ChartType
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            // Time Range Picker
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(theme.currentGradient.accentColor)
                    
                    Text("Time Period")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                    
                    Spacer()
                }
                
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(ChartsView.TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .colorMultiply(theme.currentGradient.accentColor)
            }
            
            // Chart Type Picker
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.caption)
                        .foregroundColor(theme.currentGradient.accentColor)
                    
                    Text("Chart Style")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                    
                    Spacer()
                }
                
                Picker("Chart Type", selection: $chartType) {
                    ForEach(ChartsView.ChartType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .colorMultiply(theme.currentGradient.accentColor)
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

// MARK: - Enhanced Total Amount Card (Updated with theme)
struct EnhancedTotalAmountCard: View {
    let summary: ExpenseSummary
    @StateObject private var currencyService = CurrencyService.shared
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with currency info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Expenses")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                    
                    Text("in \(currencyService.selectedCurrency.name)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(theme.currentGradient.accentColor.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(theme.currentGradient.accentColor)
                }
                
                Spacer()
                
                // Trend indicator
                ZStack {
                    Circle()
                        .fill(theme.currentGradient.accentColor.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.headline)
                        .foregroundColor(theme.currentGradient.accentColor)
                }
            }
            
            // Main amount
            Text(formatCurrencyAmount(summary.totalAmount))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            
            // Statistics row
            HStack(spacing: 20) {
                StatisticView(
                    title: "Transactions",
                    value: "\(summary.totalCount)",
                    icon: "number",
                    color: theme.currentGradient.accentColor
                )
                
                if summary.totalCount > 0 {
                    StatisticView(
                        title: "Average",
                        value: formatCurrencyAmount(summary.totalAmount / Double(summary.totalCount)),
                        icon: "chart.line.uptrend.xyaxis",
                        color: theme.currentGradient.secondaryColor
                    )
                }
                
                StatisticView(
                    title: "Categories",
                    value: "\(summary.categoryBreakdown.count)",
                    icon: "folder",
                    color: theme.currentGradient.accentColor
                )
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
    }
    
    private func formatCurrencyAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyService.selectedCurrency.rawValue
        formatter.maximumFractionDigits = amount >= 1000 ? 0 : 2
        if amount >= 1_000_000 {
            return "\(currencyService.selectedCurrency.symbol)\(String(format: "%.1fM", amount / 1_000_000))"
        } else if amount >= 1_000 {
            return "\(currencyService.selectedCurrency.symbol)\(String(format: "%.1fK", amount / 1_000))"
        } else {
            return formatter.string(from: NSNumber(value: amount)) ?? "\(currencyService.selectedCurrency.symbol)\(amount)"
        }
    }
}

struct StatisticView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
                .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
            
            Text(title)
                .font(.caption2)
                .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Enhanced Chart Container (Updated with theme)
struct EnhancedChartContainerView: View {
    let summary: ExpenseSummary
    let chartType: ChartsView.ChartType
    @State private var selectedCategory: String? = nil
    @StateObject private var currencyService = CurrencyService.shared
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Expenses by Category")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                    
                    Text("Interactive visualization")
                        .font(.caption)
                        .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                }
                
                Spacer()
                
                // Chart type indicator
                Text(chartType.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(theme.currentGradient.accentColor.opacity(0.1))
                            .overlay(
                                Capsule()
                                    .stroke(theme.currentGradient.accentColor.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .foregroundColor(theme.currentGradient.accentColor)
            }
            
            // Chart content
            Group {
                switch chartType {
                case .pie:
                    EnhancedPieChartView(
                        categoryData: summary.categoryBreakdown,
                        selectedCategory: $selectedCategory
                    )
                case .bar:
                    EnhancedBarChartView(categoryData: summary.categoryBreakdown)
                case .line:
                    if !summary.monthlyTrend.isEmpty {
                        EnhancedLineChartView(monthlyData: summary.monthlyTrend)
                    } else {
                        NoDataView(message: "Not enough data for trend analysis")
                    }
                }
            }
            .frame(height: 300)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.adaptiveCardBackground(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
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
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 12, x: 0, y: 6)
        )
    }
}

// MARK: - Enhanced Pie Chart (Updated with theme colors)
struct EnhancedPieChartView: View {
    let categoryData: [CategoryBreakdown]
    @Binding var selectedCategory: String?
    @State private var selectedAngle: Double?
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    private var data: [CategoryBreakdown] { Array(categoryData.prefix(8)) }
    private var total: Double {
        let t = data.reduce(0){ $0 + $1._sum.amount }
        return t == 0 ? 1 : t
    }
    
    var body: some View {
        ZStack {
            pieCore
            centerInfo
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCategory = nil
                selectedAngle = nil
            }
        }
    }
    
    private var pieCore: some View {
        Chart(data, id: \.category) { item in
            let sel = (item.category == selectedCategory)
            SectorMark(
                angle: .value("Amount", item._sum.amount),
                innerRadius: .ratio(sel ? 0.32 : 0.5),
                outerRadius: .ratio(sel ? 0.98 : 0.94)
            )
            .foregroundStyle(color(for: item.category))
        }
        .chartLegend(.hidden)
        .chartAngleSelection(value: $selectedAngle)
        .onChange(of: selectedAngle) { angle in
            guard let angle else {
                selectedCategory = nil
                return
            }
            selectedCategory = categoryFor(angle)
        }
    }
    
    private var centerInfo: some View {
        VStack(spacing: 4) {
            if let sel = selectedCategory,
               let item = data.first(where: { $0.category == sel }) {
                Text(sel)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                Text(format(item._sum.amount))
                    .font(.caption2)
                    .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
            } else {
                Text("Total")
                    .font(.caption)
                    .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                Text(format(data.reduce(0){ $0 + $1._sum.amount }))
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.adaptiveCardBackground(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.currentGradient.accentColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func categoryFor(_ angle: Double) -> String? {
        var start: Double = 0
        for item in data {
            let span = (item._sum.amount / total) * 360
            if angle >= start && angle < start + span { return item.category }
            start += span
        }
        return nil
    }
    
    private func format(_ v: Double) -> String {
        CurrencyService.shared.formatAmount(v, currency: CurrencyService.shared.selectedCurrency)
    }
    
    private func color(for category: String) -> Color {
        switch category.lowercased() {
        case "food": return .orange
        case "transport": return .blue
        case "shopping": return .purple
        case "entertainment": return .pink
        case "bills": return .red
        case "health": return .green
        default: return theme.currentGradient.accentColor
        }
    }
}

// MARK: - Enhanced Bar Chart (Updated with theme)
struct EnhancedBarChartView: View {
    let categoryData: [CategoryBreakdown]
    @StateObject private var currencyService = CurrencyService.shared
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Chart(categoryData.sorted { $0._sum.amount > $1._sum.amount }) { item in
            BarMark(
                x: .value("Category", item.category),
                y: .value("Amount", item._sum.amount)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        color(for: item.category),
                        color(for: item.category).opacity(0.7)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(6)
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(formatAxisAmount(amount))
                            .font(.caption2)
                            .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                    }
                }
                AxisGridLine()
                AxisTick()
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let category = value.as(String.self) {
                        Text(category)
                            .font(.caption2)
                            .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                            .rotationEffect(.degrees(-45))
                    }
                }
                AxisGridLine()
                AxisTick()
            }
        }
    }
    
    private func color(for category: String) -> Color {
        switch category.lowercased() {
        case "food": return .orange
        case "transport": return .blue
        case "shopping": return .purple
        case "entertainment": return .pink
        case "bills": return .red
        case "health": return .green
        default: return theme.currentGradient.accentColor
        }
    }
    
    private func formatAxisAmount(_ amount: Double) -> String {
        if amount >= 1000 {
            return "\(currencyService.selectedCurrency.symbol)\(Int(amount/1000))K"
        } else {
            return "\(currencyService.selectedCurrency.symbol)\(Int(amount))"
        }
    }
}

// MARK: - Enhanced Line Chart (Updated with theme)
struct EnhancedLineChartView: View {
    let monthlyData: [MonthlyTrend]
    @StateObject private var currencyService = CurrencyService.shared
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Chart(monthlyData) { item in
            LineMark(
                x: .value("Month", item.date),
                y: .value("Amount", item._sum.amount)
            )
            .foregroundStyle(theme.currentGradient.accentColor)
            .lineStyle(StrokeStyle(lineWidth: 3))
            .symbol(Circle().strokeBorder(lineWidth: 2))
            
            AreaMark(
                x: .value("Month", item.date),
                y: .value("Amount", item._sum.amount)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        theme.currentGradient.accentColor.opacity(0.3),
                        theme.currentGradient.accentColor.opacity(0.1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(formatAxisAmount(amount))
                            .font(.caption2)
                            .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                    }
                }
                AxisGridLine()
                AxisTick()
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(DateFormatter.monthYearFormatter.string(from: date))
                            .font(.caption2)
                            .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                    }
                }
                AxisGridLine()
                AxisTick()
            }
        }
        .chartYScale(domain: 0...(monthlyData.map { $0._sum.amount }.max() ?? 1000) * 1.1)
    }
    
    private func formatAxisAmount(_ amount: Double) -> String {
        if amount >= 1000 {
            return "\(currencyService.selectedCurrency.symbol)\(Int(amount/1000))K"
        } else {
            return "\(currencyService.selectedCurrency.symbol)\(Int(amount))"
        }
    }
}

// MARK: - Enhanced Category Breakdown (Updated with theme)
struct EnhancedCategoryBreakdownView: View {
    let summary: ExpenseSummary
    @StateObject private var currencyService = CurrencyService.shared
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Category Breakdown")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                
                Spacer()
                
                Text("\(summary.categoryBreakdown.count) categories")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.currentGradient.accentColor.opacity(0.1))
                    .cornerRadius(8)
                    .foregroundColor(theme.currentGradient.accentColor)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(summary.categoryBreakdown.sorted { $0._sum.amount > $1._sum.amount }) { item in
                    CategoryBreakdownRow(
                        category: item.category,
                        amount: item._sum.amount,
                        count: item._count,
                        percentage: summary.totalAmount > 0 ? (item._sum.amount / summary.totalAmount) * 100 : 0
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.adaptiveCardBackground(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
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
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 12, x: 0, y: 6)
        )
    }
}

// MARK: - Enhanced Monthly Trend View (Updated with theme)
struct EnhancedMonthlyTrendView: View {
    let monthlyData: [MonthlyTrend]
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Monthly Trend")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                
                Spacer()
                
                Text("\(monthlyData.count) months")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.currentGradient.accentColor.opacity(0.1))
                    .cornerRadius(8)
                    .foregroundColor(theme.currentGradient.accentColor)
            }
            
            EnhancedLineChartView(monthlyData: monthlyData)
                .frame(height: 200)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.adaptiveCardBackground(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
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
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 12, x: 0, y: 6)
        )
    }
}

// MARK: - Monthly Trend Explanation (Updated with theme)
struct MonthlyTrendExplanationView: View {
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(theme.currentGradient.accentColor)
                
                Text("What is Monthly Trend?")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                BulletPoint(text: "Shows your spending pattern over time")
                BulletPoint(text: "Helps identify seasonal spending habits")
                BulletPoint(text: "Compare expenses across different months")
                BulletPoint(text: "Track if you're spending more or less over time")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.currentGradient.accentColor.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.currentGradient.accentColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct BulletPoint: View {
    let text: String
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(theme.currentGradient.accentColor)
                .fontWeight(.bold)
            
            Text(text)
                .font(.caption)
                .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Category Breakdown Row (Updated with theme)
struct CategoryBreakdownRow: View {
    let category: String
    let amount: Double
    let count: Int
    let percentage: Double
    @StateObject private var currencyService = CurrencyService.shared
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            CategoryIconView(category: category)
            
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                
                Text("\(count) transactions")
                    .font(.caption)
                    .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(currencyService.formatAmount(amount, currency: currencyService.selectedCurrency))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                
                Text("\(percentage, specifier: "%.1f")%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.currentGradient.accentColor)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.adaptiveCardBackground(for: colorScheme).opacity(0.5))
        )
    }
}

// MARK: - Category Icon View (Add this or update existing one)
struct CategoryIconView: View {
    let category: String
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            Circle()
                .fill(categoryColor(for: category).opacity(0.1))
                .frame(width: 40, height: 40)
            
            Image(systemName: categoryIcon(for: category))
                .font(.system(size: 18))
                .foregroundColor(categoryColor(for: category))
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
    
    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "food": return .orange
        case "transport": return .blue
        case "shopping": return .purple
        case "entertainment": return .pink
        case "bills": return .red
        case "health": return .green
        default: return theme.currentGradient.accentColor // THIS IS THE KEY CHANGE
        }
    }
}


// MARK: - No Data View (Updated with theme)
struct NoDataView: View {
    let message: String
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty Chart View (Updated with theme)
struct EmptyChartView: View {
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(theme.currentGradient.accentColor.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "chart.pie")
                    .font(.system(size: 32))
                    .foregroundColor(theme.currentGradient.accentColor)
            }
            
            VStack(spacing: 8) {
                Text("No data available")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                
                Text("Add some expenses to see your analytics")
                    .font(.subheadline)
                    .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
        .padding(.vertical, 40)
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

// MARK: - Helpers
extension Currency {
    var accentColor: Color {
        switch self {
        case .usd: return .green
        case .eur: return .blue
        case .jpy: return .red
        case .inr: return .orange
        }
    }
}

extension DateFormatter {
    static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yy"
        return formatter
    }()
}

extension Notification.Name {
    static let expensesUpdated = Notification.Name("expensesUpdated")
}

extension View {
    func glassBackground(corner: CGFloat = 18, strokeOpacity: Double = 0.08) -> some View {
        background(
            RoundedRectangle(cornerRadius: corner)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: corner)
                        .stroke(Color.white.opacity(strokeOpacity), lineWidth: 1)
                )
        )
    }
}
