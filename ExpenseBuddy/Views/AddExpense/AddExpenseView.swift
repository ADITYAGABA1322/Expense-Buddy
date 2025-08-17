import SwiftUI

struct AddExpenseView: View {
    @StateObject private var theme = AppTheme.shared
    @StateObject private var viewModel = AddExpenseViewModel()
    @StateObject private var networkService = NetworkService.shared
    @StateObject private var currencyService = CurrencyService.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let onSave: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                GradientBackgroundView()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Enhanced Header Card
                        AddExpenseHeaderCard()
                        
                        // Form Fields Card
                        FormFieldsCard()
                        
                        // Error Message
                        if !viewModel.errorMessage.isEmpty {
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
            .navigationTitle("Add Expense")
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
    private func AddExpenseHeaderCard() -> some View {
        HStack(spacing: 16) {
            // Add Icon
            ZStack {
                Circle()
                    .fill(theme.currentGradient.accentColor.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(theme.currentGradient.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("New Expense")
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
            CustomInputField(
                title: "Expense Title",
                text: $viewModel.title,
                placeholder: "Enter expense title",
                icon: "textformat"
            )
            
            // Amount Field
            CustomInputField(
                title: "Amount (\(currencyService.selectedCurrency.symbol))",
                text: $viewModel.amount,
                placeholder: "0.00",
                icon: "dollarsign.circle",
                keyboardType: .decimalPad
            )
            
            // Category Selector
            CategorySelectorView()
            
            // Date Picker
            DatePickerField()
            
            // Description Field
            CustomInputField(
                title: "Description (Optional)",
                text: $viewModel.description,
                placeholder: "Add a note about this expense",
                icon: "text.alignleft",
                isMultiline: true
            )
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
    
    // MARK: - Custom Input Field
    private func CustomInputField(
        title: String,
        text: Binding<String>,
        placeholder: String,
        icon: String,
        keyboardType: UIKeyboardType = .default,
        isMultiline: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(theme.currentGradient.accentColor)
                
                Text(title.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
            }
            
            if isMultiline {
                TextField(placeholder, text: text, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
                    .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
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
            } else {
                TextField(placeholder, text: text)
                    .keyboardType(keyboardType)
                    .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
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
    }
    
    // MARK: - Category Selector
    private func CategorySelectorView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "folder")
                    .font(.caption)
                    .foregroundColor(theme.currentGradient.accentColor)
                
                Text("CATEGORY")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(["Food", "Transport", "Shopping", "Entertainment", "Bills", "Health", "Other"], id: \.self) { category in
                    CategoryButton(category: category)
                }
            }
        }
    }
    
    private func CategoryButton(category: String) -> some View {
        let isSelected = viewModel.category == category
        
        return Button(action: {
            viewModel.category = category
        }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(categoryColor(for: category).opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: categoryIcon(for: category))
                        .font(.system(size: 16))
                        .foregroundColor(categoryColor(for: category))
                }
                
                Text(category)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected ?
                        theme.currentGradient.accentColor.opacity(0.2) :
                        theme.adaptiveCardBackground(for: colorScheme).opacity(0.5)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? theme.currentGradient.accentColor : theme.currentGradient.accentColor.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
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
    
    // MARK: - Date Picker
    private func DatePickerField() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(theme.currentGradient.accentColor)
                
                Text("DATE")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
            }
            
            DatePicker("Date", selection: $viewModel.date, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(CompactDatePickerStyle())
                .colorMultiply(theme.currentGradient.accentColor)
                .frame(maxWidth: .infinity, alignment: .leading)
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
    
    // MARK: - Error Message Card
    private func ErrorMessageCard() -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(viewModel.errorMessage)
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
                let success = await viewModel.saveExpense()
                if success {
                    NotificationCenter.default.post(name: .expensesUpdated, object: nil)
                    onSave()
                    dismiss()
                }
            }
        } label: {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.headline)
                    
                    Text("Save Expense")
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
        .disabled(viewModel.isLoading || !viewModel.isFormValid)
        .opacity(viewModel.isLoading || !viewModel.isFormValid ? 0.6 : 1.0)
        .scaleEffect(viewModel.isLoading ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: viewModel.isLoading)
    }
}
