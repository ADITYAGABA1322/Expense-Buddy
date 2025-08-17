import SwiftUI

struct WelcomeSheetView: View {
    @Binding var isShowing: Bool
    @State private var page = 0
    @State private var waveOffset: CGFloat = 0
    
    private let pages: [OBPage] = [
        .init(title: "Welcome to ExpenseBuddy",
              subtitle: "Track • Analyze • Grow",
              icon: "wallet.pass",
              color: .blue,
              bullets: ["Unified multi‑currency view", "Smart offline sync", "Insightful charts"]),
        .init(title: "Add Expenses Fast",
              subtitle: "Less typing, more tracking",
              icon: "plus.circle.fill",
              color: .teal,
              bullets: ["Quick add sheet", "Auto currency convert", "Pending sync indicator"]),
        .init(title: "Powerful Analytics",
              subtitle: "Understand spending",
              icon: "chart.pie.fill",
              color: .purple,
              bullets: ["Category breakdown", "Trends & averages", "Multi‑range filters"]),
        .init(title: "Stay in Control",
              subtitle: "Your data, your way",
              icon: "lock.shield.fill",
              color: .orange,
              bullets: ["Works offline", "Secure storage", "Instant refresh"])
    ]
    
    var body: some View {
        ZStack {
            OBGradientBackground(color: pages[page].color, waveOffset: $waveOffset)
            VStack(spacing: 28) {
                OBDots(count: pages.count, current: page, accent: pages[page].color)
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        OBPageView(p: pages[i], isActive: page == i)
                            .tag(i)
                            .padding(.horizontal)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                OBNavBar(page: $page, total: pages.count, color: pages[page].color) {
                    isShowing = false
                }
            }
            .padding(.vertical, 20)
        }
        .onAppear {
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                waveOffset = UIScreen.main.bounds.width
            }
        }
    }
}

private struct OBPage {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let bullets: [String]
}

private struct OBDots: View {
    let count: Int
    let current: Int
    let accent: Color
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
//                    .fill(i == current ? accent.gradient : Color.white.opacity(0.2))
                    .fill(i == current ? accent : Color.white.opacity(0.2))
                
                    .frame(width: i == current ? 30 : 10, height: 8)
                    .animation(.spring(response: 0.35), value: current)
            }
        }
    }
}

private struct OBPageView: View {
    let p: OBPage
    let isActive: Bool
    @State private var iconScale: CGFloat = 0.8
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(p.color.opacity(0.18))
                    .frame(width: 180, height: 180)
                    .blur(radius: 12)
                Circle()
                    .stroke(p.color.opacity(0.35), lineWidth: 1.4)
                    .frame(width: 165, height: 165)
                    .overlay(
                        Circle()
                            .fill(
                                LinearGradient(colors: [.white.opacity(0.9), .white.opacity(0.6)],
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing)
                            )
                            .frame(width: 140, height: 140)
                            .shadow(color: p.color.opacity(0.35), radius: 8, y: 4)
                    )
                Image(systemName: p.icon)
                    .font(.system(size: 58, weight: .semibold))
                    .foregroundStyle(LinearGradient(colors: [p.color, p.color.opacity(0.7)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing))
                    .scaleEffect(iconScale)
                    .onAppear {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
                            iconScale = 1
                        }
                    }
            }
            VStack(spacing: 10) {
                Text(p.title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(
                        LinearGradient(colors: [.white, .white.opacity(0.85)],
                                       startPoint: .top,
                                       endPoint: .bottom)
                    )
                Text(p.subtitle)
                    .font(.title3.weight(.medium))
                    .foregroundColor(.white.opacity(0.75))
            }
            VStack(alignment: .leading, spacing: 10) {
                ForEach(p.bullets, id: \.self) { b in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(p.color.opacity(0.9))
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)
                        Text(b)
                            .foregroundColor(.white.opacity(0.85))
                            .font(.subheadline.weight(.medium))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(18)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity)
        .padding(.top, 10)
        .opacity(isActive ? 1 : 0.4)
        .scaleEffect(isActive ? 1 : 0.96)
        .animation(.easeInOut(duration: 0.4), value: isActive)
    }
}

private struct OBNavBar: View {
    @Binding var page: Int
    let total: Int
    let color: Color
    let finish: () -> Void
    
    var body: some View {
        HStack {
            Button {
                finish()
            } label: {
                Text("Skip")
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
            }
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.08)))
            
            Spacer()
            
            Button {
                if page < total - 1 {
                    withAnimation(.spring()) { page += 1 }
                } else {
                    finish()
                }
            } label: {
                HStack(spacing: 6) {
                    Text(page == total - 1 ? "Start" : "Next")
                        .fontWeight(.semibold)
                    Image(systemName: page == total - 1 ? "checkmark.circle.fill" : "chevron.right.circle.fill")
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(colors: [color, color.opacity(0.7)],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                        .cornerRadius(18)
                )
                .shadow(color: color.opacity(0.4), radius: 6, y: 4)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 10)
    }
}

private struct OBGradientBackground: View {
    let color: Color
    @Binding var waveOffset: CGFloat
    @Environment(\.colorScheme) private var cs
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    color.opacity(cs == .dark ? 0.55 : 0.6),
                    Color.black.opacity(cs == .dark ? 0.75 : 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            Wave(offset: waveOffset * 0.4, amplitude: 24)
                .fill(color.opacity(0.10))
                .frame(height: 180)
                .blur(radius: 4)
                .offset(y: 260)
            Wave(offset: waveOffset * 0.7, amplitude: 18)
                .fill(color.opacity(0.06))
                .frame(height: 190)
                .offset(y: 270)
        }
    }
}

private struct Wave: Shape {
    var offset: CGFloat
    var amplitude: CGFloat
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: .init(x: 0, y: rect.maxY))
        for x in stride(from: 0, through: rect.width, by: 2) {
            let rel = x / rect.width
            let y = sin(rel * .pi * 2 + offset / 40) * amplitude + rect.midY
            p.addLine(to: .init(x: x, y: y))
        }
        p.addLine(to: .init(x: rect.width, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
