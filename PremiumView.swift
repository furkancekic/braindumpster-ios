import SwiftUI
import StoreKit

struct PremiumView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var storeManager = NativeStoreManager.shared
    @State private var selectedProductID: String = "brain_dumpster_yearly_premium"
    @State private var isPurchasing = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastType = .success
    @State private var showTermsOfService = false
    @State private var showPrivacyPolicy = false

    let premiumFeatures = [
        PremiumFeature(icon: "infinity", title: "Unlimited Everything", description: "No limits. Dump as many tasks as you need"),
        PremiumFeature(icon: "brain.head.profile", title: "AI That Gets You", description: "Smart suggestions that actually help"),
        PremiumFeature(icon: "mic.fill", title: "Just Say It", description: "Voice commands for hands-free task creation"),
        PremiumFeature(icon: "chart.bar.fill", title: "See Your Progress", description: "Visual insights into your productivity"),
        PremiumFeature(icon: "bell.badge.fill", title: "Never Forget Again", description: "Smart reminders that work for you"),
        PremiumFeature(icon: "icloud.fill", title: "Everywhere You Are", description: "Seamless sync across all your devices")
    ]

    var body: some View {
        ZStack {
            Color(white: 0.98)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Close Button
                    HStack {
                        Spacer()
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(Color(white: 0.7))
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 10)
                    }

                    // Premium Badge
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 1.0, green: 0.84, blue: 0.0),
                                            Color(red: 1.0, green: 0.65, blue: 0.0)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3), radius: 20, x: 0, y: 10)

                            Image(systemName: "crown.fill")
                                .font(.system(size: 45))
                                .foregroundColor(.white)
                        }

                        Text("Go Premium ✨")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black)

                        Text("Stop juggling tasks.\nStart crushing goals.")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color(white: 0.5))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 20)

                    // Premium Features
                    VStack(spacing: 16) {
                        ForEach(premiumFeatures) { feature in
                            PremiumFeatureRow(feature: feature)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Subscription Plans
                    VStack(spacing: 12) {
                        Text("Choose Your Plan")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.top, 8)

                        if storeManager.isLoading {
                            ProgressView()
                                .padding(.vertical, 40)
                        } else if !storeManager.products.isEmpty {
                            // Yearly Plan
                            if let yearlyProduct = storeManager.yearlyProduct {
                                NativePlanCard(
                                    product: yearlyProduct,
                                    isSelected: selectedProductID == yearlyProduct.id,
                                    badge: "MOST POPULAR",
                                    savings: "Save 50%"
                                ) {
                                    selectedProductID = yearlyProduct.id
                                }
                            }

                            // Monthly Plan
                            if let monthlyProduct = storeManager.monthlyProduct {
                                NativePlanCard(
                                    product: monthlyProduct,
                                    isSelected: selectedProductID == monthlyProduct.id
                                ) {
                                    selectedProductID = monthlyProduct.id
                                }
                            }

                            // Lifetime Plan
                            if let lifetimeProduct = storeManager.lifetimeProduct {
                                NativePlanCard(
                                    product: lifetimeProduct,
                                    isSelected: selectedProductID == lifetimeProduct.id,
                                    badge: "BEST VALUE"
                                ) {
                                    selectedProductID = lifetimeProduct.id
                                }
                            }
                        } else {
                            // Fallback pricing when products unavailable
                            FallbackPlanCard(
                                title: "Yearly Premium",
                                price: "$49.99",
                                period: "year",
                                productID: "brain_dumpster_yearly_premium",
                                badge: "MOST POPULAR",
                                savings: "Save 50%",
                                isSelected: selectedProductID == "brain_dumpster_yearly_premium"
                            ) {
                                selectedProductID = "brain_dumpster_yearly_premium"
                            }

                            FallbackPlanCard(
                                title: "Monthly Premium",
                                price: "$9.99",
                                period: "month",
                                productID: "brain_dumpster_monthly_premium",
                                badge: nil,
                                savings: nil,
                                isSelected: selectedProductID == "brain_dumpster_monthly_premium"
                            ) {
                                selectedProductID = "brain_dumpster_monthly_premium"
                            }

                            FallbackPlanCard(
                                title: "Lifetime Premium",
                                price: "$99.99",
                                period: "one-time",
                                productID: "brain_dumpster_lifetime_premium",
                                badge: "BEST VALUE",
                                savings: nil,
                                isSelected: selectedProductID == "brain_dumpster_lifetime_premium"
                            ) {
                                selectedProductID = "brain_dumpster_lifetime_premium"
                            }

                            Text("⚠️ Products awaiting approval - Showing preview pricing")
                                .font(.system(size: 10))
                                .foregroundColor(Color(white: 0.6))
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Purchase Button
                    Button(action: {
                        purchaseSelected()
                    }) {
                        if isPurchasing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        } else {
                            Text("Start Your Premium Journey →")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        }
                    }
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.35, green: 0.75, blue: 0.95),
                                Color(red: 0.45, green: 0.55, blue: 0.95)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .disabled(isPurchasing)
                    .opacity(isPurchasing ? 0.6 : 1.0)
                    .padding(.horizontal, 20)

                    // Restore Purchases
                    Button(action: {
                        restorePurchases()
                    }) {
                        Text("Restore Purchases")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 0.4, green: 0.75, blue: 0.88))
                    }
                    .disabled(isPurchasing)

                    // Legal
                    HStack(spacing: 8) {
                        Button(action: {
                            showTermsOfService = true
                        }) {
                            Text("Terms of Service")
                                .font(.system(size: 13))
                                .foregroundColor(Color(white: 0.5))
                                .underline()
                        }
                        .buttonStyle(.plain)

                        Text("•")
                            .font(.system(size: 13))
                            .foregroundColor(Color(white: 0.5))

                        Button(action: {
                            showPrivacyPolicy = true
                        }) {
                            Text("Privacy Policy")
                                .font(.system(size: 13))
                                .foregroundColor(Color(white: 0.5))
                                .underline()
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showTermsOfService) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .toast(isShowing: $showToast, message: toastMessage, type: toastType)
        .onAppear {
            // Pre-select yearly if available
            if let yearlyProduct = storeManager.yearlyProduct {
                selectedProductID = yearlyProduct.id
            }
        }
    }

    // MARK: - Purchase Selected
    private func purchaseSelected() {
        guard let product = storeManager.product(for: selectedProductID) else {
            toastMessage = "Products are awaiting App Store approval. You can still view pricing!"
            toastType = .info
            showToast = true
            return
        }

        isPurchasing = true

        _Concurrency.Task {
            do {
                let transaction = try await storeManager.purchase(product)

                if transaction != nil {
                    await MainActor.run {
                        isPurchasing = false
                        toastMessage = "Welcome to Premium! 🎉 You're all set!"
                        toastType = .success
                        showToast = true
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                } else {
                    await MainActor.run {
                        isPurchasing = false
                        toastMessage = "Purchase cancelled or pending"
                        toastType = .info
                        showToast = true
                    }
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    toastMessage = "Payment didn't go through 😕 Try again?"
                    toastType = .error
                    showToast = true
                }
            }
        }
    }

    // MARK: - Restore Purchases
    private func restorePurchases() {
        isPurchasing = true

        _Concurrency.Task {
            do {
                try await storeManager.restorePurchases()

                await MainActor.run {
                    isPurchasing = false

                    if storeManager.isPremium {
                        toastMessage = "All restored! Welcome back Premium member 🌟"
                        toastType = .success
                        showToast = true

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            dismiss()
                        }
                    } else {
                        toastMessage = "No Premium purchase found. Want to try? 💎"
                        toastType = .info
                        showToast = true
                    }
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    toastMessage = "Restore didn't work 😕 Try again?"
                    toastType = .error
                    showToast = true
                }
            }
        }
    }
}

