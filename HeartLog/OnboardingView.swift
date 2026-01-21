// Add this new file: OnboardingView.swift
import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Background color
            Color(hex: "fff8ee")
                .ignoresSafeArea()

            // Top-left gradient glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.purple.opacity(0.15), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .offset(x: -150, y: -250)

            VStack {
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
                            .padding(.top, 160)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Spacer()

                        // Animated knot heart
                        AnimatedKnotHeart(
                            startAnimation: currentPage == 0,
                            strokeColor: Color(hex: "DC12E8"),
                            strokeWidth: 10,
                            animationDuration: 2.5
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .padding(.bottom, 60)

                        Spacer()

                        // Next button
                        HStack {
                            Spacer()
                            Button(action: { currentPage = 1 }) {
                                Text("Next →")
                                    .font(.system(size: 24, weight: .light))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 34)
                                    .padding(.vertical, 16)
                                    .background(Color(hex: "1b1b1b"))
                                    .clipShape(Capsule())
                            }
                            .padding(.trailing, 40)
                            .padding(.bottom, 80)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tag(0)
          
                    VStack(alignment: .center, spacing: 0) {
                        Spacer()

                        Text("Tap on the circle to log a conflict")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        Image("Center Circle")
                            .padding(.vertical, 40)

                        Spacer()

                        HStack {
                            Spacer()
                            Button(action: { currentPage = 2 }) {
                                Text("Next →")
                                    .font(.system(size: 24, weight: .light))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 34)
                                    .padding(.vertical, 16)
                                    .background(Color(hex: "1b1b1b"))
                                    .clipShape(Capsule())
                            }
                            .padding(.trailing, 40)
                            .padding(.bottom, 80)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tag(1)
             
                    VStack(alignment: .center, spacing: 0) {
                        Spacer()

                        Text("Slide to adjust the intensity")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        Image("Slider")
                            .padding(.vertical, 40)

                        Spacer()

                        HStack {
                            Spacer()
                            Button(action: onComplete) {
                                Text("Get Started →")
                                    .font(.system(size: 24, weight: .light))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 34)
                                    .padding(.vertical, 16)
                                    .background(Color(hex: "1b1b1b"))
                                    .clipShape(Capsule())
                            }
                            .padding(.trailing, 40)
                            .padding(.bottom, 80)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tag(2)
               
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
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
