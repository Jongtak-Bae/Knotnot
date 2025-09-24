//
//  HeartLogApp.swift
//  HeartLog
//
//  Created by Jeong on 2025/9/17.
//

import SwiftUI

// MARK: App Entry Point
@main
struct HeartLogApp: App {
    let persistenceController = PersistenceController.shared
    let conflictManager: ConflictManager
    
    init() {
        let context = persistenceController.container.viewContext
        conflictManager = ConflictManager(context: context)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(conflictManager)
        }
    }
}