// MARK: - Premium Feature Model
struct PremiumFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

// MARK: - Premium Feature Row
struct PremiumFeatureRow: View {
    let feature: PremiumFeature

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.35, green: 0.75, blue: 0.95).opacity(0.2),
                                Color(red: 0.45, green: 0.55, blue: 0.95).opacity(0.2)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: feature.icon)
                    .font(.system(size: 22))
                    .foregroundColor(Color(red: 0.4, green: 0.65, blue: 0.95))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)

                Text(feature.description)
                    .font(.system(size: 14))
                    .foregroundColor(Color(white: 0.5))
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
    }
}

// MARK: - Native Plan Card
struct NativePlanCard: View {
    let product: Product
    let isSelected: Bool
    var badge: String? = nil
    var savings: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                // Badge
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 1.0, green: 0.84, blue: 0.0),
                                    Color(red: 1.0, green: 0.65, blue: 0.0)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(8, corners: [.topLeft, .topRight])
                }

                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(product.displayName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)

                        if let savings = savings {
                            Text(savings)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                        }

                        Text(subscriptionPeriodText)
                            .font(.system(size: 13))
                            .foregroundColor(Color(white: 0.5))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(product.displayPrice)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)

                        if product.type == .autoRenewable {
                            Text(pricePerMonth)
                                .font(.system(size: 12))
                                .foregroundColor(Color(white: 0.5))
                        }
                    }

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? Color(red: 0.4, green: 0.65, blue: 0.95) : Color(white: 0.8))
                        .padding(.leading, 12)
                }
                .padding(20)
            }
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ?
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.35, green: 0.75, blue: 0.95),
                                Color(red: 0.45, green: 0.55, blue: 0.95)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [Color(white: 0.9)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(color: isSelected ? Color(red: 0.4, green: 0.65, blue: 0.95).opacity(0.2) : .clear, radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }

    private var subscriptionPeriodText: String {
        if product.type == .nonConsumable {
            return "One-time payment"
        } else if let subscription = product.subscription {
            switch subscription.subscriptionPeriod.unit {
            case .year:
                return "Annual subscription"
            case .month:
                return "Monthly subscription"
            case .week:
                return "Weekly subscription"
            case .day:
                return "Daily subscription"
            @unknown default:
                return "Subscription"
            }
        } else {
            return "Subscription"
        }
    }

    private var pricePerMonth: String {
        if let subscription = product.subscription {
            switch subscription.subscriptionPeriod.unit {
            case .year:
                let monthlyPrice = product.price / 12
                return String(format: "$%.2f/month", monthlyPrice as NSNumber as! Double)
            case .month:
                return product.displayPrice + "/month"
            default:
                return ""
            }
        }
        return ""
    }
}

