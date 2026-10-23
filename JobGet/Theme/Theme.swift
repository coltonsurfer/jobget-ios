import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }

    static let jgPurple = Color(hex: 0x5B3DF5)
    static let jgPurpleDark = Color(hex: 0x3E27B9)
    static let jgLilac = Color(hex: 0xEFEBFF)
    static let jgGreen = Color(hex: 0x14A86B)
    static let jgGreenSoft = Color(hex: 0xE4F7EE)
    static let jgOrange = Color(hex: 0xFF6B1A)
    static let jgOrangeSoft = Color(hex: 0xFFEEE3)
    static let jgInk = Color(hex: 0x15122E)
    static let jgMuted = Color(hex: 0x6F6B8A)
    static let jgSurface = Color(hex: 0xF5F4FA)
    static let jgLine = Color(hex: 0xE6E3F2)
    static let jgRed = Color(hex: 0xD93A3A)
    static let jgRedSoft = Color(hex: 0xFCE9E9)
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.jgLine, lineWidth: 1))
    }
}

extension View {
    func jgCard() -> some View { modifier(CardStyle()) }
}

struct Pill: View {
    let text: String
    var icon: String? = nil
    var foreground: Color = .jgPurple
    var background: Color = .jgLilac

    var body: some View {
        HStack(spacing: 4) {
            if let icon { Image(systemName: icon).font(.caption2.weight(.bold)) }
            Text(text).font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .foregroundStyle(foreground)
        .background(background, in: Capsule())
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = .jgPurple
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(color.opacity(configuration.isPressed ? 0.85 : 1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.jgPurple)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color.jgLilac.opacity(configuration.isPressed ? 0.7 : 1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct LogoBadge: View {
    let symbol: String
    let color: Color
    var size: CGFloat = 52

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            .fill(color.gradient)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: symbol)
                    .font(.system(size: size * 0.46, weight: .semibold))
                    .foregroundStyle(.white)
            )
    }
}

struct Avatar: View {
    let name: String
    var color: Color = .jgPurple
    var size: CGFloat = 44

    private var initials: String {
        let parts = name.split(separator: " ")
        return parts.prefix(2).compactMap { $0.first.map(String.init) }.joined()
    }

    var body: some View {
        Circle()
            .fill(color.gradient)
            .frame(width: size, height: size)
            .overlay(Text(initials).font(.system(size: size * 0.38, weight: .bold)).foregroundStyle(.white))
    }
}

enum Haptics {
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
