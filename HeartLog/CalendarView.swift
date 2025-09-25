import SwiftUI
import CoreData

struct CalendarView: View {
    @EnvironmentObject private var conflictManager: ConflictManager
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Conflict.date, ascending: true)],
        animation: .default)
    private var conflicts: FetchedResults<Conflict>
    
    @State private var currentMonth: Date = Date()
    @State private var selectedDate: Date? = nil
    // Add state for showing conflict details
    @State private var selectedConflict: Conflict? = nil
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 1 // Start week on Sunday
        return cal
    }
    
    private var monthDays: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else {
            return []
        }
        
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 0
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let offsetDays = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        var days: [Date] = []
        // Add empty slots for days before the first day of the month
        for _ in 0..<offsetDays {
            days.append(Date.distantPast)
        }
        // Add actual days of the month
        for day in 0..<daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day, to: firstDay) {
                days.append(date)
            }
        }
        // Fill remaining slots to complete the grid
        let totalSlots = ((days.count + 6) / 7) * 7
        for _ in days.count..<totalSlots {
            days.append(Date.distantFuture)
        }
        return days
    }
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private var detailDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }
    
    // Add this computed property to calculate total conflicts
    private var totalConflicts: Int {
        conflicts.count
    }
    
    private func hasConflict(on date: Date) -> Bool {
        conflicts.contains { Calendar.current.isDate($0.date!, inSameDayAs: date) }
    }
    
    private func conflictIntensity(on date: Date) -> ConflictIntensity {
        conflicts.first { Calendar.current.isDate($0.date!, inSameDayAs: date) }
            .flatMap { ConflictIntensity(string: $0.intensity) } ?? .moderate
    }
    
    private func conflictEmoji(on date: Date) -> String {
        switch conflictIntensity(on: date) {
        case .minor: return "☹️"
        case .moderate: return "😡"
        case .severe: return "👿"
        }
    }
    
    private func hasNote(on date: Date) -> Bool {
        if let conflict = conflicts.first(where: { Calendar.current.isDate($0.date!, inSameDayAs: date) }) {
            return !(conflict.notes ?? "").isEmpty
        }
        return false
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            // Total conflicts display
            VStack(alignment: .leading){
                Text("Total Conflicts")
                    .foregroundStyle(.gray)
                Text("\(totalConflicts)")
                    .font(.title)
                    .fontWeight(.semibold)
                    .padding(.top, 6)
            }
            .padding()
            
            Divider()
                  
            // Month navigation
            HStack {
                Button(action: {
                    currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text(monthName)
                    .font(.title)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth)!
                }) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            // Weekday headers
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 7), spacing: 20) {
                ForEach(monthDays, id: \.self) { date in
                    if date == Date.distantPast || date == Date.distantFuture {
                        Text("") // Empty cell for padding
                            .frame(height: 40)
                    } else {
                        ZStack(alignment: .bottom){
                            ZStack {
                                let circleColor: Color = hasConflict(on: date) ? conflictIntensity(on: date).color : .clear
                                Circle()
                                    .fill(circleColor)
                                    .stroke(
                                        selectedConflict != nil && Calendar.current.isDate(date, inSameDayAs: selectedConflict!.date!) ? Color.gray : Color.gray.opacity(0.5),
                                                                                    lineWidth: selectedConflict != nil && Calendar.current.isDate(date, inSameDayAs: selectedConflict!.date!) ? 3 : 0
                                                                                )
                                    .frame(width: 40, height: 40)
                                
                                Text(hasConflict(on: date) ? conflictEmoji(on: date) : "\(calendar.component(.day, from: date))")
                                    .font(.body)
                                    .foregroundColor(hasConflict(on: date) ? .white : .primary)
                            }
                            if hasNote(on: date) {
                                                       Circle()
                                                           .fill(conflictIntensity(on: date).color)
                                                           .frame(width: 4, height: 4)
                                                           .offset(y: 8)
                                                   }
                        }
                       
                        .onTapGesture {
                                                selectedConflict = hasConflict(on: date) ?
                                                    conflicts.first { Calendar.current.isDate($0.date!, inSameDayAs: date) } : nil
                                            }
                    }
                }
            }
            .padding(.horizontal)
            // Conflict details
                  if let conflict = selectedConflict {
                      ConflictDetailView(
                          conflict: conflict,
                          onDelete: {
                              Task {
                                  do {
                                      try await conflictManager.deleteConflict(for: conflict.date!)
                                      selectedConflict = nil
                                  } catch {
                                      print("Error deleting conflict: \(error)")
                                  }
                              }
                          }
                      )
                      .padding()
                      .background(
                          RoundedRectangle(cornerRadius: 10)
                            .stroke(.gray.opacity(0.2), lineWidth: 1)
                             
                      )
                      .padding(.horizontal)
                  }

            
            Spacer()
        }
        .onChange(of: currentMonth) { _, _ in
            selectedConflict = nil // Hide details when navigating to a new month
           }
    
    }
}

// Conflict Detail View
struct ConflictDetailView: View {
    let conflict: Conflict
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
             
                VStack(alignment: .leading, spacing: 10){
                    HStack {
                                           Text("Date:")
                                               .font(.headline)
                                               .foregroundColor(.gray)
                        Text(dateFormatter.string(from: conflict.date ?? Date()))
                                               .font(.body)
                                       }
                                       HStack {
                                           Text("Intensity:")
                                               .font(.headline)
                                               .foregroundColor(.gray)
                                           Text(conflict.intensity ?? "Unknown")
                                               .font(.body)
                                       }
                                       VStack(alignment: .leading) {
                                           Text("Note:")
                                               .font(.headline)
                                               .foregroundColor(.gray)
                                           Text(conflict.notes ?? "")
                                               .font(.body)
                                               .multilineTextAlignment(.leading)
                                               .frame(maxWidth: .infinity, alignment: .leading)
                                       }
                }
        
                Spacer()
                Button(action: {
                    onDelete()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.gray)
                        .font(.body)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 50.0)
                            .stroke(.gray.opacity(0.5)))
                }
               
            }
  
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

#Preview {
    CalendarView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(ConflictManager(context: PersistenceController.shared.container.viewContext))
        .preferredColorScheme(.dark)
}
