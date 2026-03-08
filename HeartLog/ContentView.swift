import SwiftUI



struct ContentView: View {
    var body: some View {
        CalendarView()
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(ConflictManager(context: PersistenceController.shared.container.viewContext))
        .preferredColorScheme(.dark)
}
