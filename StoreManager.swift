import Foundation
import StoreKit
import RevenueCat

@MainActor
class StoreManager: NSObject, ObservableObject {
    @Published var currentOffering: Offering?
    @Published var customerInfo: CustomerInfo?
    @Published var isPremium = false
    @Published var isLoading = false
    @Published var lastError: String?

    static let shared = StoreManager()

    // Entitlement Identifier (RevenueCat'te oluşturduğunuz identifier)
    let premiumEntitlementID = "Pro"

    // Product IDs
    let lifetimeProductID = "brain_dumpster_lifetime_premium"
    let monthlyProductID = "brain_dumpster_monthly_premium"
    let yearlyProductID = "brain_dumpster_yearly_premium"

    private override init() {
        super.init()
        _Concurrency.Task {
            await configure()
            await fetchOfferings()
            await checkSubscriptionStatus()
        }
    }

    // MARK: - Configure RevenueCat
    func configure() async {
        print("🔧 [StoreManager] Starting RevenueCat configuration...")

        // Configure RevenueCat with API key
        Purchases.logLevel = .debug
        print("📝 [StoreManager] API Key: appl_ahYtUaTuzyZwYPLipOKjffhUYIp")
        Purchases.configure(withAPIKey: "appl_ahYtUaTuzyZwYPLipOKjffhUYIp")
        print("✅ [StoreManager] RevenueCat configured successfully")

        // Set user ID if authenticated
        if let userId = AuthService.shared.user?.uid {
            print("👤 [StoreManager] Logging in user to RevenueCat: \(userId)")
            Purchases.shared.logIn(userId) { customerInfo, created, error in
                if let error = error {
                    print("❌ [StoreManager] Failed to log in to RevenueCat: \(error.localizedDescription)")
                    print("🔍 [StoreManager] Error details: \(error)")
                } else {
                    print("✅ [StoreManager] Logged in to RevenueCat successfully")
                    print("📊 [StoreManager] User ID: \(userId)")
                    print("📊 [StoreManager] Created new user: \(created)")
                    if let info = customerInfo {
                        print("📊 [StoreManager] Active entitlements: \(info.entitlements.active.keys)")
                    }
                }
            }
        } else {
            print("⚠️ [StoreManager] No authenticated user, skipping RevenueCat login")
        }

        // Listen for customer info updates
        Purchases.shared.delegate = self
        print("🔔 [StoreManager] Delegate set for customer info updates")
    }

    // MARK: - Fetch Offerings
    func fetchOfferings() async {
        print("📦 [StoreManager] Fetching offerings from RevenueCat...")
        isLoading = true
        lastError = nil

        do {
            let offerings = try await Purchases.shared.offerings()

            await MainActor.run {
                self.currentOffering = offerings.current
                isLoading = false

                if let current = offerings.current {
                    print("✅ [StoreManager] Loaded current offering: \(current.identifier)")
                    print("📊 [StoreManager] Available packages count: \(current.availablePackages.count)")

                    for package in current.availablePackages {
                        print("   📦 Package: \(package.identifier)")
                        print("      Product ID: \(package.storeProduct.productIdentifier)")
                        print("      Price: \(package.storeProduct.localizedPriceString)")
                        print("      Type: \(package.packageType)")
                    }

                    lastError = nil
                } else {
                    print("⚠️ [StoreManager] No current offering available")
                    lastError = "No offerings configured in RevenueCat dashboard"
                }
            }
        } catch {
            await MainActor.run {
                isLoading = false
                lastError = error.localizedDescription
                print("❌ [StoreManager] Failed to load offerings: \(error.localizedDescription)")
                print("🔍 [StoreManager] Error details: \(error)")
            }
        }
    }

