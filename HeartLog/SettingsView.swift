
import SwiftUI
import StoreKit

struct SettingsView: View {
    // MARK: - Properties
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Environment(\.openURL) var openURL
    @Environment(\.dismiss) var dismiss
    @State private var versionNumber: String = ""
    @State private var showPaywall: Bool = false
    @State private var showRestoreAlert: Bool = false
    @State private var restoreMessage: String = ""

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Premium Section
                premiumSection

                // MARK: - General Section
                generalSection

                // MARK: - Legal Section
                legalSection

                // MARK: - Connect Section
                connectSection

                // MARK: - App Version
                versionSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
        .background(Color("BackgroundPrimary"))
        .navigationTitle(NSLocalizedString("Settings", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            getAppVersion()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(feature: .general)
                .environmentObject(purchaseManager)
        }
        .alert(NSLocalizedString("Restore Purchases", comment: ""), isPresented: $showRestoreAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(restoreMessage)
        }
    }

    // MARK: - Premium Section
    private var premiumSection: some View {
        VStack(spacing: 0) {
            if purchaseManager.isPremium {
                SettingsRow(
                    icon: "checkmark.seal.fill",
                    iconColor: Color("Orange"),
                    title: NSLocalizedString("Premium", comment: ""),
                    trailing: NSLocalizedString("Active", comment: "")
                )
            } else {
                SettingsRow(
                    icon: "crown.fill",
                    iconColor: Color("Orange"),
                    title: NSLocalizedString("Upgrade to Premium", comment: ""),
                    action: { showPaywall = true }
                )

                Divider()
                    .padding(.leading, 52)

                SettingsRow(
                    icon: "arrow.clockwise",
                    iconColor: Color("LabelPrimary"),
                    title: NSLocalizedString("Restore Purchases", comment: ""),
                    action: {
                        Task { await restorePurchases() }
                    }
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color("BackgroundSecondary"))
        )
    }

    // MARK: - General Section
    private var generalSection: some View {
        VStack(spacing: 0) {
            Link(destination: writeReview()) {
                SettingsRowContent(
                    icon: "star.fill",
                    iconColor: Color("Yellow"),
                    title: NSLocalizedString("Rate the App", comment: ""),
                    showChevron: false
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color("BackgroundSecondary"))
        )
    }

    // MARK: - Legal Section
    private var legalSection: some View {
        VStack(spacing: 0) {
            Link(destination: URL(string: "https://sites.google.com/view/knot-not-privacy-policy/home")!) {
                SettingsRowContent(
                    icon: "hand.raised.fill",
                    iconColor: Color("LabelPrimary"),
                    title: NSLocalizedString("Privacy Policy", comment: ""),
                    showChevron: false
                )
            }

            Divider()
                .padding(.leading, 52)

            Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
                SettingsRowContent(
                    icon: "doc.text.fill",
                    iconColor: Color("LabelPrimary"),
                    title: NSLocalizedString("Terms & Conditions", comment: ""),
                    showChevron: false
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color("BackgroundSecondary"))
        )
    }

    // MARK: - Connect Section
    private var connectSection: some View {
        VStack(spacing: 0) {
            SettingsRow(
                icon: "envelope.fill",
                iconColor: Color("LabelPrimary"),
                title: NSLocalizedString("Contact", comment: ""),
                trailing: "peizhengze@gmail.com"
            )

            Divider()
                .padding(.leading, 52)

            Link(destination: URL(string: "https://x.com/JeongtaeBae")!) {
                SettingsRowContent(
                    icon: "xmark",
                    iconColor: Color("LabelPrimary"),
                    title: NSLocalizedString("Follow on X", comment: ""),
                    trailing: "@JeongTaeBae",
                    showChevron: false
                )
            }

            Divider()
                .padding(.leading, 52)

            Link(destination: URL(string: "https://www.instagram.com/jeongpei/")!) {
                SettingsRowContent(
                    icon: "camera.fill",
                    iconColor: Color("LabelPrimary"),
                    title: NSLocalizedString("Instagram", comment: ""),
                    trailing: "@JeongPei",
                    showChevron: false
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color("BackgroundSecondary"))
        )
    }

    // MARK: - Version Section
    private var versionSection: some View {
        VStack(spacing: 0) {
            SettingsRow(
                icon: "info.circle.fill",
                iconColor: Color("LabelPrimary"),
                title: NSLocalizedString("App Version", comment: ""),
                trailing: versionNumber
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color("BackgroundSecondary"))
        )
    }

    // MARK: - Functions
    private func getAppVersion() {
        if let text = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            versionNumber = text
        }
    }

    private func writeReview() -> URL {
        let appID = "6753355545"
        let url = "https://apps.apple.com/app/id\(appID)?action=write-review"
        guard let writeReviewURL = URL(string: url) else {
            fatalError("Expected a valid URL")
        }
        return writeReviewURL
    }

    private func restorePurchases() async {
        do {
            try await purchaseManager.restorePurchases()

            if purchaseManager.isPremium {
                restoreMessage = String(localized: "Purchases successfully restored!")
            } else {
                restoreMessage = String(localized: "No previous purchases found.")
            }
            showRestoreAlert = true
        } catch {
            restoreMessage = String(localized: "Restore failed. Please try again.")
            showRestoreAlert = true
        }
    }
}

// MARK: - Settings Row (tappable)
private struct SettingsRow: View {
    let icon: String
    var iconColor: Color = Color("LabelPrimary")
    let title: String
    var trailing: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        if let action = action {
            Button(action: action) {
                SettingsRowContent(
                    icon: icon,
                    iconColor: iconColor,
                    title: title,
                    trailing: trailing
                )
            }
            .buttonStyle(.plain)
        } else {
            SettingsRowContent(
                icon: icon,
                iconColor: iconColor,
                title: title,
                trailing: trailing
            )
        }
    }
}

// MARK: - Settings Row Content
private struct SettingsRowContent: View {
    let icon: String
    var iconColor: Color = Color("LabelPrimary")
    let title: String
    var trailing: String? = nil
    var showChevron: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundColor(iconColor)
                .frame(width: 28, alignment: .center)

            Text(title)
                .font(.system(size: 17, weight: .regular))
                .tracking(-0.43)
                .foregroundColor(Color("LabelPrimary"))

            Spacer()

            if let trailing = trailing {
                Text(trailing)
                    .font(.system(size: 15, weight: .regular))
                    .tracking(-0.23)
                    .foregroundColor(Color("LabelPrimary").opacity(0.5))
                    .lineLimit(1)
            }

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color("LabelPrimary").opacity(0.3))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(PurchaseManager.shared)
    }
    .preferredColorScheme(.dark)
}
