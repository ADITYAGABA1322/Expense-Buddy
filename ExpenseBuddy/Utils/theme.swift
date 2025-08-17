import SwiftUI
import Combine

class AppTheme: ObservableObject {
    static let shared = AppTheme()
    
    @Published var currentGradient: GradientTheme
    
    private let themeKey = "selected_theme_index"
    private var currentIndex: Int {
        didSet {
            // Save theme preference immediately when changed
            UserDefaults.standard.set(currentIndex, forKey: themeKey)
            print("🎨 Theme saved: \(themes[currentIndex].name)")
        }
    }
    
    private let themes: [GradientTheme] = [
        GradientTheme(
            name: "Ocean Breeze",
            accentColor: Color(red: 0.2, green: 0.6, blue: 1.0),
            secondaryColor: Color(red: 0.0, green: 0.8, blue: 0.9),
            backgroundColor: Color(red: 0.05, green: 0.15, blue: 0.25)
        ),
        GradientTheme(
            name: "Sunset Glow",
            accentColor: Color(red: 1.0, green: 0.4, blue: 0.2),
            secondaryColor: Color(red: 1.0, green: 0.6, blue: 0.0),
            backgroundColor: Color(red: 0.25, green: 0.1, blue: 0.05)
        ),
        GradientTheme(
            name: "Forest Dream",
            accentColor: Color(red: 0.2, green: 0.8, blue: 0.4),
            secondaryColor: Color(red: 0.0, green: 0.6, blue: 0.8),
            backgroundColor: Color(red: 0.05, green: 0.2, blue: 0.1)
        ),
        GradientTheme(
            name: "Purple Rain",
            accentColor: Color(red: 0.6, green: 0.2, blue: 1.0),
            secondaryColor: Color(red: 0.8, green: 0.3, blue: 0.9),
            backgroundColor: Color(red: 0.15, green: 0.05, blue: 0.25)
        ),
        GradientTheme(
            name: "Golden Hour",
            accentColor: Color(red: 1.0, green: 0.8, blue: 0.2),
            secondaryColor: Color(red: 1.0, green: 0.5, blue: 0.0),
            backgroundColor: Color(red: 0.25, green: 0.2, blue: 0.05)
        ),
        GradientTheme(
            name: "Midnight Blue",
            accentColor: Color(red: 0.1, green: 0.3, blue: 0.8),
            secondaryColor: Color(red: 0.3, green: 0.1, blue: 0.6),
            backgroundColor: Color(red: 0.05, green: 0.05, blue: 0.2)
        )
    ]
    
    private init() {
        // Load saved theme preference
        let savedIndex = UserDefaults.standard.integer(forKey: themeKey)
        self.currentIndex = min(savedIndex, themes.count - 1)
        self.currentGradient = themes[currentIndex]
        print("🎨 Theme loaded: \(currentGradient.name)")
    }
    
    func nextGradient() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentIndex = (currentIndex + 1) % themes.count
            currentGradient = themes[currentIndex]
        }
        
        // Send notification for theme change
        NotificationCenter.default.post(name: .themeChanged, object: currentGradient)
        print("🎨 Theme changed to: \(currentGradient.name)")
    }
    
    func setTheme(at index: Int) {
        guard index >= 0 && index < themes.count else { return }
        withAnimation(.easeInOut(duration: 0.5)) {
            currentIndex = index
            currentGradient = themes[index]
        }
        
        // Send notification for theme change
        NotificationCenter.default.post(name: .themeChanged, object: currentGradient)
    }
    
    func getAllThemes() -> [GradientTheme] {
        return themes
    }
    
    func getCurrentThemeIndex() -> Int {
        return currentIndex
    }
    
    // MARK: - Adaptive Colors for Light/Dark Mode
    func adaptiveTextPrimary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white : .black
    }
    
    func adaptiveTextSecondary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6)
    }
    
    func adaptiveCardBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ?
            Color(white: 0.1).opacity(0.8) :
            Color.white.opacity(0.9)
    }
    
    // MARK: - Theme-Aware Status Colors
    func statusOnlineColor() -> Color {
        currentGradient.accentColor
    }
    
    func statusOfflineColor() -> Color {
        .orange
    }
    
    func statusBorderColor() -> Color {
        currentGradient.accentColor.opacity(0.3)
    }
}