    // MARK: - Check Subscription Status
    func checkSubscriptionStatus() async {
        print("🔍 [StoreManager] Checking subscription status...")

        do {
            let customerInfo = try await Purchases.shared.customerInfo()

            await MainActor.run {
                self.customerInfo = customerInfo
                self.isPremium = customerInfo.entitlements[premiumEntitlementID]?.isActive == true

                print("✅ [StoreManager] Subscription status checked")
                print("👑 [StoreManager] Premium status: \(self.isPremium)")
                print("🔑 [StoreManager] Checking entitlement: '\(premiumEntitlementID)'")
                print("📦 [StoreManager] Active entitlements: \(customerInfo.entitlements.active.keys)")
                print("📅 [StoreManager] Latest expiration: \(customerInfo.latestExpirationDate?.description ?? "N/A")")
                print("📅 [StoreManager] Original purchase: \(customerInfo.originalPurchaseDate?.description ?? "N/A")")

                if !customerInfo.entitlements.active.isEmpty {
                    for (key, entitlement) in customerInfo.entitlements.active {
                        print("   ✨ Entitlement: \(key)")
                        print("      Product: \(entitlement.productIdentifier)")
                        print("      Will renew: \(entitlement.willRenew)")
                        print("      Expires: \(entitlement.expirationDate?.description ?? "Never")")
                    }
                }
            }

            // Sync with backend
            await syncWithBackend(customerInfo: customerInfo)

        } catch {
            await MainActor.run {
                print("❌ [StoreManager] Failed to check subscription status: \(error.localizedDescription)")
                print("🔍 [StoreManager] Error details: \(error)")
            }
        }
    }

    // MARK: - Purchase Package
    func purchase(_ package: Package) async throws -> CustomerInfo {
        print("💳 [StoreManager] Starting purchase...")
        print("📦 [StoreManager] Package: \(package.identifier)")
        print("💰 [StoreManager] Product ID: \(package.storeProduct.productIdentifier)")
        print("💵 [StoreManager] Price: \(package.storeProduct.localizedPriceString)")

        isLoading = true

        do {
            print("🔄 [StoreManager] Initiating RevenueCat purchase...")
            let result = try await Purchases.shared.purchase(package: package)

            await MainActor.run {
                self.customerInfo = result.customerInfo
                self.isPremium = result.customerInfo.entitlements[premiumEntitlementID]?.isActive == true
                isLoading = false

                print("✅ [StoreManager] Purchase successful!")
                print("📦 [StoreManager] Product: \(package.storeProduct.productIdentifier)")
                print("👑 [StoreManager] Premium status: \(self.isPremium)")
                print("🔑 [StoreManager] Entitlement '\(premiumEntitlementID)' active: \(self.isPremium)")
                print("📊 [StoreManager] Active entitlements: \(result.customerInfo.entitlements.active.keys)")
            }

            // Sync with backend
            print("🔄 [StoreManager] Syncing purchase with backend...")
            await syncWithBackend(customerInfo: result.customerInfo)

            return result.customerInfo

        } catch {
            await MainActor.run {
                isLoading = false
            }
            print("❌ [StoreManager] Purchase failed: \(error.localizedDescription)")
            print("🔍 [StoreManager] Error details: \(error)")

            if let purchaseError = error as? ErrorCode {
                print("🔍 [StoreManager] RevenueCat error code: \(purchaseError)")
            }

            throw error
        }
    }

    // MARK: - Purchase Product by ID
    func purchaseProduct(productID: String) async throws -> CustomerInfo {
        guard let offering = currentOffering else {
            throw StoreError.productNotFound
        }

        // Find package by product ID
        guard let package = offering.availablePackages.first(where: { package in
            package.storeProduct.productIdentifier == productID
        }) else {
            throw StoreError.productNotFound
        }

        return try await purchase(package)
    }

    // MARK: - Restore Purchases
    func restorePurchases() async throws -> CustomerInfo {
        print("🔄 [StoreManager] Starting restore purchases...")
        isLoading = true

        do {
            let customerInfo = try await Purchases.shared.restorePurchases()

            await MainActor.run {
                self.customerInfo = customerInfo
                self.isPremium = customerInfo.entitlements[premiumEntitlementID]?.isActive == true
                isLoading = false

                print("✅ [StoreManager] Purchases restored successfully")
                print("👑 [StoreManager] Premium status: \(self.isPremium)")
                print("🔑 [StoreManager] Entitlement '\(premiumEntitlementID)' active: \(self.isPremium)")
                print("📦 [StoreManager] Active entitlements: \(customerInfo.entitlements.active.keys)")

                if customerInfo.entitlements.active.isEmpty {
                    print("⚠️ [StoreManager] No active purchases found to restore")
                } else {
                    for (key, entitlement) in customerInfo.entitlements.active {
                        print("   ✨ Restored: \(key) - \(entitlement.productIdentifier)")
                    }
                }
            }

            // Sync with backend
            print("🔄 [StoreManager] Syncing restored purchases with backend...")
            await syncWithBackend(customerInfo: customerInfo)

            return customerInfo

        } catch {
            await MainActor.run {
                isLoading = false
            }
            print("❌ [StoreManager] Failed to restore purchases: \(error.localizedDescription)")
            print("🔍 [StoreManager] Error details: \(error)")
            throw error
        }
    }

