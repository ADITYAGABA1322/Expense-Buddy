import SwiftUI

struct AuthContainerView: View {
    @State private var showingRegister = false
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Enhanced Gradient Background
                GradientBackgroundView()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Enhanced Logo Section with better spacing
                        LogoSection()
                            .frame(minHeight: max(geometry.size.height * 0.35 - keyboardHeight * 0.3, 200))
                        
                        // Enhanced Form Section
                        FormSection()
                            .padding(.bottom, max(keyboardHeight, 20))
                    }
                    .frame(minHeight: geometry.size.height)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.3)) {
                    keyboardHeight = keyboardFrame.height
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.3)) {
                keyboardHeight = 0
            }
        }
    }
    
    // MARK: - Enhanced Logo Section with Breathing Animation
    private func LogoSection() -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Enhanced App Logo with Theme Integration + Breathing Effect
            ZStack {
                // Outer glow ring with breathing animation
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                theme.currentGradient.accentColor.opacity(0.4),
                                theme.currentGradient.secondaryColor.opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 90
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(keyboardHeight > 0 ? 0.8 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: keyboardHeight)
                
                // Main circle with beautiful gradient
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.adaptiveCardBackground(for: colorScheme),
                                theme.adaptiveCardBackground(for: colorScheme).opacity(0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110, height: 110)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        theme.currentGradient.accentColor.opacity(0.4),
                                        theme.currentGradient.secondaryColor.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.4 : 0.15), radius: 15, x: 0, y: 8)
                    .scaleEffect(keyboardHeight > 0 ? 0.8 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: keyboardHeight)
                
                // Inner circle with theme-adaptive icon
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
                    .frame(width: 85, height: 85)
                    .overlay(
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: keyboardHeight > 0 ? 32 : 42, weight: .medium))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                            .animation(.easeInOut(duration: 0.3), value: keyboardHeight)
                    )
                    .shadow(color: theme.currentGradient.accentColor.opacity(0.5), radius: 20, x: 0, y: 10)
                    .scaleEffect(keyboardHeight > 0 ? 0.8 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: keyboardHeight)
            }
            
            // Enhanced App Title with keyboard responsiveness
            VStack(spacing: keyboardHeight > 0 ? 4 : 8) {
                Text("ExpenseBuddy")
                    .font(.system(size: keyboardHeight > 0 ? 28 : 34, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                theme.adaptiveTextPrimary(for: colorScheme),
                                theme.adaptiveTextPrimary(for: colorScheme).opacity(0.8)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 4, x: 0, y: 2)
                    .animation(.easeInOut(duration: 0.3), value: keyboardHeight)
                
                if keyboardHeight == 0 {
                    Text("Smart expense tracking made simple")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: keyboardHeight)
            
            Spacer()
        }
    }
    
    // Rest of your existing code remains the same...
    private func FormSection() -> some View {
        VStack(spacing: 24) {
            Group {
                if showingRegister {
                    RegisterFormView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                } else {
                    LoginFormView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                }
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingRegister)
            
            ToggleAuthButton()
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }
    
    private func ToggleAuthButton() -> some View {
        Button {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showingRegister.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Text(showingRegister ? "Already have an account?" : "Don't have an account?")
                    .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                
                Text(showingRegister ? "Sign In" : "Sign Up")
                    .fontWeight(.semibold)
                    .foregroundColor(theme.currentGradient.accentColor)
            }
            .font(.subheadline)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(theme.adaptiveCardBackground(for: colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
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
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(showingRegister ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: showingRegister)
    }
}


// MARK: - Enhanced Login Form
struct LoginFormView: View {
    @StateObject private var viewModel = AuthViewModel()
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Welcome Header
            VStack(spacing: 8) {
                Text("Welcome Back")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                
                Text("Sign in to continue tracking your expenses")
                    .font(.subheadline)
                    .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 8)
            
            // Enhanced Email Field
            EnhancedInputField(
                title: "Email Address",
                text: $email,
                placeholder: "Enter your email",
                icon: "envelope.fill",
                keyboardType: .emailAddress
            )
            
            // Enhanced Password Field
            EnhancedPasswordField(
                title: "Password",
                text: $password,
                placeholder: "Enter your password",
                isVisible: $isPasswordVisible
            )
            
            // Error Message
            if !viewModel.errorMessage.isEmpty {
                ErrorMessageView(message: viewModel.errorMessage)
            }
            
            // Enhanced Sign In Button
            EnhancedActionButton(
                title: "Sign In",
                isLoading: viewModel.isLoading,
                isEnabled: !email.isEmpty && !password.isEmpty,
                colors: [theme.currentGradient.accentColor, theme.currentGradient.secondaryColor]
            ) {
                Task {
                    await viewModel.login(email: email, password: password)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(theme.adaptiveCardBackground(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
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
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.4 : 0.15), radius: 20, x: 0, y: 10)
        )
    }
}

// MARK: - Enhanced Register Form
struct RegisterFormView: View {
    @StateObject private var viewModel = AuthViewModel()
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    
    var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        password == confirmPassword &&
        password.count >= 6
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Welcome Header
            VStack(spacing: 8) {
                Text("Create Account")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                
                Text("Join ExpenseBuddy to start tracking your expenses")
                    .font(.subheadline)
                    .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 8)
            
            // Name Fields Row
            HStack(spacing: 12) {
                EnhancedInputField(
                    title: "First Name",
                    text: $firstName,
                    placeholder: "First",
                    icon: "person.fill",
                    isCompact: true
                )
                
                EnhancedInputField(
                    title: "Last Name",
                    text: $lastName,
                    placeholder: "Last",
                    icon: "person.fill",
                    isCompact: true
                )
            }
            
            // Enhanced Email Field
            EnhancedInputField(
                title: "Email Address",
                text: $email,
                placeholder: "Enter your email",
                icon: "envelope.fill",
                keyboardType: .emailAddress
            )
            
            // Enhanced Password Fields
            EnhancedPasswordField(
                title: "Password",
                text: $password,
                placeholder: "Create a password",
                isVisible: $isPasswordVisible
            )
            
            EnhancedPasswordField(
                title: "Confirm Password",
                text: $confirmPassword,
                placeholder: "Confirm your password",
                isVisible: $isConfirmPasswordVisible
            )
            
            // Password validation
            if !password.isEmpty && password.count < 6 {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.orange)
                    Text("Password must be at least 6 characters")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                }
            }
            
            if !confirmPassword.isEmpty && password != confirmPassword {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text("Passwords don't match")
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                }
            }
            
            // Error Message
            if !viewModel.errorMessage.isEmpty {
                ErrorMessageView(message: viewModel.errorMessage)
            }
            
            // Enhanced Create Account Button
            EnhancedActionButton(
                title: "Create Account",
                isLoading: viewModel.isLoading,
                isEnabled: isFormValid,
                colors: [.green, theme.currentGradient.accentColor]
            ) {
                Task {
                    await viewModel.register(
                        email: email,
                        password: password,
                        firstName: firstName,
                        lastName: lastName
                    )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(theme.adaptiveCardBackground(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.green.opacity(0.2),
                                    theme.currentGradient.accentColor.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.4 : 0.15), radius: 20, x: 0, y: 10)
        )
    }
}