struct GradientTheme: Equatable {
    let name: String
    let accentColor: Color
    let secondaryColor: Color
    let backgroundColor: Color
}

// MARK: - MISSING COMPONENT: GradientBackgroundView
//struct GradientBackgroundView: View {
//    @StateObject private var theme = AppTheme.shared
//    @Environment(\.colorScheme) private var colorScheme
//    @State private var animateGradient = false
//    
//    var body: some View {
//        ZStack {
//            // Base gradient with theme colors
//            LinearGradient(
//                colors: [
//                    theme.currentGradient.accentColor.opacity(colorScheme == .dark ? 0.6 : 0.3),
//                    theme.currentGradient.secondaryColor.opacity(colorScheme == .dark ? 0.4 : 0.2),
//                    theme.currentGradient.backgroundColor.opacity(colorScheme == .dark ? 0.8 : 0.1),
//                    colorScheme == .dark ? Color.black.opacity(0.9) : Color.white.opacity(0.95)
//                ],
//                startPoint: animateGradient ? .topLeading : .bottomTrailing,
//                endPoint: animateGradient ? .bottomTrailing : .topLeading
//            )
//            
//            // Animated overlay for dynamic effect
//            LinearGradient(
//                colors: [
//                    theme.currentGradient.accentColor.opacity(0.1),
//                    Color.clear,
//                    theme.currentGradient.secondaryColor.opacity(0.1)
//                ],
//                startPoint: animateGradient ? .bottomLeading : .topTrailing,
//                endPoint: animateGradient ? .topTrailing : .bottomLeading
//            )
//            .animation(
//                .easeInOut(duration: 4.0).repeatForever(autoreverses: true),
//                value: animateGradient
//            )
//            
//            // Subtle texture overlay
//            RadialGradient(
//                colors: [
//                    .white.opacity(colorScheme == .dark ? 0.02 : 0.1),
//                    .clear
//                ],
//                center: .topLeading,
//                startRadius: 50,
//                endRadius: 300
//            )
//        }
//        .ignoresSafeArea()
//        .animation(.easeInOut(duration: 1.0), value: theme.currentGradient.name)
//        .onAppear {
//            animateGradient = true
//        }
//        .onReceive(NotificationCenter.default.publisher(for: .themeChanged)) { _ in
//            // Reset animation when theme changes
//            withAnimation(.easeInOut(duration: 0.5)) {
//                animateGradient.toggle()
//            }
//        }
//    }
//}

