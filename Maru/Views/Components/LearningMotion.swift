import SwiftUI

enum LearningMotion {
    static let quickSpring = Animation.spring(response: 0.22, dampingFraction: 0.74)
    static let feedbackSpring = Animation.spring(response: 0.3, dampingFraction: 0.62)
    static let gentleSpring = Animation.spring(response: 0.38, dampingFraction: 0.78)
    static let quickFade = Animation.easeOut(duration: 0.14)

    static func animation(reduceMotion: Bool, spring: Animation = quickSpring) -> Animation {
        reduceMotion ? quickFade : spring
    }
}

private struct PulseOnChangeModifier<Value: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let value: Value
    let scale: CGFloat
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing && !reduceMotion ? scale : 1)
            .animation(LearningMotion.animation(reduceMotion: reduceMotion, spring: LearningMotion.feedbackSpring), value: isPulsing)
            .onChange(of: value) { _, _ in
                guard !reduceMotion else { return }
                isPulsing = true
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 130_000_000)
                    isPulsing = false
                }
            }
    }
}

private struct ShakeEffect: GeometryEffect {
    var travel: CGFloat = 7
    var shakes: CGFloat = 3
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: travel * sin(progress * .pi * shakes), y: 0))
    }
}

private struct ShakeOnChangeModifier<Value: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let value: Value
    let isActive: Bool
    @State private var progress: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(progress: reduceMotion ? 0 : progress))
            .onChange(of: value) { _, _ in
                guard isActive, !reduceMotion else { return }
                progress = 0
                withAnimation(.linear(duration: 0.26)) {
                    progress = 1
                }
            }
    }
}

extension View {
    func pulseOnChange<Value: Equatable>(_ value: Value, scale: CGFloat = 1.06) -> some View {
        modifier(PulseOnChangeModifier(value: value, scale: scale))
    }

    func shakeOnChange<Value: Equatable>(_ value: Value, isActive: Bool) -> some View {
        modifier(ShakeOnChangeModifier(value: value, isActive: isActive))
    }
}
