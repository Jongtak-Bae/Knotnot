import SwiftUI



struct ContentView: View {
    var body: some View {
        TabView {
            MainView()
                .tabItem {
                    Label("Log", systemImage: "heart")
                        
                }
            
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                        
                }
        }
        .tint(Color(hex: "#A640BC"))
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(ConflictManager(context: PersistenceController.shared.container.viewContext))
        .preferredColorScheme(.dark)
}