//struct GradientBackgroundView: View {
//    @StateObject private var theme = AppTheme.shared
//    @Environment(\.colorScheme) private var colorScheme
//    @State private var animateGradient = false
//    @State private var animationId = UUID() // 🎯 ADD THIS: Force animation restart
//    
//    var body: some View {
//        ZStack {
//            // Base gradient with theme colors
//            LinearGradient(
//                colors: [
//                    theme.currentGradient.accentColor.opacity(colorScheme == .dark ? 0.6 : 0.3),
//                    theme.currentGradient.secondaryColor.opacity(colorScheme == .dark ? 0.4 : 0.2),
//                    theme.currentGradient.backgroundColor.opacity(colorScheme == .dark ? 0.8 : 0.1),
//                    colorScheme == .dark ? Color.black.opacity(0.9) : Color.white.opacity(0.95)
//                ],
//                startPoint: animateGradient ? .topLeading : .bottomTrailing,
//                endPoint: animateGradient ? .bottomTrailing : .topLeading
//            )
//            
//            // 🎯 FIXED: Animated overlay with proper restart mechanism
//            LinearGradient(
//                colors: [
//                    theme.currentGradient.accentColor.opacity(0.1),
//                    Color.clear,
//                    theme.currentGradient.secondaryColor.opacity(0.1)
//                ],
//                startPoint: animateGradient ? .bottomLeading : .topTrailing,
//                endPoint: animateGradient ? .topTrailing : .bottomLeading
//            )
//            .animation(
//                .easeInOut(duration: 4.0).repeatForever(autoreverses: true),
//                value: animateGradient
//            )
//            .id(animationId) // 🎯 FIXED: Force view recreation to restart animation
//            
//            // Subtle texture overlay
//            RadialGradient(
//                colors: [
//                    .white.opacity(colorScheme == .dark ? 0.02 : 0.1),
//                    .clear
//                ],
//                center: .topLeading,
//                startRadius: 50,
//                endRadius: 300
//            )
//        }
//        .ignoresSafeArea()
//        .animation(.easeInOut(duration: 1.0), value: theme.currentGradient.name)
//        .onAppear {
//            // 🎯 FIXED: Ensure animation starts properly
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                withAnimation(.easeInOut(duration: 0.5)) {
//                    animateGradient = true
//                }
//            }
//        }
//        .onReceive(NotificationCenter.default.publisher(for: .themeChanged)) { _ in
//            // 🎯 FIXED: Properly restart animation when theme changes
//            withAnimation(.easeInOut(duration: 0.3)) {
//                animationId = UUID() // Force animation restart
//                animateGradient.toggle()
//            }
//            
//            // Ensure continuous animation
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
//                    animateGradient.toggle()
//                }
//            }
//        }
//        // 🎯 NEW: Reset animation when view disappears and reappears (logout/login)
//        .onDisappear {
//            animateGradient = false
//        }
//    }
//}

struct GradientBackgroundView: View {
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateGradient = false
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        ZStack {
            // Simple base gradient
            LinearGradient(
                colors: [
                    theme.currentGradient.accentColor.opacity(colorScheme == .dark ? 0.6 : 0.3),
                    theme.currentGradient.secondaryColor.opacity(colorScheme == .dark ? 0.4 : 0.2),
                    colorScheme == .dark ? Color.black.opacity(0.9) : Color.white.opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // 🎯 SIMPLIFIED: Moving overlay with better animation control
            LinearGradient(
                colors: [
                    theme.currentGradient.accentColor.opacity(0.1),
                    Color.clear,
                    theme.currentGradient.secondaryColor.opacity(0.1)
                ],
                startPoint: UnitPoint(x: 0.5 + cos(rotationAngle) * 0.3, y: 0.5 + sin(rotationAngle) * 0.3),
                endPoint: UnitPoint(x: 0.5 - cos(rotationAngle) * 0.3, y: 0.5 - sin(rotationAngle) * 0.3)
            )
        }
        .ignoresSafeArea()
        .onAppear {
            startAnimation()
        }
        .onReceive(NotificationCenter.default.publisher(for: .themeChanged)) { _ in
            // Restart animation on theme change
            startAnimation()
        }
    }
    
    private func startAnimation() {
        withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
            rotationAngle = .pi * 2
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let themeChanged = Notification.Name("themeChanged")
}

// MARK: - Premium UI Extensions
extension View {
    func themeAdaptiveCard(padding: CGFloat = 16) -> some View {
        let theme = AppTheme.shared
        
        return self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        theme.currentGradient.accentColor.opacity(0.3),
                                        theme.currentGradient.secondaryColor.opacity(0.2),
                                        .clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .shadow(
                color: theme.currentGradient.accentColor.opacity(0.15),
                radius: 20,
                x: 0,
                y: 10
            )
    }
    
    func themeAdaptiveButton() -> some View {
        let theme = AppTheme.shared
        
        return self
            .padding(.horizontal, 20)
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
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(
                color: theme.currentGradient.accentColor.opacity(0.4),
                radius: 12,
                x: 0,
                y: 6
            )
    }
    
    func themeAdaptiveIcon() -> some View {
        let theme = AppTheme.shared
        
        return self
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        theme.currentGradient.accentColor,
                        theme.currentGradient.secondaryColor
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

// MARK: - Theme-Aware Components
struct ThemeChip: View {
    let label: String
    let systemImage: String?
    var isSelected: Bool = false
    
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : theme.currentGradient.accentColor)
            }
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(isSelected ? .white : theme.currentGradient.accentColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(
                    isSelected ?
                    LinearGradient(
                        colors: [
                            theme.currentGradient.accentColor,
                            theme.currentGradient.secondaryColor
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        colors: [
                            theme.currentGradient.accentColor.opacity(0.1),
                            theme.currentGradient.secondaryColor.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Capsule()
                        .stroke(
                            theme.currentGradient.accentColor.opacity(isSelected ? 0 : 0.3),
                            lineWidth: 1
                        )
                )
        )
        .shadow(
            color: isSelected ? theme.currentGradient.accentColor.opacity(0.4) : .clear,
            radius: 8,
            x: 0,
            y: 4
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}
