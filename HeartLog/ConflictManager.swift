import CoreData
import Foundation

class ConflictManager: ObservableObject {
    let viewContext: NSManagedObjectContext
    private let calendar: Calendar // MODIFIED: Use fixed UTC calendar
    @Published var lastUpdate: Date = Date()
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "UTC")! // NEW: Force UTC
        self.calendar = calendar
    }
    
    // Fetch conflicts for a given date range (inclusive start, exclusive end)
    func fetchConflicts(from startDate: Date, to endDate: Date) -> [Conflict] {
        let fetchStart = calendar.startOfDay(for: startDate)
        let fetchEnd = calendar.startOfDay(for: endDate)
        let request: NSFetchRequest<Conflict> = Conflict.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", fetchStart as NSDate, fetchEnd as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Conflict.date, ascending: true)]
        
        do {
            let conflicts = try viewContext.fetch(request)
            print("Fetched \(conflicts.count) conflicts from \(fetchStart) to \(fetchEnd)")
            return conflicts
        } catch {
            print("Error fetching conflicts: \(error)")
            return []
        }
    }
    
    // Fetch a single conflict for a specific date
    func fetchConflict(for date: Date) -> Conflict? {
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<Conflict> = Conflict.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.fetchLimit = 1
        
        do {
            let conflict = try viewContext.fetch(request).first
            print("Fetched conflict for \(startOfDay): \(conflict != nil ? "Found" : "Not found")")
            return conflict
        } catch {
            print("Error fetching conflict for date: \(error)")
            return nil
        }
    }
    
    // Save or update a conflict for a given date
    func saveConflict(date: Date, person: String, notes: String?, intensity: String?) {
        let startOfDay = calendar.startOfDay(for: date)
        
        if let existing = fetchConflict(for: startOfDay) {
            viewContext.delete(existing)
            print("Deleted existing conflict for \(startOfDay)")
        }
        
        if notes != nil || intensity != nil || person != "Him" {
            let newConflict = Conflict(context: viewContext)
            newConflict.id = UUID()
            newConflict.date = startOfDay
            newConflict.person = person
            newConflict.notes = notes
            newConflict.intensity = intensity
            print("Created new conflict for \(startOfDay): person=\(person), notes=\(notes ?? "nil"), intensity=\(intensity ?? "nil")")
        }
        
        do {
            try viewContext.save()
            viewContext.refreshAllObjects()
            lastUpdate = Date()
            objectWillChange.send()
            print("Saved context for \(startOfDay)")
        } catch {
            print("Error saving conflict: \(error)")
        }
    }
    
    // Toggle conflict (add default or delete)
    func toggleConflict(for date: Date, person: String, intensity: String = ConflictIntensity.moderate.stringValue) {
        let startOfDay = calendar.startOfDay(for: date)
        
        if let existing = fetchConflict(for: startOfDay) {
            viewContext.delete(existing)
            print("Toggled: Deleted conflict for \(startOfDay)")
        } else {
            let newConflict = Conflict(context: viewContext)
            newConflict.id = UUID()
            newConflict.date = startOfDay
            newConflict.person = person
            newConflict.notes = nil
            newConflict.intensity = intensity
            print("Toggled: Created conflict for \(startOfDay)")
        }
        
        do {
            try viewContext.save()
            viewContext.refreshAllObjects()
            lastUpdate = Date()
            objectWillChange.send()
            print("Saved context for toggle on \(startOfDay)")
        } catch {
            print("Error toggling conflict: \(error)")
        }
    }
    
    // Update intensity for a date
    func updateIntensity(for date: Date, intensity: String) {
        let startOfDay = calendar.startOfDay(for: date)
        if let conflict = fetchConflict(for: startOfDay) {
            conflict.intensity = intensity
            do {
                try viewContext.save()
                viewContext.refreshAllObjects()
                lastUpdate = Date()
                objectWillChange.send()
                print("Updated intensity for \(startOfDay) to \(intensity)")
            } catch {
                print("Error updating intensity: \(error)")
            }
        }
    }
}
