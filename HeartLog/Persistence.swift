//
//  Persistence.swift
//  HeartLog
//
//  Created by Jeong on 2025/9/17.
//

import CoreData
import CloudKit

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "ConflictModel")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Configure CloudKit options for iCloud sync
            let description = container.persistentStoreDescriptions.first

            // Enable lightweight migration
            description?.shouldMigrateStoreAutomatically = true
            description?.shouldInferMappingModelAutomatically = true

            // Check if user is premium to enable iCloud sync
            let isPremium = UserDefaults.standard.bool(forKey: "isPremiumUser")

            if isPremium {
                // Configure CloudKit container for premium users only
                description?.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                    containerIdentifier: "iCloud.com.jeongpei.Knotnot"
                )

                // Enable remote change notifications
                description?.setOption(true as NSNumber,
                                      forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            } else {
                // Disable CloudKit sync for free users
                description?.cloudKitContainerOptions = nil
            }
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        // Configure merge policies for handling conflicts
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Observe CloudKit sync events for debugging
        NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: container,
            queue: .main
        ) { notification in
            if let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                as? NSPersistentCloudKitContainer.Event {
                print("☁️ CloudKit sync event: \(event.type)")
                if let error = event.error {
                    print("⚠️ CloudKit sync error: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - iCloud Status Check

    /// Check if iCloud sync is available (requires premium)
    func isSyncAvailable() -> Bool {
        return UserDefaults.standard.bool(forKey: "isPremiumUser")
    }

    /// Check if iCloud is available for syncing
    func checkiCloudStatus(completion: @escaping (Bool, String?) -> Void) {
        // First check if user is premium
        guard isSyncAvailable() else {
            completion(false, "iCloud sync is a premium feature. Upgrade to enable sync across devices.")
            return
        }

        CKContainer.default().accountStatus { status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    completion(true, nil)
                case .noAccount:
                    completion(false, "Please sign in to iCloud to sync your data across devices.")
                case .restricted:
                    completion(false, "iCloud access is restricted on this device.")
                case .couldNotDetermine:
                    completion(false, "Could not determine iCloud status.")
                case .temporarilyUnavailable:
                    completion(false, "iCloud is temporarily unavailable.")
                @unknown default:
                    completion(false, "Unknown iCloud status.")
                }
            }
        }
    }
}
