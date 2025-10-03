// Add this new file: OnboardingView.swift
import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    let onComplete: () -> Void
    
    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                VStack{
                    Spacer()
                    Text("Awareness is the first step to harmony.")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                    Image("Knot Heart")
                        .resizable()
                                        .scaledToFill() // Use scaledToFill to stretch across the width
                                        .frame(maxWidth: .infinity) // Expand to full width
                                        .frame(height: 220) // Set a fixed height to maintain aspect ratio
                                        //.clipped() // Clip any overflow to prevent stretching beyond bounds
                    Spacer()
                    
                    Button(action: {currentPage = 1} ) {
                        Text("Next")
                            .font(.headline)
                            .foregroundColor(.purple)
                            .padding()
                            .frame(maxWidth: 200)
                            .background(RoundedRectangle(cornerRadius: 60).stroke(.gray.opacity(0.5)))
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
                .frame(maxWidth: .infinity)
                .tag(0)
          
                VStack{
                    Spacer()
                    Text("Tap on the circle to log a conflict")
                        .font(.title)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                  
                    Image("Center Circle")
                        
                    Spacer()
                    
                    Button(action: {currentPage = 2} ) {
                        Text("Next")
                            .font(.headline)
                            .foregroundColor(.purple)
                            .padding()
                            .frame(maxWidth: 200)
                            .background(RoundedRectangle(cornerRadius: 60).stroke(.gray.opacity(0.5)))
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
                .tag(1)
             
                VStack{
                    Spacer()
                    Text("Slide to adjust the intensity")
                        .font(.title)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                  
                    Image("Slider")
                
             
                    Spacer()
                    Button(action: onComplete ) {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(.purple)
                            .padding()
                            .frame(maxWidth: 200)
                            .background(RoundedRectangle(cornerRadius: 60).stroke(.gray.opacity(0.5)))
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
                .tag(2)
               
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .ignoresSafeArea()
        .background()
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
