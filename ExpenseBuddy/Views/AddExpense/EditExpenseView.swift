import SwiftUI

struct EditExpenseView: View {
    let expense: Expense
    @StateObject private var theme = AppTheme.shared
    @StateObject private var networkService = NetworkService.shared
    @StateObject private var currencyService = CurrencyService.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let onSave: () -> Void
    
    @State private var title: String
    @State private var amount: String
    @State private var category: String
    @State private var date: Date
    @State private var description: String
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    init(expense: Expense, onSave: @escaping () -> Void) {
        self.expense = expense
        self.onSave = onSave
        _title = State(initialValue: expense.title)
        _amount = State(initialValue: String(format: "%.2f", expense.amount))
        _category = State(initialValue: expense.category)
        _date = State(initialValue: expense.date)
        _description = State(initialValue: expense.description ?? "")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                GradientBackgroundView()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Enhanced Header Card
                        EditExpenseHeaderCard()
                        
                        // Form Fields Card
                        FormFieldsCard()
                        
                        // Error Message
                        if !errorMessage.isEmpty {
                            ErrorMessageCard()
                        }
                        
                        // Save Button
                        SaveButtonCard()
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Edit Expense")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(theme.currentGradient.accentColor)
                }
                
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
    }
    
    // MARK: - Enhanced Header Card
    private func EditExpenseHeaderCard() -> some View {
        HStack(spacing: 16) {
            // Edit Icon
            ZStack {
                Circle()
                    .fill(theme.currentGradient.accentColor.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "pencil.circle.fill")
                    .font(.title2)
                    .foregroundColor(theme.currentGradient.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Edit Expense")
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
            
            // Connection Status
            if !networkService.isConnected {
                VStack(spacing: 4) {
                    Circle()
                        .fill(.orange)
                        .frame(width: 8, height: 8)
                    
                    Text("Offline")
                        .font(.caption2)
                        .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                }
            } else {
                VStack(spacing: 4) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    
                    Text("Online")
                        .font(.caption2)
                        .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
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
    
    // MARK: - Form Fields Card
    private func FormFieldsCard() -> some View {
        VStack(spacing: 20) {
            // Title Field
            formField("Title") {
                TextField("Enter expense title", text: $title)
                    .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
            }
            
            // Amount Field
            formField("Amount (\(currencyService.selectedCurrency.symbol))") {
                TextField("0.00", text: $amount)
                    .keyboardType(.decimalPad)
                    .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
            }
            
            // Category Field
            formField("Category") {
                categoryPicker
            }
            
            // Date Field
            formField("Date") {
                DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .colorMultiply(theme.currentGradient.accentColor)
            }
            
            // Description Field
            formField("Description") {
                TextField("Add a note (optional)", text: $description, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
                    .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
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
    
    // MARK: - Helper Views
    private func formField<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: fieldIcon(for: label))
                    .font(.caption)
                    .foregroundColor(theme.currentGradient.accentColor)
                
                Text(label.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
            }
            
            content()
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.adaptiveCardBackground(for: colorScheme).opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(theme.currentGradient.accentColor.opacity(0.2), lineWidth: 1)
                        )
                )
        }
    }
    
    private func fieldIcon(for label: String) -> String {
        switch label.lowercased() {
        case "title": return "textformat"
        case let s where s.contains("amount"): return "dollarsign.circle"
        case "category": return "folder"
        case "date": return "calendar"
        case "description": return "text.alignleft"
        default: return "pencil"
        }
    }
    
    private var categoryPicker: some View {
        Menu {
            ForEach(["Food", "Transport", "Shopping", "Entertainment", "Bills", "Health", "Other"], id: \.self) { cat in
                Button {
                    category = cat
                } label: {
                    HStack {
                        Image(systemName: categoryIcon(for: cat))
                            .foregroundColor(categoryColor(for: cat))
                        Text(cat)
                        if category == cat {
                            Image(systemName: "checkmark")
                                .foregroundColor(theme.currentGradient.accentColor)
                        }
                    }
                }
            }
        } label: {
            HStack {
                if !category.isEmpty {
                    Image(systemName: categoryIcon(for: category))
                        .foregroundColor(categoryColor(for: category))
                }
                
                Text(category.isEmpty ? "Select category" : category)
                    .foregroundColor(category.isEmpty ? theme.adaptiveTextSecondary(for: colorScheme) : theme.adaptiveTextPrimary(for: colorScheme))
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
            }
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
        default: return theme.currentGradient.accentColor
        }
    }
    
    // MARK: - Error Message Card
    private func ErrorMessageCard() -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(errorMessage)
                .font(.subheadline)
                .foregroundColor(.red)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Save Button Card
    private func SaveButtonCard() -> some View {
        Button {
            Task {
                await saveExpense()
            }
        } label: {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.headline)
                    
                    Text("Update Expense")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
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
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(color: theme.currentGradient.accentColor.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .disabled(isLoading || !isFormValid)
        .opacity(isLoading || !isFormValid ? 0.6 : 1.0)
        .scaleEffect(isLoading ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isLoading)
    }
    
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !amount.isEmpty &&
        Double(amount) != nil &&
        Double(amount)! > 0 &&
        !category.isEmpty
    }
    
    private func saveExpense() async {
        guard isFormValid else {
            errorMessage = "Please fill all required fields with valid data"
            return
        }
        
        guard let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "Please enter a valid amount"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Update the expense
        let updatedExpense = Expense(
            id: expense.id,
            title: trimmedTitle,
            amount: amountValue,
            category: category,
            currency: currencyService.selectedCurrency.rawValue,
            date: date,
            description: trimmedDescription.isEmpty ? nil : trimmedDescription,
            syncedAt: nil // Mark as unsynced for offline support
        )
        
        // Save locally first
        CoreDataService.shared.saveExpenseLocally(updatedExpense)
        
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
                
                let serverExpense = try await ExpenseService.shared.updateExpense(id: expense.id, expense: expenseRequest)
                
                // Update with server data
                CoreDataService.shared.saveExpenseLocally(serverExpense)
                
            } catch {
                // If server update fails, keep the local version for later sync
                print("Failed to update on server, will sync later: \(error)")
            }
        }
        // After updating expense
        NotificationCenter.default.post(name: .expensesUpdated, object: nil)
        
        isLoading = false
        onSave()
        dismiss()
    }
}
