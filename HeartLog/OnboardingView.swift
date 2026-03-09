import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            Color("BackgroundPrimary")
                .ignoresSafeArea()

            // Top-left gradient glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "FFB52D").opacity(0.15), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .offset(x: -150, y: -250)

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Awareness is the first step to harmony.")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(Color("LabelPrimary"))
                        .lineSpacing(8)
                        .fixedSize(horizontal: false, vertical: true)
                        .minimumScaleFactor(0.5)
                        .padding(.horizontal, 32)
                        .padding(.trailing)
                        .padding(.top, 160)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()

                    AnimatedKnotHeart(
                        startAnimation: true,
                        strokeColor: Color("Orange"),
                        strokeWidth: 15,
                        animationDuration: 2.5
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .padding(.bottom, 60)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Button at bottom
                HStack {
                    Spacer()
                    Button(action: {
                        onComplete()
                    }) {
                        Text("Get Started →")
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(Color("White"))
                            .padding(.horizontal, 34)
                            .padding(.vertical, 16)
                            .background(Color("LabelPrimary"))
                            .clipShape(Capsule())
                    }
                    .padding(.trailing, 40)
                    .padding(.bottom)
                }
            }
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
        .preferredColorScheme(.dark)
}
