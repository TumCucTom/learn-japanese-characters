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
            DomeShape()
                .fill(
                    LinearGradient(
                        colors: [LearningTheme.red.opacity(0.94), LearningTheme.red],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    DomeShape()
                        .stroke(LearningTheme.line, lineWidth: max(2, size * 0.035))
                )
                .frame(width: size, height: size * 0.74)
                .shadow(color: LearningTheme.ink.opacity(0.14), radius: 0, x: 0, y: size * 0.045)

            faceView
                .frame(width: size * 0.72, height: size * 0.34)
                .offset(y: size * 0.08)
        }
        .frame(width: size, height: size * 0.82)
        .accessibilityLabel("Learning mascot")
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
        VStack(spacing: size * 0.04) {
            HStack(spacing: size * 0.22) {
                dotEye
                dotEye
            }
            CatSmile()
                .stroke(LearningTheme.ink, style: StrokeStyle(lineWidth: max(2, size * 0.032), lineCap: .round, lineJoin: .round))
                .frame(width: size * 0.28, height: size * 0.13)
        }
        .overlay(blush, alignment: .bottom)
    }

    private var thinkingFace: some View {
        VStack(spacing: size * 0.05) {
            HStack(spacing: size * 0.22) {
                WinkEye()
                    .stroke(LearningTheme.ink, style: StrokeStyle(lineWidth: max(2, size * 0.03), lineCap: .round))
                    .frame(width: size * 0.1, height: size * 0.05)
                dotEye
            }

            Circle()
                .stroke(LearningTheme.ink, lineWidth: max(2, size * 0.028))
                .frame(width: size * 0.11, height: size * 0.11)
        }
        .overlay(blush, alignment: .bottom)
    }

    private var celebratingFace: some View {
        VStack(spacing: size * 0.05) {
            HStack(spacing: size * 0.2) {
                SparkEye()
                    .fill(LearningTheme.yellow)
                    .overlay(SparkEye().stroke(LearningTheme.ink, lineWidth: max(1.5, size * 0.018)))
                    .frame(width: size * 0.12, height: size * 0.12)
                SparkEye()
                    .fill(LearningTheme.yellow)
                    .overlay(SparkEye().stroke(LearningTheme.ink, lineWidth: max(1.5, size * 0.018)))
                    .frame(width: size * 0.12, height: size * 0.12)
            }

            Capsule()
                .fill(LearningTheme.ink)
                .frame(width: size * 0.26, height: size * 0.13)
        }
        .overlay(blush, alignment: .bottom)
    }

    private var neutralFace: some View {
        VStack(spacing: size * 0.07) {
            HStack(spacing: size * 0.22) {
                dotEye
                dotEye
            }

            Capsule()
                .fill(LearningTheme.ink)
                .frame(width: size * 0.2, height: max(2, size * 0.024))
        }
    }

    private var sadFace: some View {
        VStack(spacing: size * 0.05) {
            HStack(spacing: size * 0.2) {
                SadEye()
                    .stroke(LearningTheme.ink, style: StrokeStyle(lineWidth: max(2, size * 0.028), lineCap: .round))
                    .frame(width: size * 0.1, height: size * 0.05)
                SadEye()
                    .stroke(LearningTheme.ink, style: StrokeStyle(lineWidth: max(2, size * 0.028), lineCap: .round))
                    .frame(width: size * 0.1, height: size * 0.05)
            }

            Frown()
                .stroke(LearningTheme.ink, style: StrokeStyle(lineWidth: max(2, size * 0.03), lineCap: .round))
                .frame(width: size * 0.22, height: size * 0.1)
        }
    }

    private var dotEye: some View {
        Circle()
            .fill(LearningTheme.ink)
            .frame(width: size * 0.105, height: size * 0.105)
    }

    private var blush: some View {
        HStack(spacing: size * 0.36) {
            BlushMark()
            BlushMark()
        }
        .foregroundColor(Color.white.opacity(0.5))
        .frame(height: size * 0.1)
        .offset(y: size * 0.06)
    }
}

// MARK: - Supporting Shapes

private struct DomeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control: CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.12)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct CatSmile: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let mid = CGPoint(x: rect.midX, y: rect.midY)
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: mid)
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.midY), control: CGPoint(x: rect.width * 0.28, y: rect.maxY))
        path.move(to: mid)
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY), control: CGPoint(x: rect.width * 0.72, y: rect.maxY))
        return path
    }
}

private struct WinkEye: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY), control: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

private struct SadEye: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.midX, y: rect.minY))
        return path
    }
}

private struct Frown: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.midX, y: rect.minY))
        return path
    }
}

private struct SparkEye: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.42

        for index in 0..<8 {
            let radius = index.isMultiple(of: 2) ? outerRadius : innerRadius
            let angle = CGFloat(index) * .pi / 4 - .pi / 2
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            index == 0 ? path.move(to: point) : path.addLine(to: point)
        }

        path.closeSubpath()
        return path
    }
}

private struct BlushMark: View {
    var body: some View {
        HStack(spacing: 2) {
            Capsule().frame(width: 4, height: 11).rotationEffect(.degrees(28))
            Capsule().frame(width: 4, height: 11).rotationEffect(.degrees(28))
            Capsule().frame(width: 4, height: 11).rotationEffect(.degrees(28))
        }
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
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
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

#Preview("Learning Mascot") {
    VStack(spacing: 28) {
        ForEach(MascotExpression.allCases, id: \.self) { expression in
            MaruMascot(expression: expression, size: 120)
        }
    }
    .padding()
    .background(LearningTheme.cream)
}
