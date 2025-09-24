import SwiftUI

struct SteppedSlider: View {
    @Binding var value: ConflictIntensity
    private let steps = ConflictIntensity.allCases.count
    
    private let trackHeight: CGFloat = 56
    private let thumbSize: CGFloat = 40
    
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let usableWidth = totalWidth - thumbSize // keep thumb inside with margin
            let stepWidth = usableWidth / CGFloat(steps - 1)
            
            ZStack {
                // Track
                Capsule()
                    .fill(Color("Purple"))
                    .frame(height: trackHeight)
                    .padding(.horizontal, -10) // margin for thumb ends
                
                // Stops (ticks)
                HStack {
                    ForEach(0..<steps) { i in
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 8, height: 8)
                        if i < steps - 1 { Spacer() }
                    }
                }
                .padding(.horizontal, thumbSize / 2)
                
                // Thumb
                Circle()
                    .fill(Color("WhiteAlt"))
                    //.stroke(Color("White"), lineWidth: 2)
                    .frame(width: thumbSize, height: thumbSize)
                    .offset(x: currentThumbX(usableWidth: usableWidth, stepWidth: stepWidth))
                    .gesture(
                        DragGesture()
                            .onChanged { drag in
                                // Clamp drag so thumb stays inside track
                                let minX = -stepWidth * CGFloat(value.rawValue)
                                let maxX = stepWidth * CGFloat((steps - 1) - value.rawValue)
                                dragOffset = min(max(drag.translation.width, minX), maxX)
                            }
                            .onEnded { drag in
                                // Snap to nearest stop
                                let currentX = stepWidth * CGFloat(value.rawValue) + dragOffset
                                let nearestIndex = Int((currentX / stepWidth).rounded())
                                withAnimation(.spring()) {
                                    value = ConflictIntensity(rawValue: min(max(nearestIndex, 0), steps - 1)) ?? .moderate
                                    dragOffset = 0
                                }
                            }
                    )
            }
            .frame(height: thumbSize)
            .sensoryFeedback(.impact(flexibility: .solid, intensity: 1), trigger: value) // Feedback on value change
        }
        .frame(height: thumbSize * 2)
    }
    
    private func currentThumbX(usableWidth: CGFloat, stepWidth: CGFloat) -> CGFloat {
        // base X centered on track + drag offset
        let baseX = stepWidth * CGFloat(value.rawValue) - usableWidth / 2
        return baseX + dragOffset
    }
}

#Preview {
    SteppedSlider(value: .constant(.moderate))
        .preferredColorScheme(.dark)
}
