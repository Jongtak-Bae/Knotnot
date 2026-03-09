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
    @State private var currentPage = 0
    @State private var autoAdvanceTimer: Timer?

    private let pageCount = 5
    private let autoAdvanceInterval: TimeInterval = 3.0

    var body: some View {
        ZStack(alignment: .bottom) {
            Color("BackgroundPrimary")
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // MARK: - Page Indicators
                    pageIndicators
                        .padding(.top, 20)
                    
                    // MARK: - Carousel
                    carouselSection
                        .padding(.top, 16)

                  

                    // MARK: - Title
                    Text(NSLocalizedString("Unlock All Features", comment: ""))
                        .font(.system(size: 34, weight: .light, design: .rounded))
                        .foregroundColor(Color("LabelPrimary"))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)

                    // MARK: - Feature Card
                    featureCard
                        .padding(.horizontal, 20)
                        .padding(.top, 24)

                    // MARK: - Footer Links
                    footerLinks
                        .padding(.top, 24)
                        .padding(.bottom, 120) // Space for sticky CTA
                }
            }

            // MARK: - Sticky CTA
            stickyCTA
        }
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .topTrailing) {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color("LabelPrimary"))
                    .frame(width: 30, height: 30)
                    .background(Color("BackgroundSecondary"))
                    .clipShape(Circle())
            }
            .padding(.trailing, 20)
            .padding(.top, 16)
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
        .onAppear { startAutoAdvance() }
        .onDisappear { stopAutoAdvance() }
    }

    // MARK: - Carousel

    private var carouselSection: some View {
        ZStack {
            PaywallCarouselStatistics()
                .opacity(currentPage == 0 ? 1 : 0)
            PaywallCarouselEmotionTags()
                .opacity(currentPage == 1 ? 1 : 0)
            PaywallCarouselICloudSync()
                .opacity(currentPage == 2 ? 1 : 0)
            PaywallCarouselUnlimitedNotes()
                .opacity(currentPage == 3 ? 1 : 0)
            PaywallCarouselEarlySupporter()
                .opacity(currentPage == 4 ? 1 : 0)
        }
        .animation(.easeInOut(duration: 0.5), value: currentPage)
        .frame(height: 248)
    }

    // MARK: - Page Indicators

    private var pageIndicators: some View {
        HStack(spacing: 4) {
            ForEach(0..<pageCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 10)
                    .fill(index == currentPage
                        ? Color("LabelPrimary").opacity(0.7)
                        : Color("BackgroundSecondary"))
                    .frame(width: 42, height: 3)
            }
        }
    }

    // MARK: - Feature Card

    private var featureCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(NSLocalizedString("Included Features", comment: ""))
                .font(.system(size: 17, weight: .regular))
                .tracking(-0.43)
                .foregroundColor(Color("LabelPrimary"))

            PaywallFeatureRow(
                icon: "chart.bar.fill",
                title: NSLocalizedString("Statistics & Insights", comment: ""),
                description: NSLocalizedString("View detailed charts and analytics of your conflict patterns", comment: "")
            )
            PaywallFeatureRow(
                icon: "face.smiling.fill",
                title: NSLocalizedString("Emotion Tags", comment: ""),
                description: NSLocalizedString("Track your emotional states with tags", comment: "")
            )
            PaywallFeatureRow(
                icon: "arrow.trianglehead.2.clockwise.rotate.90.icloud.fill",
                title: NSLocalizedString("iCloud Sync", comment: ""),
                description: NSLocalizedString("Seamlessly sync your data across all your devices", comment: "")
            )
            PaywallFeatureRow(
                icon: "text.alignleft",
                title: NSLocalizedString("Unlimited Notes", comment: ""),
                description: NSLocalizedString("Write notes of any length without character limits", comment: "")
            )
            PaywallFeatureRow(
                icon: "heart.fill",
                title: NSLocalizedString("Early Supporter & Future Updates", comment: ""),
                description: NSLocalizedString("Become an early supporter and get all future premium features", comment: "")
            )
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color("BackgroundSecondary"))
        )
    }

    // MARK: - Footer Links

    private var footerLinks: some View {
        HStack {
            Link(destination: URL(string: "https://sites.google.com/view/knot-not-privacy-policy/home")!) {
                Text(NSLocalizedString("Privacy", comment: ""))
                    .font(.system(size: 13, weight: .regular))
                    .tracking(-0.08)
                    .foregroundColor(Color("LabelPrimary"))
            }

            Spacer()

            Button(action: {
                Task { await restorePurchases() }
            }) {
                Text(NSLocalizedString("Restore Purchase", comment: ""))
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(-0.08)
                    .foregroundColor(Color("LabelPrimary"))
            }
            .disabled(isProcessing)

            Spacer()

            Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
                Text(NSLocalizedString("Terms", comment: ""))
                    .font(.system(size: 13, weight: .regular))
                    .tracking(-0.08)
                    .foregroundColor(Color("LabelPrimary"))
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Sticky CTA

    private var stickyCTA: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(Color("LabelPrimary").opacity(0.5))

            if let product = purchaseManager.products.first {
                Button(action: {
                    Task { await purchaseProduct(product) }
                }) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("\(product.displayPrice) / Lifetime ")
                                .font(.system(size: 24, weight: .light))
                                .foregroundColor(Color("White"))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        Capsule()
                            .fill(Color("LabelPrimary"))
                    )
                }
                .disabled(isProcessing)
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            } else {
                ProgressView()
                    .padding(24)
            }
        }
        .background(Color("BackgroundPrimary"))
    }

    // MARK: - Auto Advance

    private func startAutoAdvance() {
        autoAdvanceTimer = Timer.scheduledTimer(withTimeInterval: autoAdvanceInterval, repeats: true) { _ in
            withAnimation {
                currentPage = (currentPage + 1) % pageCount
            }
        }
    }

    private func stopAutoAdvance() {
        autoAdvanceTimer?.invalidate()
        autoAdvanceTimer = nil
    }

    private func restartAutoAdvance() {
        stopAutoAdvance()
        startAutoAdvance()
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

private struct PaywallFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(title)
            } icon: {
                Image(systemName: icon)
            }
            .font(.system(size: 17, weight: .semibold))
            .tracking(-0.43)
            .foregroundColor(Color("Orange"))

            Text(description)
                .font(.system(size: 15, weight: .regular))
                .tracking(-0.23)
                .foregroundColor(Color("LabelPrimary").opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Carousel Pages

private struct PaywallCarouselStatistics: View {
    var body: some View {
        VStack(spacing: 30) {
            // Static chart illustration
            HStack(alignment: .bottom, spacing: 7) {
                PaywallBar(height: 46, maxHeight: 148, colors: [Color("Orange")])
                PaywallBar(height: 76, maxHeight: 148, colors: [Color("Orange")])
                PaywallBar(height: 120, maxHeight: 148, colors: [Color("Yellow"), Color("Purple"), Color("Orange")])
                PaywallBar(height: 76, maxHeight: 148, colors: [Color("Orange")])
                PaywallBar(height: 120, maxHeight: 148, colors: [Color("Yellow"), Color("Purple"), Color("Orange")])
                PaywallBar(height: 52, maxHeight: 148, colors: [Color("Orange")])
                PaywallBar(height: 76, maxHeight: 148, colors: [Color("Purple")])
                PaywallBar(height: 76, maxHeight: 148, colors: [Color("Orange")])
            }
            .frame(height: 148)

            Text(NSLocalizedString("Statistics & Insights", comment: ""))
                .font(.system(size: 17, weight: .regular))
                .tracking(-0.43)
                .foregroundColor(Color("LabelPrimary"))
        }
        .padding(.horizontal, 44)
        .padding(.vertical, 24)
    }
}

private struct PaywallBar: View {
    let height: CGFloat
    let maxHeight: CGFloat
    let colors: [Color]

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 30)
                .fill(Color("BackgroundSecondary"))
                .frame(width: 32, height: maxHeight)

            if colors.count == 1 {
                RoundedRectangle(cornerRadius: 30)
                    .fill(colors[0])
                    .frame(width: 32, height: height)
            } else {
                // Stacked segments
                VStack(spacing: 0) {
                    ForEach(Array(colors.enumerated()), id: \.offset) { _, color in
                        Rectangle()
                            .fill(color)
                            .frame(width: 32)
                    }
                }
                .frame(width: 32, height: height)
                .clipShape(RoundedRectangle(cornerRadius: 30))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct PaywallCarouselEmotionTags: View {
    private let tags = ["Sadness", "Anger", "Misunderstanding", "Neglect", "Blamed", "Exhausted"]

    var body: some View {
        VStack(spacing: 30) {
            PaywallFlowLayout(spacing: 8, lineSpacing: 16) {
                ForEach(tags, id: \.self) { tag in
                    Text(LocalizedStringKey(tag))
                        .font(.system(size: 15, weight: .regular))
                        .tracking(-0.23)
                        .foregroundColor(Color("LabelPrimary"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color("BackgroundSecondary"))
                        )
                }
            }
            .frame(height: 148)

            Text(NSLocalizedString("Emotion Tags", comment: ""))
                .font(.system(size: 17, weight: .regular))
                .tracking(-0.43)
                .foregroundColor(Color("LabelPrimary"))
        }
        .padding(.horizontal, 44)
        .padding(.vertical, 24)
    }
}

private struct PaywallFlowLayout: Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(subviews: subviews, width: proposal.width ?? .infinity)
        return CGSize(width: proposal.width ?? result.width, height: result.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        let maxWidth = bounds.width

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.minX + maxWidth, x > bounds.minX {
                x = bounds.minX
                y += size.height + lineSpacing
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
        }
    }

    private func layout(subviews: Subviews, width: CGFloat) -> (width: CGFloat, height: CGFloat) {
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + lineSpacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxHeight = y + rowHeight
        }
        return (width, maxHeight)
    }
}

