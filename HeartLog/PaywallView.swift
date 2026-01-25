//
//  PaywallView.swift
//  HeartLog
//
//  Premium upgrade paywall with feature showcase
//

import SwiftUI
import StoreKit
import UIKit

enum PaywallFeature {
    case statistics
    case emotionTags
    case iCloudSync
    case unlimitedNotes
    case general
}

struct PaywallView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    let feature: PaywallFeature

    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isProcessing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "#A640BC"), Color(hex: "#D896FF")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(.top, 20)

                        Text("Unlock Premium")
                            .font(.title.bold())

                        Text("Get full access to all features")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 8)

                    // Features List
                    VStack(spacing: 16) {
                        FeatureRow(
                            icon: "chart.bar.fill",
                            title: String(localized: "Statistics & Insights"),
                            description: String(localized: "View detailed charts and analytics of your conflict patterns"),
                            isHighlighted: feature == .statistics
                        )

                        FeatureRow(
                            icon: "face.smiling.fill",
                            title: String(localized: "Emotion Tags"),
                            description: String(localized: "Track your emotional states with tags"),
                            isHighlighted: feature == .emotionTags
                        )

                        FeatureRow(
                            icon: "icloud.fill",
                            title: String(localized: "iCloud Sync"),
                            description: String(localized: "Seamlessly sync your data across all your devices"),
                            isHighlighted: feature == .iCloudSync
                        )

                        FeatureRow(
                            icon: "text.alignleft",
                            title: String(localized: "Unlimited Notes"),
                            description: String(localized: "Write notes of any length without character limits"),
                            isHighlighted: feature == .unlimitedNotes
                        )
                        FeatureRow(
                            icon: "heart.fill",
                            title: String(localized: "Early Supporter & Future Updates"),
                            description: String(localized: "Become an early supporter and get all future premium features"),
                            isHighlighted: false
                        )
                    }
                    .padding(.horizontal)

                    // Pricing Card
                    if let product = purchaseManager.products.first {
                        VStack(spacing: 16) {
                            VStack(spacing: 4) {
                                Text("One-Time Purchase")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Text(product.displayPrice)
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(Color(hex: "#A640BC"))

                                Text("Lifetime Access")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)

                            // Purchase Button
                            Button(action: {
                                Task {
                                    await purchaseProduct(product)
                                }
                            }) {
                                HStack {
                                    if isProcessing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Purchase Premium")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "#A640BC"))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(isProcessing)

                            // Restore Button
                            Button(action: {
                                Task {
                                    await restorePurchases()
                                }
                            }) {
                                Text("Restore Purchases")
                                    .font(.subheadline)
                                    .foregroundColor(Color(hex: "#A640BC"))
                            }
                            .disabled(isProcessing)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    } else {
                        ProgressView()
                            .padding()
                    }

                    // Privacy Note
                    Text("One-time payment. No subscriptions. Unlock all current and future premium features.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 8)

                    // Privacy Policy & Terms Links
                    HStack(spacing: 16) {
                        Link(destination: URL(string: "https://sites.google.com/view/knot-not-privacy-policy/home")!) {
                            Text("Privacy Policy")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        Text("•")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
                            Text("Terms & Conditions")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onChange(of: purchaseManager.isPremium) { _, isPremium in
                if isPremium {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Actions

    private func purchaseProduct(_ product: Product) async {
        isProcessing = true
        defer { isProcessing = false }

        do {
            try await purchaseManager.purchase(product)
        } catch {
            errorMessage = String(localized: "Purchase failed. Please try again.")
            showError = true
        }
    }

    private func restorePurchases() async {
        isProcessing = true
        defer { isProcessing = false }

        do {
            try await purchaseManager.restorePurchases()

            if purchaseManager.isPremium {
                errorMessage = String(localized: "Purchases successfully restored!")
                showError = true
            } else {
                errorMessage = String(localized: "No previous purchases found.")
                showError = true
            }
        } catch {
            errorMessage = String(localized: "Restore failed. Please try again.")
            showError = true
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    var isHighlighted: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isHighlighted ? Color(hex: "#A640BC") : .secondary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(isHighlighted ? Color(hex: "#A640BC") : .primary)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHighlighted ? Color(hex: "#A640BC").opacity(0.1) : Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHighlighted ? Color(hex: "#A640BC") : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    PaywallView(feature: .statistics)
        .environmentObject(PurchaseManager.shared)
}
