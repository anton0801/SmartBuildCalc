import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0

    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "function",
            accentIcon: "square.3.layers.3d.down.right",
            title: "Calculate Building\nMaterials",
            description: "Instantly calculate bricks, concrete, tiles, paint, drywall, and insulation for any project.",
            gradient: [Color(hex: "#F4621F"), Color(hex: "#FF8A50")],
            bgShape: .brick
        ),
        OnboardingPage(
            icon: "dollarsign.circle.fill",
            accentIcon: "chart.bar.fill",
            title: "Plan Construction\nCosts",
            description: "Get accurate cost estimates, track material prices, and stay within your budget.",
            gradient: [Color(hex: "#F5A623"), Color(hex: "#E8920F")],
            bgShape: .chart
        ),
        OnboardingPage(
            icon: "folder.fill.badge.plus",
            accentIcon: "house.fill",
            title: "Save Your Building\nProjects",
            description: "Organize multiple construction projects, rooms, and shopping lists all in one place.",
            gradient: [Color(hex: "#27AE60"), Color(hex: "#1D8A4A")],
            bgShape: .folder
        )
    ]

    var body: some View {
        ZStack {
            Color.surfaceLight
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { idx, page in
                        OnboardingPageView(page: page)
                            .tag(idx)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)

                // Bottom controls
                VStack(spacing: 20) {
                    // Dot indicators
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { idx in
                            Capsule()
                                .fill(idx == currentPage ? Color.brandOrange : Color.brandOrange.opacity(0.3))
                                .frame(width: idx == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                        }
                    }

                    // Buttons
                    HStack {
                        Button("Skip") {
                            appState.hasCompletedOnboarding = true
                        }
                        .buttonStyle(GhostButtonStyle())

                        Spacer()

                        Button(currentPage < pages.count - 1 ? "Next" : "Get Started") {
                            if currentPage < pages.count - 1 {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    currentPage += 1
                                }
                            } else {
                                appState.hasCompletedOnboarding = true
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle(isFullWidth: false))
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
                .padding(.top, 16)
            }
        }
    }
}

struct OnboardingPage {
    var icon: String
    var accentIcon: String
    var title: String
    var description: String
    var gradient: [Color]
    var bgShape: BgShape

    enum BgShape { case brick, chart, folder }
}

struct OnboardingPageView: View {
    var page: OnboardingPage
    @State private var appeared = false
    @State private var floatOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Illustration
            ZStack {
                // Background circle
                Circle()
                    .fill(LinearGradient(colors: page.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 220, height: 220)
                    .opacity(0.15)
                    .scaleEffect(appeared ? 1 : 0.5)

                Circle()
                    .fill(LinearGradient(colors: page.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 160, height: 160)
                    .opacity(0.25)
                    .scaleEffect(appeared ? 1 : 0.5)

                // Main icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: page.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 110, height: 110)
                        .shadow(color: page.gradient[0].opacity(0.4), radius: 20, x: 0, y: 10)

                    Image(systemName: page.icon)
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(appeared ? 1 : 0.3)
                .offset(y: floatOffset)

                // Floating accent badge
                Image(systemName: page.accentIcon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(page.gradient[0])
                    .padding(12)
                    .background(Circle().fill(Color.white).shadow(color: Color.black.opacity(0.1), radius: 8))
                    .offset(x: 55, y: -50)
                    .scaleEffect(appeared ? 1 : 0)
                    .offset(y: floatOffset * 0.5)
            }
            .frame(height: 260)

            // Text
            VStack(spacing: 12) {
                Text(page.title)
                    .font(SBCFont.display(28))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                Text(page.description)
                    .font(SBCFont.body(16))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
            }

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.1)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                floatOffset = -10
            }
        }
        .onDisappear {
            appeared = false
        }
    }
}
