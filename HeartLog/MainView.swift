import SwiftUI
import Foundation
import CoreData
import UIKit

struct MainView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var conflictManager: ConflictManager
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Conflict.date, ascending: true)],
        animation: .default)
    private var conflicts: FetchedResults<Conflict>
    
    @State private var selectedPerson: String = "Him"
    @State private var isSheetPresented = false
    @State private var userText: String = ""
    @State private var selectedDateIndex: Int? = nil
    @State private var centeredIndex: Int = 0
    @State private var scrollPosition: Int? = nil
    
    @State private var intensity: ConflictIntensity = .moderate // Conflict intensity
    
    @State private var selectedCircle: Int? = nil
    @Namespace private var animation
    
    // Generate five past days including today
    private var pastFiveDates: [Date] {
        let today = Calendar.current.startOfDay(for: Date()) // Normalize to start of day
        let calendar = Calendar.current
        return (0...4).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }.reversed()
    }
    
    var body: some View {
        ZStack {
            VStack(alignment: .center) {
               
                VStack {
                    // MARK: Date
                    VStack(alignment: .leading) {
                        Text(year(from: pastFiveDates[centeredIndex]))
                            .font(.largeTitle)
                            .bold()
                            .foregroundStyle(.gray)
                        
                        Text(dayAndMonth(from: pastFiveDates[centeredIndex]))
                            .font(.system(size: 48))
                            .fontWeight(.semibold)
                    }
                    
                    // MARK: Carousel
                    ZStack {
                        RoundedRectangle(cornerRadius: 70)
                            .frame(width: 140, height: 200)
                            .offset(x: 0, y: -30)
                            .foregroundStyle(Color("Purple"))
                        
                        ScrollView(.horizontal) {
                            LazyHStack(spacing: 0.0) {
                                ForEach(Array(pastFiveDates.enumerated()), id: \.offset) { index, date in
                                    DateCircleView(
                                        date: date,
                                        index: index,
                                        centeredIndex: centeredIndex, // Pass dynamic centeredIndex
                                        conflicts: conflicts,
                                        selectedDateIndex: $selectedDateIndex,
                                        scrollPosition: $scrollPosition,
                                        onTap: { toggleConflictForDate(date: date, index: index) }
                                    )
                                    .containerRelativeFrame(.horizontal)
                                    .scrollTransition { content, phase in
                                        content
                                            .scaleEffect(phase.isIdentity ? 1.2 : 0.8)
                                            .opacity(phase.isIdentity ? 1.0 : 0.5)
                                    }
                                }
                            }
                            .scrollTargetLayout()
                        }
                        .contentMargins(120.0, for: .scrollContent)
                        .scrollTargetBehavior(.viewAligned)
                        .scrollIndicators(.hidden)
                        .frame(height: 250)
                        .scrollPosition(id: $scrollPosition)

                        .onChange(of: scrollPosition) { _, newValue in
                            centeredIndex = newValue ?? 0
                            refreshUIState(for: pastFiveDates[centeredIndex])
                        }
                        .onAppear {
                            scrollPosition = pastFiveDates.count - 1
                        }
                    }
                    
                    
                  
                        Text(intensity.displayName)
                        .foregroundStyle(Color(hex: "#7F809E"))
                        .padding(.bottom)
                        
                        // Intensity Slider
                        SteppedSlider(value: $intensity)
                            .frame(width: 150, height: 56)
                            .onChange(of: intensity) { _, _ in
                                Task { @MainActor in
                                    do {
                                        let centerDate = pastFiveDates[centeredIndex]
                                        // Fetch synchronously to check existence
                                        if try conflictManager.fetchConflict(for: centerDate) != nil {
                                            try await conflictManager.saveConflict(
                                                date: centerDate,
                                                person: selectedPerson,
                                                notes: userText,
                                                intensity: intensity
                                            )
                                        }
                                    } catch {
                                        print("Error saving conflict: \(error)")
                                    }
                                }
                            }
                  
                    
                }
                .padding(.top, 120)
                
                
                // MARK: Notes Display
                let currentNotes = conflicts.first { Calendar.current.isDate($0.date!, inSameDayAs: pastFiveDates[centeredIndex]) }?.notes ?? ""
                
                if currentNotes.isEmpty {
                    // Show "Add Note" button when there are no notes
                    Button(action: {
                        let date = pastFiveDates[centeredIndex]
                        userText = ""
                        isSheetPresented = true
                    }) {
                        HStack {
                            Text("Add Note")
                                .foregroundColor(.primary.opacity(0.5))
                                .frame(width: 120)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 60).stroke(.gray.opacity(0.5)))
                    }
                } else {
                    // Show notes in a card with an "Edit" button
                    ZStack(alignment: .bottomTrailing) {
                        Text(currentNotes)
                            .font(.title2)
                            //.foregroundColor(.gray)
                            .padding()
                            .padding(.trailing, 40)
                            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(.gray.opacity(0.5), lineWidth: 1)
                                    .fill(Color("White"))
                            )
                            .padding(.horizontal)
                        
                        Button(action: {
                            let date = pastFiveDates[centeredIndex]
                            userText = currentNotes
                            isSheetPresented = true
                        }) {
                            Image(systemName: "pencil")
                                .font(.title)
                                .foregroundColor(.gray)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 60).stroke(.gray.opacity(0.5)))
                                .offset(x:-20)
                        }
                        .padding([.trailing, .bottom], 8)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
        }
        .background(
//            RadialGradient(gradient: Gradient(colors: [.red, .yellow, .green, .blue, .purple]), center: .topLeading, startRadius: 50, endRadius: 100)
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    .init(x: 0, y: 0), .init(x: 0.8, y: 0),.init(x: 1, y: 0),
                    .init(x: 0, y: 0.2), .init(x: 0.1, y: 0.5),.init(x: 1, y: 0.5),
                    .init(x: 0, y: 1), .init(x: 0, y: 1),.init(x: 1, y: 1)
                ] ,
                colors: [
                    Color(hex: "#EAAB04").opacity(0.2), Color(hex: "#A640BC").opacity(0.2),Color(hex: "#A640BC").opacity(0.2),
                    .clear, .clear, .clear,
                    .clear, .clear, .clear
                ]
            )
        )
        .ignoresSafeArea()
        .sheet(isPresented: $isSheetPresented) {
                        NoteSheet(
                            userText: $userText,
                            isPresented: $isSheetPresented,
                            onSave: { notes in
                                Task {
                                    do {
                                        try await conflictManager.saveConflict(
                                            date: pastFiveDates[centeredIndex],
                                            person: selectedPerson,
                                            notes: notes,
                                            intensity: intensity
                                        )
                                    } catch {
                                        print("Error saving conflict: \(error)")
                                    }
                                }
                            }
                        )
                    }
    }

    // MARK: - Functions
    private func dayOfWeek(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    private func dayAndMonth(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: date)
    }

    private func year(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }

    private func refreshUIState(for date: Date) {
        if let conflict = conflicts.first(where: { Calendar.current.isDate($0.date!, inSameDayAs: date) }) {
            selectedPerson = conflict.person ?? "Him"
            intensity = ConflictIntensity(string: conflict.intensity) ?? .moderate
            userText = conflict.notes ?? ""
        } else {
            intensity = .moderate
            userText = ""
        }
    }

    private func toggleConflictForDate(date: Date, index: Int) {
        Task {
            do {
                // If not centered, scroll to center it first
                if index != centeredIndex {
                    withAnimation(.spring()) {
                        scrollPosition = index
                    }
                    // Wait briefly for scroll to complete and centeredIndex to update
                    try await Task.sleep(nanoseconds: 300_000_000) // 0.3s delay
                }
                let centerDate = pastFiveDates[centeredIndex]
                try await conflictManager.toggleConflict(
                    date: centerDate,
                    person: selectedPerson,
                    notes: userText,
                    intensity: intensity
                )
                // Refresh UI state after toggle (FetchRequest will update conflicts)
                refreshUIState(for: centerDate)
            } catch {
                print("Error toggling conflict: \(error)")
            }
        }
    }
}

