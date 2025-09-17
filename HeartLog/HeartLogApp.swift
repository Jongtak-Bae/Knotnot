//
//  HeartLogApp.swift
//  HeartLog
//
//  Created by Jeong on 2025/9/17.
//

import SwiftUI

@main
struct HeartLogApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
