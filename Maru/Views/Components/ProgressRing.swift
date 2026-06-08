import SwiftUI

// MARK: - ProgressRing

struct ProgressRing: View {
    let progress: Double // 0.0 to 1.0
    let lineWidth: CGFloat
    let size: CGFloat

    init(progress: Double, lineWidth: CGFloat = 8, size: CGFloat = 60) {
        self.progress = min(max(progress, 0), 1)
        self.lineWidth = lineWidth
        self.size = size
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(
                    Color(hex: "e4ded4"),
                    lineWidth: lineWidth
                )

            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressGradient,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)

            // Percentage text
            Text("\(Int(progress * 100))%")
                .font(.system(size: size * 0.22, weight: .semibold))
                .foregroundColor(Color(hex: "22211F"))
        }
        .frame(width: size, height: size)
    }

    private var progressGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "8B5CF6"), // purple start
                Color(hex: "FF7A1A")  // orange end
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - MasteryBadge

struct MasteryBadge: View {
    let level: AppConstants.MasteryLevel

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconName)
                .font(.system(size: 12, weight: .semibold))

            Text(level.displayName)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(textColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(backgroundColor)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private var iconName: String {
        switch level {
        case .new:
            return "sparkle"
        case .learning:
            return "book"
        case .familiar:
            return "lightbulb"
        case .mastered:
            return "star.fill"
        }
    }

    private var backgroundColor: Color {
        switch level {
        case .new:
            return Color(hex: "f7f5f1")
        case .learning:
            return Color(hex: "e8dff5")
        case .familiar:
            return Color(hex: "fff3e8")
        case .mastered:
            return Color(hex: "f2f7ef")
        }
    }

    private var textColor: Color {
        switch level {
        case .new:
            return Color(hex: "5b554d")
        case .learning:
            return Color(hex: "8B5CF6")
        case .familiar:
            return Color(hex: "FF7A1A")
        case .mastered:
            return Color(hex: "34D399")
        }
    }

    private var borderColor: Color {
        switch level {
        case .new:
            return Color(hex: "e4ded4")
        case .learning:
            return Color(hex: "8B5CF6").opacity(0.3)
        case .familiar:
            return Color(hex: "FF7A1A").opacity(0.3)
        case .mastered:
            return Color(hex: "34D399").opacity(0.3)
        }
    }
}

// MARK: - MasteryLevel Extension

extension AppConstants.MasteryLevel {
    var displayName: String {
        switch self {
        case .new:
            return "New"
        case .learning:
            return "Learning"
        case .familiar:
            return "Familiar"
        case .mastered:
            return "Mastered"
        }
    }
}

// MARK: - Previews

#Preview("ProgressRing") {
    VStack(spacing: 20) {
        ProgressRing(progress: 0.0)
        ProgressRing(progress: 0.25)
        ProgressRing(progress: 0.5)
        ProgressRing(progress: 0.75)
        ProgressRing(progress: 1.0)
    }
    .padding()
}

#Preview("MasteryBadge") {
    VStack(spacing: 16) {
        ForEach([AppConstants.MasteryLevel.new, .learning, .familiar, .mastered], id: \.self) { level in
            MasteryBadge(level: level)
        }
    }
    .padding()
}
