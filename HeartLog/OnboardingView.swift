// Add this new file: OnboardingView.swift
import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Background color
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
                TabView(selection: $currentPage) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Title text
                        Text("Awareness is the first step to harmony.")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(.black)
                            .lineSpacing(8)
                            .fixedSize(horizontal: false, vertical: true)
                            .minimumScaleFactor(0.5)
                            .padding(.horizontal, 32)
                            .padding(.trailing)
                            .padding(.top, 160)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Spacer()

                        // Animated knot heart
                        AnimatedKnotHeart(
                            startAnimation: currentPage == 0,
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
                    .tag(0)

                    VStack(alignment: .center, spacing: 0) {
                        Spacer()

                        Text("Tap on the circle to log a conflict")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(.black)
                            .lineSpacing(8)
                            .fixedSize(horizontal: false, vertical: true)
                            .minimumScaleFactor(0.5)
                            .padding(.horizontal, 32)
                            .padding(.top, 160)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        LottieView(
                            animationName: "Center Circle",
                            loopMode: .loop,
                            animationSpeed: 1.0
                        )
                        .frame(width: 280, height: 280)
                        .padding(.vertical, 40)

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tag(1)

                    VStack(alignment: .center, spacing: 0) {
                        Spacer()

                        Text("Slide to adjust the intensity")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(.black)
                            .lineSpacing(8)
                            .fixedSize(horizontal: false, vertical: true)
                            .minimumScaleFactor(0.5)
                            .padding(.horizontal, 32)
                            .padding(.top, 160)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        LottieView(
                            animationName: "Slider",
                            loopMode: .loop,
                            animationSpeed: 1.0
                        )
                        .frame(width: 280, height: 280)
                        .padding(.vertical, 40)

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Fixed button at bottom
                HStack {
                    Spacer()
                    Button(action: {
                        if currentPage < 2 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            onComplete()
                        }
                    }) {
                        Text(currentPage == 2 ? "Get Started →" : "Next →")
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(.white)
                            .padding(.horizontal, 34)
                            .padding(.vertical, 16)
                            .background(Color("LabelPrimary"))
                            .clipShape(Capsule())
                    }
                    .padding(.trailing, 40)
                    .padding(.bottom)
                }
            }

            // Custom page control - left bottom corner, positioned absolutely
            VStack {
                Spacer()
                HStack {
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.black : Color.black.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.leading, 40)
                    .padding(.bottom, 40)
                    Spacer()
                }
            }
        }
    }
}

struct OnboardingPage: View {
    let imageName: String
    let title: String
    let description: String
    let buttonText: String
    let onButtonTap: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(Color(hex: "#A640BC"))
            
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            Button(action: onButtonTap) {
                Text(buttonText)
                    .font(.headline)
                    .foregroundColor(.purple)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(RoundedRectangle(cornerRadius: 60).stroke(.gray.opacity(0.5)))
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
//        .preferredColorScheme(.dark)
}
