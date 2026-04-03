import SwiftUI

// MARK: - Color Palette
extension Color {
    // Primary brand colors
    static let brandOrange = Color(hex: "#F4621F")
    static let brandOrangeLight = Color(hex: "#FF8A50")
    static let brandOrangeDark = Color(hex: "#C44A0E")

    // Secondary
    static let brandSlate = Color(hex: "#1E2A3A")
    static let brandSlateLight = Color(hex: "#2D3F54")
    static let brandSlateMid = Color(hex: "#3D5068")

    // Accent
    static let brandGold = Color(hex: "#F5A623")
    static let brandGreen = Color(hex: "#27AE60")
    static let brandRed = Color(hex: "#E74C3C")

    // Surface
    static let surfaceLight = Color(hex: "#F7F5F2")
    static let surfaceDark = Color(hex: "#141D27")
    static let cardLight = Color(hex: "#FFFFFF")
    static let cardDark = Color(hex: "#1E2A3A")

    // Text
    static let textPrimary = Color(hex: "#1E2A3A")
    static let textSecondary = Color(hex: "#6B7C93")
    static let textMuted = Color(hex: "#A0ADB8")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Gradients
extension LinearGradient {
    static let brandGradient = LinearGradient(
        colors: [.brandOrange, .brandOrangeDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let slateGradient = LinearGradient(
        colors: [.brandSlate, .brandSlateMid],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let goldGradient = LinearGradient(
        colors: [.brandGold, Color(hex: "#E8920F")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let cardGradient = LinearGradient(
        colors: [Color.white.opacity(0.08), Color.white.opacity(0.02)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Typography
struct SBCFont {
    static func display(_ size: CGFloat) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func headline(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static func body(_ size: CGFloat) -> Font { .system(size: size, weight: .regular, design: .rounded) }
    static func caption(_ size: CGFloat) -> Font { .system(size: size, weight: .medium, design: .rounded) }
    static func mono(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold, design: .monospaced) }
}

// MARK: - Card Style
struct CardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(colorScheme == .dark ? Color.cardDark : Color.cardLight)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 12, x: 0, y: 4)
            )
    }
}

extension View {
    func cardStyle(padding: CGFloat = 16) -> some View {
        modifier(CardStyle(padding: padding))
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    var isFullWidth: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SBCFont.headline(16))
            .foregroundColor(.white)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(LinearGradient.brandGradient)
            .cornerRadius(14)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .shadow(color: Color.brandOrange.opacity(0.4), radius: 8, x: 0, y: 4)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SBCFont.headline(16))
            .foregroundColor(.brandOrange)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.brandOrange, lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SBCFont.body(15))
            .foregroundColor(.brandOrange)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Input Field Style
struct SBCInputField: View {
    var title: String
    var placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var suffix: String? = nil

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if #available(iOS 16.0, *) {
                Text(title)
                    .font(SBCFont.caption(12))
                    .foregroundColor(.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            } else {
                Text(title)
                    .font(SBCFont.caption(12))
                    .foregroundColor(.textSecondary)
                    .textCase(.uppercase)
            }

            HStack {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .font(SBCFont.body(16))
                    .foregroundColor(colorScheme == .dark ? .white : .textPrimary)

                if let suffix = suffix {
                    Text(suffix)
                        .font(SBCFont.caption(14))
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color.brandSlateMid.opacity(0.5) : Color.surfaceLight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.brandOrange.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Section Header
struct SBCSectionHeader: View {
    var title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(SBCFont.headline(18))
                .foregroundColor(.primary)
            Spacer()
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .font(SBCFont.caption(14))
                    .foregroundColor(.brandOrange)
            }
        }
    }
}

// MARK: - Stat Badge
struct StatBadge: View {
    var value: String
    var label: String
    var color: Color = .brandOrange

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(SBCFont.display(20))
                .foregroundColor(color)
            Text(label)
                .font(SBCFont.caption(11))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
