import SwiftUI

struct SubscriptionManagementView: View {
    @StateObject private var viewModel = SubscriptionManagementViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.97, blue: 1.0),
                        Color.white
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection

                        // Current subscription status
                        if viewModel.isLoading {
                            loadingView
                        } else if let subscription = viewModel.subscription {
                            subscriptionDetailsSection(subscription)

                            // Action buttons
                            actionButtonsSection(subscription)

                            // Plan comparison
                            if subscription.status != "lifetime" {
                                availablePlansSection
                            }
                        } else {
                            noSubscriptionView
                        }

                        // Help section
                        helpSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Manage Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .alert("Cancel Subscription?", isPresented: $viewModel.showCancelConfirmation) {
                Button("Cancel Subscription", role: .destructive) {
                    _Concurrency.Task {
                        await viewModel.cancelSubscription()
                    }
                }
                Button("Keep Subscription", role: .cancel) {}
            } message: {
                Text("You'll keep premium access until \(viewModel.subscription?.expirationDate?.formatted(date: .long, time: .omitted) ?? "expiration")")
            }
        }
        .onAppear {
            _Concurrency.Task {
                await viewModel.loadSubscription()
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "crown.fill")
                .font(.system(size: 50))
                .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3), radius: 10)

            Text("Premium Membership")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading subscription...")
                .font(.system(size: 16))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Subscription Details
    private func subscriptionDetailsSection(_ subscription: SubscriptionInfo) -> some View {
        VStack(spacing: 16) {
            // Status card
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: subscription.isActive ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(subscription.isActive ? .green : .orange)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(subscription.isActive ? "Active" : "Expired")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)

                        Text(subscription.planDisplayName)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }

                    Spacer()
                }

                Divider()

                // Plan details
                VStack(spacing: 10) {
                    detailRow(
                        icon: "calendar",
                        title: "Renewal Date",
                        value: subscription.expirationDate?.formatted(date: .long, time: .omitted) ?? "N/A"
                    )

                    if subscription.tier != "lifetime" {
                        detailRow(
                            icon: "arrow.clockwise",
                            title: "Auto-Renewal",
                            value: subscription.willRenew ? "On" : "Off"
                        )
                    }

                    if let cancelledAt = subscription.cancelledAt {
                        detailRow(
                            icon: "xmark.circle",
                            title: "Cancelled On",
                            value: cancelledAt.formatted(date: .long, time: .omitted),
                            valueColor: .red
                        )
                    }
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
        }
    }

    // MARK: - Action Buttons
    private func actionButtonsSection(_ subscription: SubscriptionInfo) -> some View {
        VStack(spacing: 12) {
            // Cancel button (only if active and will renew)
            if subscription.isActive && subscription.willRenew && subscription.tier != "lifetime" {
                Button(action: {
                    viewModel.showCancelConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                        Text("Cancel Subscription")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(12)
                }
            }

            // Restore purchases button
            Button(action: {
                _Concurrency.Task {
                    await viewModel.restorePurchases()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.system(size: 18))
                    Text("Restore Purchases")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(red: 0.4, green: 0.75, blue: 0.88).opacity(0.1))
                .foregroundColor(Color(red: 0.4, green: 0.75, blue: 0.88))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Available Plans
    private var availablePlansSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Available Plans")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 4)

            VStack(spacing: 12) {
                planCard(
                    name: "Yearly Premium",
                    price: "$29.99/year",
                    features: ["Best value", "Save 58%", "Full access"],
                    productID: "brain_dumpster_yearly_premium"
                )

                planCard(
                    name: "Monthly Premium",
                    price: "$5.99/month",
                    features: ["Monthly billing", "Cancel anytime", "Full access"],
                    productID: "brain_dumpster_monthly_premium"
                )

                planCard(
                    name: "Lifetime Premium",
                    price: "$79.99 once",
                    features: ["One-time payment", "Forever access", "Best for power users"],
                    productID: "brain_dumpster_lifetime_premium"
                )
            }
        }
    }

    // MARK: - No Subscription View
    private var noSubscriptionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "crown")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text("No Active Subscription")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.black)

            Text("Upgrade to Premium to unlock all features")
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Button(action: {
                // Close this view and let user open Premium view from Settings
                dismiss()
            }) {
                Text("View Plans")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(red: 0.4, green: 0.75, blue: 0.88))
                    .cornerRadius(12)
            }
            .padding(.top, 10)
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
    }

    // MARK: - Help Section
    private var helpSection: some View {
        VStack(spacing: 12) {
            Text("Need Help?")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gray)

            Button(action: {
                if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
                    #if canImport(UIKit)
                    UIApplication.shared.open(url)
                    #endif
                }
            }) {
                HStack {
                    Image(systemName: "gearshape.fill")
                    Text("Manage in Apple Settings")
                        .font(.system(size: 14))
                }
                .foregroundColor(Color(red: 0.4, green: 0.75, blue: 0.88))
            }
        }
        .padding(.top, 20)
    }

    // MARK: - Helper Views
    private func detailRow(icon: String, title: String, value: String, valueColor: Color = .black) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.4, green: 0.75, blue: 0.88))
                .frame(width: 24)

            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.gray)

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(valueColor)
        }
    }

    private func planCard(name: String, price: String, features: [String], productID: String) -> some View {
        Button(action: {
            _Concurrency.Task {
                await viewModel.switchPlan(productID: productID)
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.black)

                        Text(price)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(red: 0.4, green: 0.75, blue: 0.88))
                    }

                    Spacer()

                    if viewModel.subscription?.tier == productIDToTier(productID) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(features, id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.green)

                            Text(feature)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        viewModel.subscription?.tier == productIDToTier(productID)
                            ? Color(red: 0.4, green: 0.75, blue: 0.88)
                            : Color.clear,
                        lineWidth: 2
                    )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func productIDToTier(_ productID: String) -> String {
        if productID.contains("yearly") {
            return "yearly"
        } else if productID.contains("monthly") {
            return "monthly"
        } else if productID.contains("lifetime") {
            return "lifetime"
        }
        return "unknown"
    }
}

