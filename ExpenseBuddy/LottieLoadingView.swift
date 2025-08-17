import SwiftUI
import Lottie

struct LottieLoadingView: View {
    @StateObject private var theme = AppTheme.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateGradient = false
    @State private var showText = false
    
    var body: some View {
        ZStack {
            // Enhanced Gradient Background that matches theme
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
            
            // Overlay for depth
            LinearGradient(
                colors: [
                    Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1),
                    Color.clear,
                    Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Content
            VStack(spacing: 40) {
                Spacer()
                
                // Lottie Animation
                LottieAnimationView()
                
                // App Info with Animation
                VStack(spacing: 16) {
                    if showText {
                        Text("ExpenseBuddy")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.9)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        
                        Text("Smart expense tracking made simple")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.easeOut(duration: 1.0).delay(0.5), value: showText)
                
                Spacer()
                
                // Loading indicator
                HStack(spacing: 12) {
                    LoadingDots()
                    
                    Text("Loading your data...")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            animateGradient = true
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                showText = true
            }
        }
    }
}

// MARK: - Lottie Animation View
struct LottieAnimationView: View {
    @StateObject private var theme = AppTheme.shared
    
    var body: some View {
        ZStack {
            // Background circle with glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(0.3),
                            .white.opacity(0.1),
                            .clear
                        ],
                        center: .center,
                        startRadius: 50,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .blur(radius: 10)
            
            // Main Lottie Animation
            LottieView(fileName: "Moneystack") // Use your Lottie file name
                .frame(width: 150, height: 150)
                .background(
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)
                )
        }
    }
}

// MARK: - Lottie View Wrapper

struct LottieView: UIViewRepresentable{
    var fileName: String
    
    func makeUIView(context: UIViewRepresentableContext<LottieView>) ->  UIView {
        let view = UIView(frame: .zero)
        let animationView = AnimationView()
        animationView.animation = Animation.named(fileName)
        animationView.contentMode = .scaleAspectFill
        animationView.loopMode = .loop
        animationView.play()
        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)
        
        NSLayoutConstraint.activate([
            animationView.topAnchor.constraint(equalTo: view.topAnchor),
            animationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            animationView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        return view
    }
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<LottieView>) {
        
    }
}


// MARK: - Loading Dots Animation
struct LoadingDots: View {
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(.white.opacity(0.8))
                    .frame(width: 8, height: 8)
                    .scaleEffect(animating ? 1.0 : 0.5)
                    .opacity(animating ? 1.0 : 0.3)
                    .animation(
                        .easeInOut(duration: 0.6)
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
