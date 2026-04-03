import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.4
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var particleOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.5
    @State private var ringOpacity: Double = 0

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.brandSlate, Color(hex: "#0D1520")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Decorative rings
            ForEach(0..<3) { i in
                Circle()
                    .stroke(Color.brandOrange.opacity(0.15 - Double(i) * 0.04), lineWidth: 1)
                    .frame(width: CGFloat(180 + i * 80), height: CGFloat(180 + i * 80))
                    .scaleEffect(ringScale + CGFloat(i) * 0.1)
                    .opacity(ringOpacity)
            }

            // Particle dots
            ForEach(0..<12) { i in
                let angle = Double(i) * 30.0
                let radius: Double = 120
                Circle()
                    .fill(Color.brandOrange.opacity(0.6))
                    .frame(width: i % 3 == 0 ? 6 : 4, height: i % 3 == 0 ? 6 : 4)
                    .offset(
                        x: CGFloat(cos(angle * .pi / 180) * radius),
                        y: CGFloat(sin(angle * .pi / 180) * radius)
                    )
                    .opacity(particleOpacity)
            }

            VStack(spacing: 24) {
                // Logo icon
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(LinearGradient.brandGradient)
                        .frame(width: 110, height: 110)
                        .shadow(color: Color.brandOrange.opacity(0.5), radius: 20, x: 0, y: 10)

                    VStack(spacing: 4) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                VStack(spacing: 8) {
                    Text("SmartBuild")
                        .font(SBCFont.display(32))
                        .foregroundColor(.white)
                    + Text(" Calc")
                        .font(SBCFont.display(32))
                        .foregroundColor(.brandOrange)

                    Text("Calculate materials for construction")
                        .font(SBCFont.body(15))
                        .foregroundColor(.white.opacity(0.6))
                }
                .opacity(textOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.2)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.5)) {
                ringScale = 1.0
                ringOpacity = 1.0
            }
            withAnimation(.easeIn(duration: 0.5).delay(0.7)) {
                particleOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.9)) {
                textOpacity = 1.0
            }
        }
    }
}
