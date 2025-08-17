import Foundation
import SwiftUI
import Combine

struct ProfileView: View {
    @StateObject private var authService = AuthService.shared
    @StateObject private var currencyService = CurrencyService.shared
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                GradientBackgroundView()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Enhanced Profile Header with Avatar
                        ProfileAvatarCard()
                        
                        // Quick Stats Card
                        ProfileStatsCard()
                        
                        // User Info Card
                        if let user = authService.user {
                            UserInfoCard(user: user)
                        }
                        
                        // Preferences Card
                        PreferencesCard()
                        
                        // App Info Card
                        AppInfoCard()
                        
                        // Sign Out Section (Better Design)
                        SignOutCard()
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
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
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authService.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out? Your data will remain safe.")
            }
        }
    }
    
    // MARK: - Enhanced Profile Avatar Card
    private func ProfileAvatarCard() -> some View {
        VStack(spacing: 16) {
            // Large Avatar with Gradient Ring
            ZStack {
                // Gradient Ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                theme.currentGradient.accentColor,
                                theme.currentGradient.secondaryColor
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 100, height: 100)
                
                // Avatar Background
                Circle()
                    .fill(theme.currentGradient.accentColor.opacity(0.1))
                    .frame(width: 88, height: 88)
                
                // Avatar Icon
                Image(systemName: "person.fill")
                    .font(.system(size: 40))
                    .foregroundColor(theme.currentGradient.accentColor)
            }
            
            // User Greeting
            VStack(spacing: 4) {
                if let user = authService.user {
                    Text("Welcome back,")
                        .font(.subheadline)
                        .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                    
                    Text(user.fullName.components(separatedBy: " ").first ?? "User")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                } else {
                    Text("Profile")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                }
            }
            
            // Status Badge
            HStack(spacing: 8) {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
                
                Text("Active Account")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(.green.opacity(0.1))
                    .overlay(
                        Capsule()
                            .stroke(.green.opacity(0.3), lineWidth: 1)
                    )
            )
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
                    radius: 20,
                    x: 0,
                    y: 10
                )
        )
    }
    
    // MARK: - Profile Stats Card
    private func ProfileStatsCard() -> some View {
        HStack(spacing: 16) {
            // Member Since
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(theme.currentGradient.accentColor.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "calendar.badge.plus")
                        .font(.headline)
                        .foregroundColor(theme.currentGradient.accentColor)
                }
                
                if let user = authService.user {
                    let daysSince = Calendar.current.dateComponents([.day], from: user.createdAt ?? Date(), to: Date()).day ?? 0
                    
                    Text("\(daysSince)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                    
                    Text("Days Active")
                        .font(.caption2)
                        .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                }
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 40)
            
            // Currency
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(theme.currentGradient.secondaryColor.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Text(currencyService.selectedCurrency.symbol)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(theme.currentGradient.secondaryColor)
                }
                
                Text(currencyService.selectedCurrency.rawValue.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                
                Text("Currency")
                    .font(.caption2)
                    .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 40)
            
            // Theme
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(theme.currentGradient.accentColor.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "paintbrush.fill")
                        .font(.headline)
                        .foregroundColor(theme.currentGradient.accentColor)
                }
                
                Button {
                    theme.nextGradient()
                } label: {
                    Text("Change")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.currentGradient.accentColor)
                }
                
                Text("Theme")
                    .font(.caption2)
                    .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
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
    
    // MARK: - User Info Card (Enhanced)
    private func UserInfoCard(user: User) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Account Details")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                
                Spacer()
                
                Image(systemName: "person.text.rectangle")
                    .foregroundColor(theme.currentGradient.accentColor)
            }
            
            VStack(spacing: 16) {
                ProfileInfoRow(
                    icon: "person.fill",
                    title: "Full Name",
                    value: user.fullName,
                    color: theme.currentGradient.accentColor
                )
                
                ProfileInfoRow(
                    icon: "envelope.fill",
                    title: "Email Address",
                    value: user.email,
                    color: theme.currentGradient.secondaryColor
                )
                
                ProfileInfoRow(
                    icon: "calendar",
                    title: "Joined",
                    value: DateFormatter.memberSinceFormatter.string(from: user.createdAt ?? Date()),
                    color: theme.currentGradient.accentColor
                )
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
    
    // MARK: - Enhanced Preferences Card
    private func PreferencesCard() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Preferences")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                
                Spacer()
                
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(theme.currentGradient.accentColor)
            }
            
            // Currency Setting
            VStack(spacing: 12) {
                HStack {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(theme.currentGradient.accentColor.opacity(0.1))
                                .frame(width: 36, height: 36)
                            
                            Text(currencyService.selectedCurrency.symbol)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(theme.currentGradient.accentColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Default Currency")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                            
                            Text("Used for all transactions")
                                .font(.caption)
                                .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                        }
                    }
                    
                    Spacer()
                    
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
                        HStack(spacing: 8) {
                            Text(currencyService.selectedCurrency.rawValue.uppercased())
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.currentGradient.accentColor)
                            
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                                .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(theme.currentGradient.accentColor.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(theme.currentGradient.accentColor.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.adaptiveCardBackground(for: colorScheme).opacity(0.5))
                )
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
    
    // MARK: - App Info Card
    private func AppInfoCard() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("About ExpenseBuddy")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                
                Spacer()
                
                Image(systemName: "info.circle")
                    .foregroundColor(theme.currentGradient.accentColor)
            }
            
            VStack(spacing: 12) {
                AppInfoRow(title: "Version", value: "1.0.0")
                AppInfoRow(title: "Build", value: "1")
                AppInfoRow(title: "Platform", value: "iOS 26.0")
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
    
    // MARK: - Enhanced Sign Out Card
    private func SignOutCard() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Account Actions")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
                    
                    Text("Manage your session")
                        .font(.caption)
                        .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                }
                
                Spacer()
                
                Image(systemName: "exclamationmark.shield")
                    .foregroundColor(.orange)
            }
            
            // Sign Out Button with Better Design
            Button {
                showingSignOutAlert = true
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(.red.opacity(0.1))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.headline)
                            .foregroundColor(.red)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sign Out")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                        
                        Text("End your current session")
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.7))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.red.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.red.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
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
                                    Color.red.opacity(0.2),
                                    Color.red.opacity(0.1)
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

// MARK: - Enhanced Profile Info Row
struct ProfileInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.adaptiveCardBackground(for: colorScheme).opacity(0.5))
        )
    }
}

// MARK: - App Info Row
struct AppInfoRow: View {
    let title: String
    let value: String
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(theme.adaptiveTextSecondary(for: colorScheme))
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(theme.adaptiveTextPrimary(for: colorScheme))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.adaptiveCardBackground(for: colorScheme).opacity(0.5))
        )
    }
}

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let memberSinceFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}
