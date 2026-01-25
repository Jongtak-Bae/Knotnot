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
    @StateObject private var purchaseManager = PurchaseManager.shared
    @StateObject private var noteAccessManager = NoteAccessManager.shared
    @State private var showOnboarding: Bool = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")

    init() {
        let context = persistenceController.container.viewContext
        conflictManager = ConflictManager(context: context)

        // Track first install version for grandfathering
        if UserDefaults.standard.string(forKey: "firstInstallVersion") == nil {
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                UserDefaults.standard.set(version, forKey: "firstInstallVersion")
            }
        }
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
                        .environmentObject(purchaseManager)
                        .environmentObject(noteAccessManager)
                        .task {
                            await purchaseManager.loadProducts()
                        }
                        .onChange(of: purchaseManager.isPremium) { _, isPremium in
                            noteAccessManager.updateAccess(isPremium: isPremium)
                        }
                        .onAppear {
                            noteAccessManager.updateAccess(isPremium: purchaseManager.isPremium)
                        }
                }
            }
        }
}
