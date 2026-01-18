import SwiftUI

struct ConflictEditorView: View {
    @EnvironmentObject private var conflictManager: ConflictManager
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Conflict.date, ascending: true)],
        animation: .default)
    private var conflicts: FetchedResults<Conflict>

    let dates: [Date]
    let initialDate: Date

    @State private var centeredIndex: Int
    @State private var scrollPosition: Int?

    @State private var selectedPerson: String = "Him"
    @State private var intensity: ConflictIntensity = .moderate
    @State private var userText: String = ""
    @State private var isSheetPresented = false
    @State private var selectedEmotions: Set<String> = []

    init(dates: [Date], initialDate: Date) {
        self.dates = dates
        self.initialDate = initialDate
        let index = dates.firstIndex(where: {
            Calendar.current.isDate($0, inSameDayAs: initialDate)
        }) ?? 0
        _centeredIndex = State(initialValue: index)
        _scrollPosition = State(initialValue: index)
        
    }
    
    var body: some View {
        VStack {
            Spacer()
            // MARK: Date header
            VStack(alignment: .leading) {
                Text(year(from: dates[centeredIndex]))
                    .font(.largeTitle)
                    .foregroundStyle(.gray)
                
                Text(dayAndMonth(from: dates[centeredIndex]))
                    .font(.system(size: 48))
                    .fontWeight(.semibold)
            }
            ZStack{
                RoundedRectangle(cornerRadius: 70)
                    .frame(width: 140, height: 200)
                    .offset(x: 0, y: -30)
                    .foregroundStyle(Color("Purple"))
                // MARK: Carousel (unchanged)
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 0) {
                        ForEach(Array(dates.enumerated()), id: \.offset) { index, date in
                            DateCircleView(
                                date: date,
                                index: index,
                                centeredIndex: centeredIndex,
                                conflicts: conflicts,
                                selectedDateIndex: .constant(nil),
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
                .task {
                    // Small delay to ensure LazyHStack is ready
                    try? await Task.sleep(nanoseconds: 50_000_000) // 0.05s
                    scrollPosition = centeredIndex
                    refreshUIState(for: dates[centeredIndex])
                    
                }
                .onChange(of: scrollPosition) { _, newValue in
                    guard let newValue = newValue else { return }
                    centeredIndex = newValue
                    refreshUIState(for: dates[centeredIndex])
                }
            }
          
            
            // MARK: Intensity
            Text(intensity.displayName)
                .foregroundStyle(.gray)

            SteppedSlider(value: $intensity)
                .frame(width: 150)
                .onChange(of: intensity) { _, _ in
                    saveIfExists()
                }

            // MARK: Notes Button
            if userText.isEmpty {
                Button(action: {
                    isSheetPresented = true
                }) {
                    Text("Add Notes")
                        .font(.system(size: 17))
                        .foregroundColor(Color(hex: "#7f809e"))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .frame(height: 47)
                        .background(
                            Capsule()
                                .stroke(Color(hex: "#b0b0c9"), lineWidth: 1)
                        )
                }
                .padding(.top, 20)
            }

            // MARK: Display Notes and Emotions
            if !userText.isEmpty || !selectedEmotions.isEmpty {
                ZStack {
                    VStack(alignment: .leading, spacing: 12) {
                        // Emotion Tags
                        if !selectedEmotions.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(Array(selectedEmotions).sorted(), id: \.self) { emotion in
                                        HStack(spacing: 6) {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .semibold))
                                            Text(emotion)
                                                .font(.system(size: 17))
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(Color(hex: "#9c36b2"))
                                        )
                                    }
                                }
                            }
                            .padding(.top, 16)
                            .padding(.horizontal, 24)
                        }

                        // Note Text
                        if !userText.isEmpty {
                            Text(userText)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.primary)
                                .lineLimit(4)
                                .truncationMode(.tail)
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                                .padding(.horizontal, 24)
                                .padding(.top, selectedEmotions.isEmpty ? 25 : 8)
                                .padding(.bottom, 25)
                        } else {
                            Spacer()
                                .padding(.bottom, 25)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                isSheetPresented = true
                            }) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(Color(hex: "#7f809e"))
                                    .frame(width: 54, height: 54)
                                    .background(
                                        RoundedRectangle(cornerRadius: 30)
                                            .fill(Color(uiColor: .systemBackground))
                                            .stroke(Color(hex: "#b0b0c9"), lineWidth: 1)
                                    )
                            }
                            .padding(.trailing, 12)
                            .padding(.bottom, 12)
                        }
                    }
                }
                .frame(minHeight: 100)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color(hex: "#b0b0c9"), lineWidth: 1)
                )
                .padding(.horizontal, 22)
                .padding(.top, 20)
            }

            Spacer()
                .frame(minHeight: 100)
        }
        .sheet(isPresented: $isSheetPresented) {
            NoteSheet(
                userText: $userText,
                isPresented: $isSheetPresented,
                selectedEmotions: $selectedEmotions,
                onSave: { notes in
                    save(notes: notes)
                }
            )
        }
    }
    
    // MARK: - Helpers
    
    private func refreshUIState(for date: Date) {
        if let conflict = conflicts.first(where: {
            Calendar.current.isDate($0.date!, inSameDayAs: date)
        }) {
            intensity = ConflictIntensity(string: conflict.intensity) ?? .moderate
            userText = conflict.notes ?? ""
            if let emotionsString = conflict.emotions, !emotionsString.isEmpty {
                selectedEmotions = Set(emotionsString.split(separator: ",").map(String.init))
            } else {
                selectedEmotions = []
            }
        } else {
            intensity = .moderate
            userText = ""
            selectedEmotions = []
        }
    }
    //
    //    private func toggleConflict(for date: Date) {
    //        try? conflictManager.toggleConflict(
    //            date: date,
    //            person: selectedPerson,
    //            notes: userText,
    //            intensity: intensity
    //        )
    //    }
    
    private func save(notes: String) {
        try? conflictManager.saveConflict(
            date: dates[centeredIndex],
            person: selectedPerson,
            notes: notes,
            intensity: intensity,
            emotions: Array(selectedEmotions)
        )
        userText = notes
    }
    
    private func saveIfExists() {
        if (try? conflictManager.fetchConflict(for: dates[centeredIndex])) != nil {
            save(notes: userText)
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
        formatter.locale = Locale.current // Use the device's current locale
        formatter.dateStyle = .medium // Use medium style for date (includes day and month, adapts to locale)
        formatter.timeStyle = .none // Exclude time
        // Optionally, customize to ensure only day and month are shown
        formatter.setLocalizedDateFormatFromTemplate("dMMMM") // Template for day and month
        return formatter.string(from: date)
    }
    private func year(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
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
                //            let centerDate = pastFiveDates[centeredIndex]
                try conflictManager.toggleConflict(
                    date: date,
                    person: selectedPerson,
                    notes: userText,
                    intensity: intensity,
                    emotions: Array(selectedEmotions)
                )
                // Refresh UI state after toggle (FetchRequest will update conflicts)
                refreshUIState(for: date)
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


struct TruncatedSizeKey: PreferenceKey {
static var defaultValue: CGSize = .zero
static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
    value = nextValue()
}
}

struct FullSizeKey: PreferenceKey {
static var defaultValue: CGSize = .zero
static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
    value = nextValue()
}
}