// MARK: - Subscription Info Model
struct SubscriptionInfo {
    let tier: String
    let isActive: Bool
    let willRenew: Bool
    let expirationDate: Date?
    let cancelledAt: Date?
    let status: String

    var planDisplayName: String {
        switch tier {
        case "yearly":
            return "Yearly Premium"
        case "monthly":
            return "Monthly Premium"
        case "lifetime":
            return "Lifetime Premium"
        default:
            return "Premium"
        }
    }
}

// MARK: - ViewModel
@MainActor
class SubscriptionManagementViewModel: ObservableObject {
    @Published var subscription: SubscriptionInfo?
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var showCancelConfirmation = false

    func loadSubscription() async {
        isLoading = true

        do {
            print("🔍 [SubscriptionManagement] Loading subscription status...")

            // Get subscription from backend
            let response = try await BraindumpsterAPI.shared.getSubscriptionStatus()

            print("📦 [SubscriptionManagement] API Response: \(response)")

            // Backend returns subscription data directly (not wrapped in "subscription" key)
            let tier = response["tier"] as? String ?? response["current_tier"] as? String ?? "unknown"
            let isActive = response["is_active"] as? Bool ?? false
            let isPremium = response["is_premium"] as? Bool ?? false
            let willRenew = response["will_renew"] as? Bool ?? true
            let status = response["status"] as? String ?? "unknown"

            print("   Tier: \(tier)")
            print("   Is Active: \(isActive)")
            print("   Is Premium: \(isPremium)")
            print("   Will Renew: \(willRenew)")
            print("   Status: \(status)")

            // Only create subscription if user has premium
            if isPremium || isActive {
                // Parse dates
                var expirationDate: Date?
                if let expirationString = response["expiration_date"] as? String {
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    expirationDate = formatter.date(from: expirationString)

                    // Try without fractional seconds if failed
                    if expirationDate == nil {
                        formatter.formatOptions = [.withInternetDateTime]
                        expirationDate = formatter.date(from: expirationString)
                    }

                    print("   Expiration: \(expirationString) → \(expirationDate?.description ?? "nil")")
                }

                var cancelledAt: Date?
                if let cancelledString = response["cancelled_at"] as? String {
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    cancelledAt = formatter.date(from: cancelledString)

                    if cancelledAt == nil {
                        formatter.formatOptions = [.withInternetDateTime]
                        cancelledAt = formatter.date(from: cancelledString)
                    }

                    print("   Cancelled At: \(cancelledString)")
                }

                subscription = SubscriptionInfo(
                    tier: tier,
                    isActive: isActive,
                    willRenew: willRenew,
                    expirationDate: expirationDate,
                    cancelledAt: cancelledAt,
                    status: status
                )

                print("✅ [SubscriptionManagement] Subscription info created successfully")
            } else {
                print("⚠️ [SubscriptionManagement] User has no active subscription")
                subscription = nil
            }
        } catch {
            print("❌ [SubscriptionManagement] Error loading subscription: \(error)")
            errorMessage = "Failed to load subscription: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    func cancelSubscription() async {
        isLoading = true

        do {
            try await BraindumpsterAPI.shared.cancelSubscription(reason: "user_cancelled")

            // Reload subscription
            await loadSubscription()
        } catch {
            errorMessage = "Failed to cancel subscription: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    func restorePurchases() async {
        isLoading = true

        do {
            // Restore purchases through StoreKit
            await NativeStoreManager.shared.updatePurchaseStatus()

            // Reload subscription from backend
            await loadSubscription()
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    func switchPlan(productID: String) async {
        isLoading = true

        do {
            // Find product
            guard let product = NativeStoreManager.shared.products.first(where: { $0.id == productID }) else {
                throw NSError(domain: "SubscriptionManagement", code: 1, userInfo: [NSLocalizedDescriptionKey: "Product not found"])
            }

            // Purchase new plan
            _ = try await NativeStoreManager.shared.purchase(product)

            // Reload subscription
            await loadSubscription()
        } catch {
            errorMessage = "Failed to switch plan: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }
}
