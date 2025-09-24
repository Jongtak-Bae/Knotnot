import SwiftUI
import Foundation
import CoreData
import UIKit

struct MainView: View {
    @Environment(\.managedObjectContext) private var viewContext
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
    
    // Generate past 5 dates including today
    private var pastFiveDates: [Date] {
        let today = Date()
        let calendar = Calendar.current
        return (0..<5).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }.reversed()
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
                                        centeredIndex: centeredIndex,
                                        conflicts: conflicts,
                                        selectedDateIndex: $selectedDateIndex,
                                        scrollPosition: $scrollPosition,
                                        onTap: { saveConflictForTap(index: index, date: date) }
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
                        .onChange(of: scrollPosition) {
                            centeredIndex = scrollPosition ?? 0
                            if let conflict = conflicts.first(where: { Calendar.current.isDate($0.date!, inSameDayAs: pastFiveDates[centeredIndex]) }) {
                                selectedPerson = conflict.person ?? "Him"
                                intensity = ConflictIntensity(string: conflict.intensity) ?? .moderate
                                userText = conflict.notes ?? ""
                            } else {
                                intensity = .moderate
                                userText = ""
                            }
                        }
                        .onAppear {
                            scrollPosition = pastFiveDates.count - 1
                        }
                    }
                    
                    // Intensity Slider
                    SteppedSlider(value: $intensity)
                        .frame(width: 150, height: 56)
                        .onChange(of: intensity) {
                            // Only save if a conflict exists or user intends to create one
                            if conflicts.contains(where: { Calendar.current.isDate($0.date!, inSameDayAs: pastFiveDates[centeredIndex]) }) {
                                saveConflictForCenteredDate(notes: userText)
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
                    saveConflictForCenteredDate(notes: notes)
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

    private func saveConflictForCenteredDate(notes: String) {
        let date = pastFiveDates[centeredIndex]
        if let existingConflict = conflicts.first(where: { Calendar.current.isDate($0.date!, inSameDayAs: date) }) {
            viewContext.delete(existingConflict)
        }
        let newConflict = Conflict(context: viewContext)
        newConflict.id = UUID()
        newConflict.date = date
        newConflict.person = selectedPerson
        newConflict.notes = notes
        newConflict.intensity = intensity.stringValue
        do {
            try viewContext.save()
        } catch {
            print("Error saving conflict: \(error)")
        }
    }

    private func saveSelectedPersonForCenteredDate() {
        let date = pastFiveDates[centeredIndex]
        if let existingConflict = conflicts.first(where: { Calendar.current.isDate($0.date!, inSameDayAs: date) }) {
            viewContext.delete(existingConflict)
        }
        let newConflict = Conflict(context: viewContext)
        newConflict.id = UUID()
        newConflict.date = date
        newConflict.person = selectedPerson
        newConflict.notes = userText
        newConflict.intensity = intensity.stringValue
        do {
            try viewContext.save()
        } catch {
            print("Error saving conflict: \(error)")
        }
    }

    private func saveConflictForTap(index: Int, date: Date) {
        // Toggle conflict: if exists, delete; if not, create with current intensity
        if let existingConflict = conflicts.first(where: { Calendar.current.isDate($0.date!, inSameDayAs: date) }) {
            viewContext.delete(existingConflict)
        } else {
            let newConflict = Conflict(context: viewContext)
            newConflict.id = UUID()
            newConflict.date = date
            newConflict.person = selectedPerson
            newConflict.notes = userText
            newConflict.intensity = intensity.stringValue
        }
        do {
            try viewContext.save()
        } catch {
            print("Error saving conflict: \(error)")
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
        .preferredColorScheme(.dark)
}