// MARK: - Enhanced Input Field Component with Better Animations
struct EnhancedInputField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var isCompact: Bool = false
    
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool
    @State private var hasContent: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Field Label with animation
            HStack(spacing: 6) {
                if !isCompact {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(isFocused ? theme.currentGradient.accentColor : theme.adaptiveTextSecondary(for: colorScheme))
                        .scaleEffect(isFocused ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
                }
                
                Text(title.uppercased())
                    .font(isCompact ? .caption2 : .caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isFocused ? theme.currentGradient.accentColor : theme.adaptiveTextSecondary(for: colorScheme))
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
            }
            
            // Input Field Container
            HStack(spacing: 12) {
                if !isCompact {
                    Image(systemName: icon)
                        .foregroundColor(isFocused ? theme.currentGradient.accentColor : theme.adaptiveTextSecondary(for: colorScheme))
                        .frame(width: 20)
                        .scaleEffect(isFocused ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
                }
                
                TextField(placeholder, text: $text)
                    .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .words)
                    .keyboardType(keyboardType)
                    .autocorrectionDisabled(keyboardType == .emailAddress)
                    .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                    .focused($isFocused)
                    .onChange(of: text) { newValue in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            hasContent = !newValue.isEmpty
                        }
                    }
                
                // Success Checkmark when field has valid content
                if hasContent && isValidContent {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.subheadline)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.adaptiveCardBackground(for: colorScheme).opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                strokeColor,
                                lineWidth: isFocused ? 2 : 1
                            )
                    )
                    .shadow(
                        color: isFocused ? theme.currentGradient.accentColor.opacity(0.2) : .clear,
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                    .scaleEffect(isFocused ? 1.02 : 1.0)
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
        }
    }
    
    private var isValidContent: Bool {
        if keyboardType == .emailAddress {
            return text.contains("@") && text.contains(".")
        }
        return !text.isEmpty
    }
    
    private var strokeColor: Color {
        if isFocused {
            return theme.currentGradient.accentColor
        } else if hasContent && isValidContent {
            return .green.opacity(0.5)
        } else {
            return theme.currentGradient.accentColor.opacity(0.2)
        }
    }
}



