import SwiftUI

struct AnimatedLoadingView: View {
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateGradient = false
    @State private var showContent = false
    @State private var rotateCircles = false
    
    var body: some View {
        ZStack {
            // Simple, Beautiful Animated Gradient Background
            LinearGradient(
                colors: [
                    theme.currentGradient.accentColor,
                    theme.currentGradient.secondaryColor,
                    theme.currentGradient.accentColor.opacity(0.8)
                ],
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .animation(
                .easeInOut(duration: 3.0).repeatForever(autoreverses: true),
                value: animateGradient
            )
            
            // Content
            VStack(spacing: 50) {
                Spacer()
                
                // Clean Animated Logo
                ZStack {
                    // Rotating circles with theme colors
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.8),
                                        theme.currentGradient.accentColor.opacity(0.6),
                                        .white.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: CGFloat(80 + index * 30), height: CGFloat(80 + index * 30))
                            .rotationEffect(.degrees(rotateCircles ? 360 : 0))
                            .animation(
                                .linear(duration: Double(2 + index))
                                    .repeatForever(autoreverses: false),
                                value: rotateCircles
                            )
                    }
                    
                    // Center dollar icon with theme accent
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .blur(radius: 8)
                        
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, theme.currentGradient.accentColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .scaleEffect(showContent ? 1.0 : 0.8)
                    .animation(
                        .easeOut(duration: 1.0).delay(0.3),
                        value: showContent
                    )
                }
                
                // App Title with theme integration
                if showContent {
                    VStack(spacing: 16) {
                        Text("ExpenseBuddy")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.9)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: theme.currentGradient.backgroundColor.opacity(0.6), radius: 4, x: 0, y: 2)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        
                        Text("Smart expense tracking made simple")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        
                        // Simple theme indicator
                        HStack(spacing: 8) {
                            Circle()
                                .fill(.white.opacity(0.8))
                                .frame(width: 6, height: 6)
                            
                            Text(theme.currentGradient.name)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(.white.opacity(0.2))
                                )
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                    .animation(.easeOut(duration: 0.8).delay(0.5), value: showContent)
                }
                
                Spacer()
                
                // Simple loading indicator
                VStack(spacing: 12) {
                    SimpleThemeDots()
                    
                    Text("Preparing your dashboard...")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.7))
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                }
                .padding(.bottom, 60)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.8).delay(1.0), value: showContent)
            }
        }
        .onAppear {
            animateGradient = true
            rotateCircles = true
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                showContent = true
            }
        }
        // React to theme changes smoothly
        .onChange(of: theme.currentGradient) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                // Simple animation when theme changes
            }
        }
    }
}

// MARK: - Simple Theme-Aware Dots
struct SimpleThemeDots: View {
    @StateObject private var theme = AppTheme.shared
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.9),
                                theme.currentGradient.accentColor.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 10, height: 10)
                    .scaleEffect(animating ? 1.2 : 0.6)
                    .opacity(animating ? 1.0 : 0.4)
                    .animation(
                        .easeInOut(duration: 0.8)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .onAppear {
            animating = true
        }
    }
}
