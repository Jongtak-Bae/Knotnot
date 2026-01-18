import CoreData

class ConflictManager: ObservableObject {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Create/Update
    func saveConflict(date: Date, person: String, notes: String, intensity: ConflictIntensity, emotions: [String]? = nil) throws {
        // Check if a conflict exists for the given date
        if let existingConflict = try fetchConflict(for: date) {
            // Update existing conflict
            existingConflict.person = person
            existingConflict.notes = notes
            existingConflict.intensity = intensity.stringValue
            if let emotions = emotions {
                existingConflict.emotions = emotions.joined(separator: ",")
            }
        } else {
            // Create new conflict
            let newConflict = Conflict(context: context)
            newConflict.id = UUID()
            newConflict.date = date
            newConflict.person = person
            newConflict.notes = notes
            newConflict.intensity = intensity.stringValue
            if let emotions = emotions {
                newConflict.emotions = emotions.joined(separator: ",")
            }
        }

        try context.save()
    }
    
    // MARK: - Read
    func fetchConflict(for date: Date) throws -> Conflict? {
        let request: NSFetchRequest<Conflict> = Conflict.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                      Calendar.current.startOfDay(for: date) as NSDate,
                                      Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: date))! as NSDate)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
    
    func fetchConflicts(for dateRange: ClosedRange<Date>) throws -> [Conflict] {
        let request: NSFetchRequest<Conflict> = Conflict.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@",
                                      dateRange.lowerBound as NSDate,
                                      dateRange.upperBound as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Conflict.date, ascending: true)]
        return try context.fetch(request)
    }
    
    // MARK: - Delete
    func deleteConflict(for date: Date) throws {
        if let conflict = try fetchConflict(for: date) {
            context.delete(conflict)
            try context.save()
        }
    }
    
    // MARK: - Toggle Conflict
    func toggleConflict(date: Date, person: String, notes: String, intensity: ConflictIntensity, emotions: [String]? = nil) throws {
        if let existingConflict = try fetchConflict(for: date) {
            // Delete if conflict exists
            context.delete(existingConflict)
        } else {
            // Create new conflict
            let newConflict = Conflict(context: context)
            newConflict.id = UUID()
            newConflict.date = date
            newConflict.person = person
            newConflict.notes = notes
            newConflict.intensity = intensity.stringValue
            if let emotions = emotions {
                newConflict.emotions = emotions.joined(separator: ",")
            }
        }
        try context.save()
    }
}