// MARK: - Enhanced Password Field with Strength Indicator
struct EnhancedPasswordField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    @Binding var isVisible: Bool
    var showStrengthIndicator: Bool = false
    
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool
    @State private var hasContent: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Field Label
            HStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundColor(isFocused ? theme.currentGradient.accentColor : theme.adaptiveTextSecondary(for: colorScheme))
                    .scaleEffect(isFocused ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
                
                Text(title.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isFocused ? theme.currentGradient.accentColor : theme.adaptiveTextSecondary(for: colorScheme))
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
                
                Spacer()
                
                // Password Strength Indicator
                if showStrengthIndicator && hasContent {
                    PasswordStrengthIndicator(password: text)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            
            // Password Input Container
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .foregroundColor(isFocused ? theme.currentGradient.accentColor : theme.adaptiveTextSecondary(for: colorScheme))
                    .frame(width: 20)
                    .scaleEffect(isFocused ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
                
                Group {
                    if isVisible {
                        TextField(placeholder, text: $text)
                    } else {
                        SecureField(placeholder, text: $text)
                    }
                }
                .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                .focused($isFocused)
                .onChange(of: text) { newValue in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        hasContent = !newValue.isEmpty
                    }
                }
                
                // Visibility Toggle with Animation
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isVisible.toggle()
                    }
                } label: {
                    Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                        .font(.subheadline)
                        .scaleEffect(isVisible ? 1.1 : 1.0)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Success Checkmark
                if hasContent && text.count >= 6 {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.subheadline)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.adaptiveCardBackground(for: colorScheme).opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                strokeColor,
                                lineWidth: isFocused ? 2 : 1
                            )
                    )
                    .shadow(
                        color: isFocused ? theme.currentGradient.accentColor.opacity(0.2) : .clear,
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                    .scaleEffect(isFocused ? 1.02 : 1.0)
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
        }
    }
    
    private var strokeColor: Color {
        if isFocused {
            return theme.currentGradient.accentColor
        } else if hasContent && text.count >= 6 {
            return .green.opacity(0.5)
        } else {
            return theme.currentGradient.accentColor.opacity(0.2)
        }
    }
}

// MARK: - Password Strength Indicator
struct PasswordStrengthIndicator: View {
    let password: String
    
    private var strength: PasswordStrength {
        if password.count < 6 { return .weak }
        if password.count >= 8 && password.rangeOfCharacter(from: .decimalDigits) != nil && password.rangeOfCharacter(from: .uppercaseLetters) != nil {
            return .strong
        }
        return .medium
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Rectangle()
                    .fill(colorForIndex(index))
                    .frame(width: 20, height: 3)
                    .cornerRadius(1.5)
                    .scaleEffect(index <= strength.rawValue ? 1.0 : 0.5)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: strength)
            }
            
            Text(strength.description)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(strength.color)
        }
    }
    
    private func colorForIndex(_ index: Int) -> Color {
        if index <= strength.rawValue {
            return strength.color
        }
        return Color.gray.opacity(0.3)
    }
}

enum PasswordStrength: Int, CaseIterable {
    case weak = 0
    case medium = 1
    case strong = 2
    
    var description: String {
        switch self {
        case .weak: return "Weak"
        case .medium: return "Good"
        case .strong: return "Strong"
        }
    }
    
    var color: Color {
        switch self {
        case .weak: return .red
        case .medium: return .orange
        case .strong: return .green
        }
    }
}

// MARK: - Enhanced Action Button Component
struct EnhancedActionButton: View {
    let title: String
    let isLoading: Bool
    let isEnabled: Bool
    let colors: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: title == "Sign In" ? "arrow.right.circle.fill" : "person.badge.plus.fill")
                        .font(.headline)
                    
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(color: colors.first?.opacity(0.4) ?? .clear, radius: 15, x: 0, y: 8)
        }
        .disabled(!isEnabled || isLoading)
        .opacity(!isEnabled ? 0.6 : 1.0)
        .scaleEffect(isLoading ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isLoading)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

// MARK: - Error Message Component
struct ErrorMessageView: View {
    let message: String
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.subheadline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.red)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
