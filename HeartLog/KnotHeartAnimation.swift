//
//  KnotHeartAnimation.swift
//  HeartLog
//
//  Animated rope drawing effect for onboarding
//

import SwiftUI

struct KnotHeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.size.width
        let height = rect.size.height

        // Start from LEFT side
        path.move(to: CGPoint(x: 0.00038*width, y: 0.55426*height))

        // Go UP to middle-left
        path.addCurve(to: CGPoint(x: 0.25275*width, y: 0.47626*height),
                      control1: CGPoint(x: 0.07971*width, y: 0.55799*height),
                      control2: CGPoint(x: 0.17017*width, y: 0.5275*height))

        // Continue UP to top center through right path
        path.addCurve(to: CGPoint(x: 0.49949*width, y: 0.18192*height),
                      control1: CGPoint(x: 0.36642*width, y: 0.40573*height),
                      control2: CGPoint(x: 0.46517*width, y: 0.29591*height))

        // Draw RIGHT HALF: from top center to right top loop
        path.addCurve(to: CGPoint(x: 0.65748*width, y: 0.04008*height),
                      control1: CGPoint(x: 0.51594*width, y: 0.12814*height),
                      control2: CGPoint(x: 0.57283*width, y: -0.00172*height))

        // Right top loop down to middle-right
        path.addCurve(to: CGPoint(x: 0.74622*width, y: 0.47626*height),
                      control1: CGPoint(x: 0.74396*width, y: 0.08278*height),
                      control2: CGPoint(x: 0.77806*width, y: 0.31415*height))

        // Middle-right down to right bottom section
        path.addCurve(to: CGPoint(x: 0.73737*width, y: 0.51348*height),
                      control1: CGPoint(x: 0.74369*width, y: 0.48915*height),
                      control2: CGPoint(x: 0.74074*width, y: 0.5016*height))

        // Right side DOWN to bottom center (heart point)
        path.addCurve(to: CGPoint(x: 0.49949*width, y: 0.96029*height),
                      control1: CGPoint(x: 0.70074*width, y: 0.64256*height),
                      control2: CGPoint(x: 0.60362*width, y: 0.83972*height))

        // Draw LEFT HALF: bottom center UP to left bottom section
        path.addCurve(to: CGPoint(x: 0.26161*width, y: 0.51348*height),
                      control1: CGPoint(x: 0.39536*width, y: 0.83972*height),
                      control2: CGPoint(x: 0.29823*width, y: 0.64256*height))

        // Left bottom section up to middle-left
        path.addCurve(to: CGPoint(x: 0.25275*width, y: 0.47626*height),
                      control1: CGPoint(x: 0.25823*width, y: 0.5016*height),
                      control2: CGPoint(x: 0.25529*width, y: 0.48915*height))

        // Middle-left up to top left loop
        path.addCurve(to: CGPoint(x: 0.3415*width, y: 0.04008*height),
                      control1: CGPoint(x: 0.22092*width, y: 0.31415*height),
                      control2: CGPoint(x: 0.25502*width, y: 0.08278*height))

        // Left top loop to top center
        path.addCurve(to: CGPoint(x: 0.49949*width, y: 0.18192*height),
                      control1: CGPoint(x: 0.42615*width, y: -0.00172*height),
                      control2: CGPoint(x: 0.48303*width, y: 0.12814*height))

        // Top center down to middle-right
        path.addCurve(to: CGPoint(x: 0.74622*width, y: 0.47626*height),
                      control1: CGPoint(x: 0.5338*width, y: 0.29591*height),
                      control2: CGPoint(x: 0.63255*width, y: 0.40573*height))

        // EXIT from middle-right to RIGHT side
        path.addCurve(to: CGPoint(x: 0.99859*width, y: 0.55426*height),
                      control1: CGPoint(x: 0.8288*width, y: 0.5275*height),
                      control2: CGPoint(x: 0.91926*width, y: 0.55799*height))

        return path
    }
}

struct AnimatedKnotHeart: View {
    @State private var animationProgress: CGFloat = 0
    let startAnimation: Bool
    let strokeColor: Color
    let strokeWidth: CGFloat
    let animationDuration: Double

    init(
        startAnimation: Bool = true,
        strokeColor: Color = .purple,
        strokeWidth: CGFloat = 3,
        animationDuration: Double = 2.5
    ) {
        self.startAnimation = startAnimation
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.animationDuration = animationDuration
    }

    var body: some View {
        KnotHeartShape()
            .trim(from: 0, to: animationProgress)
            .stroke(
                strokeColor,
                style: StrokeStyle(
                    lineWidth: strokeWidth,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
            .onAppear {
                if startAnimation {
                    withAnimation(.easeInOut(duration: animationDuration)) {
                        animationProgress = 1.0
                    }
                }
            }
    }
}

struct KnotHeartAnimation_Previews: PreviewProvider {
    static var previews: some View {
        AnimatedKnotHeart(startAnimation: true)
            .frame(height: 220)
            .background(Color.gray.opacity(0.1))
    }
}
