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
    @State private var showOnboarding: Bool = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    
    init() {
        let context = persistenceController.container.viewContext
        conflictManager = ConflictManager(context: context)
    }
    
    var body: some Scene {
            WindowGroup {
                if showOnboarding {
                    OnboardingView {
                        showOnboarding = false
                        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                    }
                } else {
                    ContentView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .environmentObject(conflictManager)
                }
            }
        }
}