    // MARK: - Sync with Backend
    private func syncWithBackend(customerInfo: CustomerInfo) async {
        print("🌐 [StoreManager] Starting backend sync...")

        guard let userId = AuthService.shared.user?.uid else {
            print("⚠️ [StoreManager] No user ID, skipping backend sync")
            return
        }

        print("👤 [StoreManager] User ID: \(userId)")
        let isPremium = customerInfo.entitlements[premiumEntitlementID]?.isActive == true
        print("👑 [StoreManager] Is Premium: \(isPremium)")
        print("🔑 [StoreManager] Entitlement '\(premiumEntitlementID)' status: \(isPremium)")

        // Prepare subscription status data
        let subscriptionStatus: [String: Any] = [
            "is_premium": isPremium,
            "active_entitlements": Array(customerInfo.entitlements.active.keys),
            "expiration_date": customerInfo.latestExpirationDate?.ISO8601Format() ?? NSNull(),
            "purchase_date": customerInfo.originalPurchaseDate?.ISO8601Format() ?? NSNull(),
            "will_renew": customerInfo.entitlements[premiumEntitlementID]?.willRenew ?? false
        ]

        let requestData: [String: Any] = [
            "user_id": userId,
            "subscription_status": subscriptionStatus,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]

        print("📤 [StoreManager] Sending sync request to backend...")
        print("📊 [StoreManager] Data: \(subscriptionStatus)")

        do {
            let response = try await BraindumpsterAPI.shared.syncSubscriptionStatus(data: requestData)
            print("✅ [StoreManager] Backend sync successful")
            print("📥 [StoreManager] Response: \(response)")
        } catch {
            print("❌ [StoreManager] Failed to sync with backend: \(error.localizedDescription)")
            print("🔍 [StoreManager] Error details: \(error)")
        }
    }

    // MARK: - Get Package by Product ID
    func package(for productID: String) -> Package? {
        return currentOffering?.availablePackages.first { package in
            package.storeProduct.productIdentifier == productID
        }
    }

    // MARK: - Get Product by ID
    func product(for productID: String) -> StoreProduct? {
        return currentOffering?.availablePackages.first { package in
            package.storeProduct.productIdentifier == productID
        }?.storeProduct
    }
}

// MARK: - PurchasesDelegate
extension StoreManager: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        print("🔔 [StoreManager] Received customer info update from RevenueCat")

        _Concurrency.Task {
            await MainActor.run {
                self.customerInfo = customerInfo
                self.isPremium = customerInfo.entitlements[premiumEntitlementID]?.isActive == true

                print("🔄 [StoreManager] Customer info updated")
                print("👑 [StoreManager] Premium status: \(self.isPremium)")
                print("🔑 [StoreManager] Entitlement '\(premiumEntitlementID)' active: \(self.isPremium)")
                print("📦 [StoreManager] Active entitlements: \(customerInfo.entitlements.active.keys)")
            }

            // Sync with backend
            print("🔄 [StoreManager] Syncing updated info with backend...")
            await syncWithBackend(customerInfo: customerInfo)
        }
    }
}

// MARK: - Store Error
enum StoreError: Error {
    case failedVerification
    case purchaseFailed
    case productNotFound
    case configurationError
}

// MARK: - StoreProduct Extensions
extension StoreProduct {
    var isLifetime: Bool {
        return productIdentifier == "brain_dumpster_lifetime_premium"
    }

    var isMonthly: Bool {
        return productIdentifier == "brain_dumpster_monthly_premium"
    }

    var isYearly: Bool {
        return productIdentifier == "brain_dumpster_yearly_premium"
    }
}

// MARK: - Package Extensions
extension Package {
    var isLifetime: Bool {
        return storeProduct.productIdentifier == "brain_dumpster_lifetime_premium"
    }

    var isMonthly: Bool {
        return storeProduct.productIdentifier == "brain_dumpster_monthly_premium"
    }

    var isYearly: Bool {
        return storeProduct.productIdentifier == "brain_dumpster_yearly_premium"
    }
}