// MARK: - Date Circle View
struct DateCircleView: View {
    let date: Date
    let index: Int
    let centeredIndex: Int
    let conflicts: FetchedResults<Conflict>
    @Binding var selectedDateIndex: Int?
    @Binding var scrollPosition: Int?
    let onTap: () -> Void
    
    private func hasConflict() -> Bool {
        conflicts.contains { Calendar.current.isDate($0.date!, inSameDayAs: date) }
    }
    
    private func conflictIntensity() -> ConflictIntensity {
        conflicts.first { Calendar.current.isDate($0.date!, inSameDayAs: date) }
            .flatMap { ConflictIntensity(string: $0.intensity) } ?? .moderate
    }
    
    var body: some View {
        ZStack {
            Text(dayOfWeek(from: date))
                .offset(x: 0, y: -75)
                .font(.title)
                .foregroundStyle(Color(hex: "#7F809E"))
            
            ZStack {
                let circleColor: Color = hasConflict() ? conflictIntensity().color : .clear
                let circleText: String = {
                    switch conflictIntensity() {
                    case .minor: return "☹️"
                    case .moderate: return "😡"
                    case .severe: return "👿"
                    }
                }()
                
                // Circle
                Circle()
                    .fill(circleColor)
                    .stroke(hasConflict() ? circleColor : Color(hex: "#7F809E").opacity(0.5), lineWidth: 2)
                    .frame(width: 100, height: 100)
                
                // Text
                Text(hasConflict() ? circleText : "\(Calendar.current.component(.day, from: date))")
                    .font(.largeTitle)
                    .foregroundStyle(hasConflict() ? Color.white : Color(hex: "#7F809E"))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if index == centeredIndex {
                onTap() // Toggle conflict
                // Trigger haptic feedback for conflict toggle
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.7)
            } else {
                withAnimation(.spring()) {
                    scrollPosition = index
                    selectedDateIndex = index
                }
            }
        }
        .sensoryFeedback(.impact(flexibility: .solid, intensity: 0.5), trigger: selectedDateIndex)
    }
    
    private func dayOfWeek(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

#Preview {
      MainView()
          .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
          .environmentObject(ConflictManager(context: PersistenceController.shared.container.viewContext))
          .preferredColorScheme(.dark)
  }

