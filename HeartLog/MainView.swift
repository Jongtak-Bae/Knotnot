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
    
    @State private var showFullNote: Bool = false
    @State private var fullNoteText: String = ""
    
    // Generate five past days including today
    private var pastFiveDates: [Date] {
        let today = Calendar.current.startOfDay(for: Date()) // Normalize to start of day
        let calendar = Calendar.current
        return (0...4).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }.reversed()
    }
    
    var body: some View {
        ConflictEditorView(
                  dates: pastFiveDates,
                  initialDate: Date()
              )
        // Conditionally apply MeshGradient background for iOS 18.0+
#if canImport(SwiftUI)
        .background {
            if #available(iOS 18.0, *) {
                MeshGradient(
                    width: 3,
                    height: 3,
                    points: [
                        .init(x: 0, y: 0), .init(x: 0.8, y: 0), .init(x: 1, y: 0),
                        .init(x: 0, y: 0.2), .init(x: 0.1, y: 0.5), .init(x: 1, y: 0.5),
                        .init(x: 0, y: 1), .init(x: 0, y: 1), .init(x: 1, y: 1)
                    ],
                    colors: [
                        Color(hex: "#EAAB04").opacity(0.2), Color(hex: "#A640BC").opacity(0.2), Color(hex: "#A640BC").opacity(0.2),
                        .clear, .clear, .clear,
                        .clear, .clear, .clear
                    ]
                )
            }
        }
#endif
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
    
}