struct LimitedText: View {
let text: String
let lineLimit: Int
let font: Font
let onViewMore: () -> Void

@State private var truncatedSize: CGSize = .zero
@State private var fullSize: CGSize = .zero

var isTruncated: Bool {
    truncatedSize.height < fullSize.height
}

var body: some View {
    VStack(alignment: .leading, spacing: 4) {
        ZStack(alignment: .topLeading) {
            Text(text)
                .font(font)
                .lineLimit(lineLimit)
                .background(GeometryReader { geo in
                    Color.clear.preference(key: TruncatedSizeKey.self, value: geo.size)
                })
                .onPreferenceChange(TruncatedSizeKey.self) { truncatedSize = $0 }
            
            Text(text)
                .font(font)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .hidden()
                .background(GeometryReader { geo in
                    Color.clear.preference(key: FullSizeKey.self, value: geo.size)
                })
                .onPreferenceChange(FullSizeKey.self) { fullSize = $0 }
        }
        
        if isTruncated {
            Button("View more") {
                onViewMore()
            }
            .font(.subheadline)
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    .frame(maxWidth: .infinity, alignment: .topLeading)
}
}
// MARK: - FullNoteView
struct FullNoteView: View {
let note: String
@Environment(\.dismiss) private var dismiss

var body: some View {
    NavigationStack {
        ScrollView {
            Text(note)
                .font(.title2)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Note")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}
}