private struct PaywallCarouselICloudSync: View {
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90.icloud.fill")
                .font(.system(size: 64))
                .foregroundColor(Color("Green"))
                .frame(height: 148)

            Text(NSLocalizedString("iCloud Sync", comment: ""))
                .font(.system(size: 17, weight: .regular))
                .tracking(-0.43)
                .foregroundColor(Color("LabelPrimary"))
        }
        .padding(.horizontal, 44)
        .padding(.vertical, 24)
    }
}

private struct PaywallCarouselUnlimitedNotes: View {
    var body: some View {
        VStack(spacing: 30) {
            VStack(alignment: .leading) {
                Text(NSLocalizedString("Now I can write long notes without character limit! This is helpful for journaling my thoughts and feelings and make me more aware of what's really happening", comment: ""))
                    .font(.system(size: 17, weight: .regular))
                    .tracking(-0.43)
                    .foregroundColor(Color("LabelPrimary").opacity(0.7))
                    .lineLimit(5)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color("BackgroundSecondary"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                    )
            )
            .frame(height: 148, alignment: .top)

            Text(NSLocalizedString("Unlimited Notes", comment: ""))
                .font(.system(size: 17, weight: .regular))
                .tracking(-0.43)
                .foregroundColor(Color("LabelPrimary"))
        }
        .padding(.horizontal, 44)
        .padding(.vertical, 24)
    }
}

private struct PaywallCarouselEarlySupporter: View {
    var body: some View {
        VStack(spacing: 30) {
            // Heart shape drawn with orange stroke
            Image(systemName: "heart")
                .font(.system(size: 80, weight: .bold))
                .foregroundColor(Color("Orange"))
                .frame(height: 148)

            Text(NSLocalizedString("Early Supporter & Future Updates", comment: ""))
                .font(.system(size: 17, weight: .regular))
                .tracking(-0.43)
                .foregroundColor(Color("LabelPrimary"))
        }
        .padding(.horizontal, 44)
        .padding(.vertical, 24)
    }
}

// MARK: - Preview
#Preview {
    PaywallView(feature: .statistics)
        .environmentObject(PurchaseManager.shared)
        .preferredColorScheme(.dark)
}
