import SwiftUI

// MARK: - MaruMascot

struct MaruMascot: View {
    let expression: MascotExpression
    let size: CGFloat

    init(expression: MascotExpression = .happy, size: CGFloat = 120) {
        self.expression = expression
        self.size = size
    }

    var body: some View {
        ZStack {
            // Body with radial gradient
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "FFB6C1"), // light pink
                            Color(hex: "FF69B4")  // hot pink
                        ]),
                        center: .topLeading,
                        startRadius: size * 0.1,
                        endRadius: size * 0.8
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: Color(hex: "FF69B4").opacity(0.3), radius: 8, x: 0, y: 4)

            // Face
            faceView
                .frame(width: size * 0.7, height: size * 0.5)
        }
    }

    @ViewBuilder
    private var faceView: some View {
        switch expression {
        case .happy:
            happyFace
        case .thinking:
            thinkingFace
        case .celebrating:
            celebratingFace
        case .neutral:
            neutralFace
        case .sad:
            sadFace
        }
    }

    private var happyFace: some View {
        VStack(spacing: size * 0.08) {
            // Happy curved eyes
            HStack(spacing: size * 0.25) {
                eye(.happy)
                eye(.happy)
            }

            // Big smile
            MouthShape.smile
                .stroke(Color(hex: "4A4A4A"), lineWidth: 2)
                .frame(width: size * 0.3, height: size * 0.15)
        }
    }

    private var thinkingFace: some View {
        VStack(spacing: size * 0.08) {
            // One eye open, one closed
            HStack(spacing: size * 0.25) {
                eye(.happy) // closed happy eye
                Circle()
                    .fill(Color(hex: "4A4A4A"))
                    .frame(width: size * 0.08, height: size * 0.08)
            }

            // Small 'o' mouth
            MouthShape.oh
                .stroke(Color(hex: "4A4A4A"), lineWidth: 2)
                .frame(width: size * 0.12, height: size * 0.12)
        }
    }

    private var celebratingFace: some View {
        VStack(spacing: size * 0.08) {
            // Star eyes
            HStack(spacing: size * 0.25) {
                StarShape()
                    .fill(Color(hex: "FFD700"))
                    .frame(width: size * 0.12, height: size * 0.12)
                StarShape()
                    .fill(Color(hex: "FFD700"))
                    .frame(width: size * 0.12, height: size * 0.12)
            }

            // Open celebrating mouth
            MouthShape.celebrating
                .fill(Color(hex: "4A4A4A"))
                .frame(width: size * 0.25, height: size * 0.15)
        }
    }

    private var neutralFace: some View {
        VStack(spacing: size * 0.08) {
            // Simple dot eyes
            HStack(spacing: size * 0.25) {
                Circle()
                    .fill(Color(hex: "4A4A4A"))
                    .frame(width: size * 0.06, height: size * 0.06)
                Circle()
                    .fill(Color(hex: "4A4A4A"))
                    .frame(width: size * 0.06, height: size * 0.06)
            }

            // Straight line mouth
            MouthShape.neutral
                .stroke(Color(hex: "4A4A4A"), lineWidth: 2)
                .frame(width: size * 0.2, height: size * 0.05)
        }
    }

    private var sadFace: some View {
        VStack(spacing: size * 0.08) {
            // Downturned eyes
            HStack(spacing: size * 0.25) {
                eye(.sad)
                eye(.sad)
            }

            // Sad mouth
            MouthShape.sad
                .stroke(Color(hex: "4A4A4A"), lineWidth: 2)
                .frame(width: size * 0.2, height: size * 0.1)
        }
    }

    private func eye(_ type: EyeType) -> some View {
        Group {
            switch type {
            case .happy:
                Circle()
                    .fill(Color(hex: "4A4A4A"))
                    .frame(width: size * 0.06, height: size * 0.06)
            case .sad:
                Circle()
                    .fill(Color(hex: "4A4A4A"))
                    .frame(width: size * 0.06, height: size * 0.06)
            }
        }
    }

    enum EyeType {
        case happy
        case sad
    }
}

// MARK: - Supporting Shapes

private struct MouthShape {
    static var smile: some Shape {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 0))
            path.addQuadCurve(
                to: CGPoint(x: 1, y: 0),
                control: CGPoint(x: 0.5, y: 1)
            )
        }
    }

    static var oh: some Shape {
        Circle()
    }

    static var celebrating: some Shape {
        Capsule()
    }

    static var neutral: some Shape {
        Rectangle()
    }

    static var sad: some Shape {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 1))
            path.addQuadCurve(
                to: CGPoint(x: 1, y: 1),
                control: CGPoint(x: 0.5, y: 0)
            )
        }
    }
}

private struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let points = 4
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.4

        for i in 0..<(points * 2) {
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let angle = (CGFloat(i) * .pi / CGFloat(points)) - .pi / 2

            let point = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        path.closeSubpath()
        return path
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Previews

#Preview("MaruMascot - Happy") {
    MaruMascot(expression: .happy)
        .padding()
}

#Preview("MaruMascot - All Expressions") {
    HStack(spacing: 20) {
        ForEach(MascotExpression.allCases, id: \.self) { expression in
            VStack {
                MaruMascot(expression: expression, size: 80)
                Text(expression.rawValue.capitalized)
                    .font(.caption)
            }
        }
    }
    .padding()
}