// MARK: - Fallback Plan Card
struct FallbackPlanCard: View {
    let title: String
    let price: String
    let period: String
    let productID: String
    let badge: String?
    let savings: String?
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)

                        HStack(spacing: 4) {
                            Text(price)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(red: 0.4, green: 0.75, blue: 0.95))

                            Text("/ \(period)")
                                .font(.system(size: 14))
                                .foregroundColor(Color(white: 0.5))
                        }
                    }

                    Spacer()

                    // Checkmark
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color(red: 0.4, green: 0.75, blue: 0.95) : Color.clear)
                            .frame(width: 24, height: 24)

                        Circle()
                            .stroke(isSelected ? Color.clear : Color(white: 0.8), lineWidth: 2)
                            .frame(width: 24, height: 24)

                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }

                // Badge and savings
                if badge != nil || savings != nil {
                    HStack(spacing: 8) {
                        if let badge = badge {
                            Text(badge)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.35, green: 0.75, blue: 0.95),
                                            Color(red: 0.45, green: 0.55, blue: 0.95)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(4)
                        }

                        if let savings = savings {
                            Text(savings)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
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
                        isSelected
                            ? Color(red: 0.4, green: 0.75, blue: 0.95)
                            : Color(white: 0.9),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(color: isSelected ? Color(red: 0.4, green: 0.75, blue: 0.95).opacity(0.3) : Color.black.opacity(0.05), radius: isSelected ? 8 : 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PremiumView()
}
