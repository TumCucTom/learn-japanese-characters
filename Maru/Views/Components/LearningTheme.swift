import SwiftUI

enum LearningTheme {
    static let cream = Color(hex: "FFFDF8")
    static let warmCream = Color(hex: "f7f5f1")
    static let ink = Color(hex: "171514")
    static let mutedInk = Color(hex: "5b554d")
    static let softInk = Color(hex: "8c867d")
    static let card = Color.white
    static let line = Color(hex: "171514")
    static let red = Color(hex: "EF3138")
    static let redDark = Color(hex: "C91520")
    static let redSoft = Color(hex: "FFE1E3")
    static let yellow = Color(hex: "FFCA0A")
    static let yellowSoft = Color(hex: "FFF4B8")
    static let green = Color(hex: "34D399")
    static let greenSoft = Color(hex: "DDF8E9")
    static let locked = Color(hex: "ECE7DC")
    static let purple = Color(hex: "8B5CF6")

    static let heavyLine: CGFloat = 3
    static let cardRadius: CGFloat = 12
}

struct LearningOutlinedButtonStyle: ButtonStyle {
    var fill: Color = LearningTheme.card
    var pressedFill: Color = LearningTheme.yellowSoft

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? pressedFill : fill)
            .clipShape(RoundedRectangle(cornerRadius: LearningTheme.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LearningTheme.cardRadius, style: .continuous)
                    .stroke(LearningTheme.line, lineWidth: LearningTheme.heavyLine)
            )
            .shadow(color: LearningTheme.ink.opacity(configuration.isPressed ? 0 : 0.12), radius: 0, x: 0, y: configuration.isPressed ? 0 : 4)
            .offset(y: configuration.isPressed ? 3 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

struct LearningBadge: View {
    let text: String
    var color: Color = LearningTheme.red

    var body: some View {
        Text(text)
            .font(.system(size: 18, weight: .black, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct LearningPattern: View {
    private let symbols = ["あ", "カ", "星", "雲", "A", "日"]

    var body: some View {
        GeometryReader { proxy in
            ForEach(0..<18, id: \.self) { index in
                Text(symbols[index % symbols.count])
                    .font(.system(size: CGFloat(28 + (index % 4) * 8), weight: .black, design: .rounded))
                    .foregroundColor(LearningTheme.locked)
                    .rotationEffect(.degrees(Double((index * 29) % 42) - 21))
                    .position(
                        x: CGFloat((index * 73) % max(Int(proxy.size.width), 1)),
                        y: CGFloat((index * 137) % max(Int(proxy.size.height), 1))
                    )
            }
        }
    }
}
