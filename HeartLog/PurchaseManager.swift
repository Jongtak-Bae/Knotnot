//
//  PurchaseManager.swift
//  HeartLog
//
//  Manages In-App Purchases using StoreKit 2
//

import Foundation
import StoreKit

enum PurchaseState {
    case idle
    case loading
    case purchasing
    case purchased
    case failed(Error)
    case restored
}

@MainActor
class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    // Product ID for lifetime premium access
    private let productID = "com.jeongpei.knotnot.premium.lifetime"

    // Published properties for UI binding
    @Published private(set) var isPremium: Bool = false
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchaseState: PurchaseState = .idle

    // UserDefaults key for caching premium status
    private let premiumStatusKey = "isPremiumUser"

    // Transaction listener task
    private var transactionListener: Task<Void, Error>?

    private init() {
        // Load cached premium status from UserDefaults
        self.isPremium = UserDefaults.standard.bool(forKey: premiumStatusKey)

        // Start listening for transactions
        transactionListener = listenForTransactions()

        // Verify premium status with StoreKit
        Task {
            await updatePurchaseStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Product Loading

    func loadProducts() async {
        purchaseState = .loading

        do {
            let products = try await Product.products(for: [productID])
            self.products = products
            purchaseState = .idle
        } catch {
            print("Failed to load products: \(error)")
            purchaseState = .failed(error)
            self.products = []
        }
    }

    // MARK: - Purchase Flow

    func purchase(_ product: Product) async throws {
        purchaseState = .purchasing

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Verify the transaction
                let transaction = try checkVerified(verification)

                // Update premium status
                await updatePurchaseStatus()

                // Finish the transaction
                await transaction.finish()

                purchaseState = .purchased

            case .userCancelled:
                purchaseState = .idle

            case .pending:
                purchaseState = .idle

            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed(error)
            throw error
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async throws {
        purchaseState = .loading

        do {
            try await AppStore.sync()
            await updatePurchaseStatus()

            if isPremium {
                purchaseState = .restored
            } else {
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed(error)
            throw error
        }
    }

    // MARK: - Transaction Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Status Update

    private func updatePurchaseStatus() async {
        var hasPremium = false

        // Check for current entitlements
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // Check if this is our premium product
                if transaction.productID == productID {
                    hasPremium = true
                    break
                }
            } catch {
                print("Transaction verification failed: \(error)")
            }
        }

        // Update published property and cache
        isPremium = hasPremium
        UserDefaults.standard.set(hasPremium, forKey: premiumStatusKey)
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // Listen for transaction updates
            for await result in Transaction.updates {
                do {
                    // Verify the transaction
                    let transaction: Transaction
                    switch result {
                    case .unverified:
                        throw StoreError.failedVerification
                    case .verified(let safe):
                        transaction = safe
                    }

                    // Update premium status on main actor
                    await self.updatePurchaseStatus()

                    // Finish the transaction
                    await transaction.finish()
                } catch {
                    print("Transaction update failed: \(error)")
                }
            }
        }
    }
}

// MARK: - Store Errors

enum StoreError: LocalizedError {
    case failedVerification

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        }
    }
}
