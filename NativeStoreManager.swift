import Foundation
import StoreKit

@MainActor
class NativeStoreManager: ObservableObject {
    static let shared = NativeStoreManager()

    // Product IDs
    private let productIDs = [
        "brain_dumpster_monthly_premium",
        "brain_dumpster_yearly_premium",
        "brain_dumpster_lifetime_premium"
    ]

    // Published properties
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var isPremium = false
    @Published var premiumExpirationDate: Date?
    @Published var currentPremiumProductID: String?
    @Published var isInBillingRetry = false
    @Published var daysUntilExpiration: Int?

    private var updateListenerTask: _Concurrency.Task<Void, Never>?
    private var expirationCheckTimer: Timer?

    private init() {
        // Start listening for transactions
        updateListenerTask = listenForTransactions()

        // Load products and check purchase status
        _Concurrency.Task {
            await loadProducts()
            await updatePurchaseStatus()
            await startExpirationMonitoring()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products
    func loadProducts() async {
        print("🛒 [NativeStore] Loading products...")
        isLoading = true

        do {
            let loadedProducts = try await Product.products(for: productIDs)
            products = loadedProducts.sorted { product1, product2 in
                // Sort: Yearly, Monthly, Lifetime
                if product1.id.contains("yearly") { return true }
                if product2.id.contains("yearly") { return false }
                if product1.id.contains("monthly") { return true }
                return false
            }

            print("✅ [NativeStore] Loaded \(products.count) products")
            for product in products {
                print("   📦 \(product.displayName): \(product.displayPrice)")
            }
        } catch {
            print("❌ [NativeStore] Failed to load products: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - Purchase Product
    func purchase(_ product: Product) async throws -> Transaction? {
        print("🛍️ [NativeStore] Initiating purchase for: \(product.displayName)")
        print("   Product ID: \(product.id)")
        print("   Price: \(product.displayPrice)")
        print("   Environment: \(getEnvironment())")

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                print("✅ [NativeStore] Purchase successful")
                print("   Verification result received")

                // First, do basic StoreKit verification (ensures Apple signature is valid)
                let transaction = try checkVerified(verification)

                print("   ✅ StoreKit verification passed (Apple signature valid)")
                print("   Transaction ID: \(transaction.id)")
                print("   Product ID: \(transaction.productID)")
                print("   Purchase Date: \(transaction.purchaseDate)")
                print("   Environment: \(transaction.environment)")

                // NOW: Verify with backend (server-side validation)
                // CRITICAL: This is NON-BLOCKING for App Review
                // StoreKit verification alone is sufficient for security
                print("🔐 [NativeStore] Verifying receipt with backend...")

                do {
                    let userId = AuthService.shared.user?.uid
                    let backendResponse = try await ReceiptValidationService.shared.verifyReceipt(
                        transaction: transaction,
                        userId: userId
                    )

                    if backendResponse.success && backendResponse.isPremium {
                        print("✅ [NativeStore] Backend verification successful!")
                        print("   Premium: \(backendResponse.isPremium)")
                        print("   Product: \(backendResponse.productId ?? "N/A")")
                        print("   Backend Environment: \(backendResponse.environment ?? "N/A")")
                    } else {
                        print("⚠️ [NativeStore] Backend verification returned non-premium status")
                        print("   Message: \(backendResponse.message ?? "No message")")
                        print("   Proceeding with StoreKit-only verification")
                    }

                } catch let validationError as ReceiptValidationError {
                    print("⚠️ [NativeStore] Backend validation error (non-blocking): \(validationError.localizedDescription)")
                    print("   Proceeding with StoreKit-only verification")

                    // Log error details for debugging
                    switch validationError {
                    case .noReceiptAvailable:
                        print("   Reason: No receipt available")
                    case .timeout:
                        print("   Reason: Request timeout")
                    case .networkError(let error):
                        print("   Reason: Network error - \(error.localizedDescription)")
                    case .serverError(let code, let message):
                        print("   Reason: Server error (\(code)) - \(message ?? "Unknown")")
                    case .invalidResponse:
                        print("   Reason: Invalid response format")
                    case .maxRetriesExceeded:
                        print("   Reason: Max retries exceeded")
                    }
                } catch {
                    print("⚠️ [NativeStore] Unexpected backend error (non-blocking): \(error.localizedDescription)")
                    print("   Proceeding with StoreKit-only verification")
                }

                // ALWAYS finish transaction and unlock premium after StoreKit verification
                // Backend verification is supplementary, not required
                print("✅ [NativeStore] StoreKit verification passed - unlocking premium")
                await updatePurchaseStatus()
                await transaction.finish()

                print("🎉 [NativeStore] Transaction finished: \(transaction.productID)")

                return transaction

            case .userCancelled:
                print("❌ [NativeStore] User cancelled purchase")
                return nil

            case .pending:
                print("⏳ [NativeStore] Purchase pending approval (Ask to Buy or pending review)")
                return nil

            @unknown default:
                print("❌ [NativeStore] Unknown purchase result")
                return nil
            }
        } catch StoreKitError.userCancelled {
            print("❌ [NativeStore] User cancelled during purchase")
            throw StoreKitError.userCancelled
        } catch StoreKitError.networkError(let error) {
            print("❌ [NativeStore] Network error during purchase: \(error.localizedDescription)")
            throw StoreKitError.networkError(error)
        } catch {
            print("❌ [NativeStore] Purchase error: \(error.localizedDescription)")
            print("   Error domain: \(error._domain)")
            print("   Error code: \(error._code)")
            throw error
        }
    }

    // MARK: - Restore Purchases
    func restorePurchases() async throws {
        print("🔄 [NativeStore] Restoring purchases...")
        print("   Environment: \(getEnvironment())")

        do {
            try await AppStore.sync()
            print("   ✅ AppStore.sync() completed")

            // Verify with backend for each active transaction
            var hasValidPurchase = false

            for await result in Transaction.currentEntitlements {
                do {
                    let transaction = try checkVerified(result)

                    print("🔐 [NativeStore] Verifying restored transaction with backend...")
                    print("   Product ID: \(transaction.productID)")

                    // Verify with backend
                    let userId = AuthService.shared.user?.uid
                    let backendResponse = try await ReceiptValidationService.shared.verifyReceipt(
                        transaction: transaction,
                        userId: userId
                    )

                    if backendResponse.success && backendResponse.isPremium {
                        hasValidPurchase = true
                        print("✅ [NativeStore] Restored purchase verified by backend")
                    } else {
                        print("⚠️ [NativeStore] Backend did not confirm premium status")
                    }

                } catch let validationError as ReceiptValidationError {
                    print("⚠️ [NativeStore] Backend verification failed during restore: \(validationError.localizedDescription)")
                    // Continue with local verification if backend fails
                } catch {
                    print("⚠️ [NativeStore] Transaction verification failed: \(error.localizedDescription)")
                }
            }

            await updatePurchaseStatus()

            print("✅ [NativeStore] Purchases restored successfully")
            print("   Active products: \(purchasedProductIDs)")
            print("   Backend verified: \(hasValidPurchase ? "Yes" : "No (using local verification)")")
        } catch {
            print("❌ [NativeStore] Restore purchases failed: \(error.localizedDescription)")
            print("   Error domain: \(error._domain)")
            print("   Error code: \(error._code)")
            throw error
        }
    }

    // MARK: - Update Purchase Status
    func updatePurchaseStatus() async {
        print("🔍 [NativeStore] Checking purchase status...")
        print("   Environment: \(getEnvironment())")

        var purchasedIDs: Set<String> = []
        var entitlementCount = 0
        var latestExpirationDate: Date?
        var activePremiumProductID: String?

        for await result in Transaction.currentEntitlements {
            entitlementCount += 1

            do {
                let transaction = try checkVerified(result)

                // Add to purchased products
                purchasedIDs.insert(transaction.productID)

                // Track expiration date (for auto-renewable subscriptions)
                if let expirationDate = transaction.expirationDate {
                    if latestExpirationDate == nil || expirationDate > latestExpirationDate! {
                        latestExpirationDate = expirationDate
                        activePremiumProductID = transaction.productID
                    }
                } else {
                    // Lifetime purchase (no expiration)
                    latestExpirationDate = nil
                    activePremiumProductID = transaction.productID
                }

                print("   ✅ Active entitlement #\(entitlementCount):")
                print("      Product ID: \(transaction.productID)")
                print("      Transaction ID: \(transaction.id)")
                print("      Purchase Date: \(transaction.purchaseDate)")
                print("      Expiration Date: \(transaction.expirationDate?.description ?? "Lifetime")")
                print("      Environment: \(transaction.environment)")
                print("      Revocation Date: \(transaction.revocationDate?.description ?? "None")")

            } catch {
                print("   ❌ Failed to verify entitlement #\(entitlementCount)")
                print("      Error: \(error.localizedDescription)")
                print("      Error type: \(type(of: error))")
            }
        }

        purchasedProductIDs = purchasedIDs
        isPremium = !purchasedIDs.isEmpty
        premiumExpirationDate = latestExpirationDate
        currentPremiumProductID = activePremiumProductID

        print("👑 [NativeStore] Purchase status check complete:")
        print("   Premium: \(isPremium)")
        print("   Active products: \(purchasedProductIDs.isEmpty ? "None" : purchasedProductIDs.joined(separator: ", "))")
        print("   Expiration: \(premiumExpirationDate?.description ?? "Lifetime")")
        print("   Total entitlements checked: \(entitlementCount)")

        // Check billing retry status
        await checkBillingRetryStatus()

        // Sync with backend if user has premium
        if isPremium, let productID = activePremiumProductID, let expirationDate = latestExpirationDate {
            print("🔄 [NativeStore] Syncing subscription status with backend...")

            do {
                try await syncSubscriptionWithBackend(
                    productID: productID,
                    expirationDate: expirationDate
                )
                print("✅ [NativeStore] Backend sync successful")
            } catch {
                print("⚠️ [NativeStore] Backend sync failed (non-critical): \(error.localizedDescription)")
            }
        } else if isPremium, let productID = activePremiumProductID {
            // Lifetime subscription (no expiration)
            print("🔄 [NativeStore] Syncing lifetime subscription with backend...")

            do {
                try await syncSubscriptionWithBackend(
                    productID: productID,
                    expirationDate: nil
                )
                print("✅ [NativeStore] Backend sync successful")
            } catch {
                print("⚠️ [NativeStore] Backend sync failed (non-critical): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Listen for Transactions
    private func listenForTransactions() -> _Concurrency.Task<Void, Never> {
        return _Concurrency.Task.detached {
            print("👂 [NativeStore] Listening for transaction updates...")

            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)

                    print("🔔 [NativeStore] Transaction update received:")
                    print("   Product ID: \(transaction.productID)")
                    print("   Transaction ID: \(transaction.id)")
                    print("   Environment: \(transaction.environment)")
                    print("   Purchase Date: \(transaction.purchaseDate)")

                    // Update purchase status on main actor
                    await self.updatePurchaseStatus()

                    // Finish the transaction
                    await transaction.finish()

                    print("   ✅ Transaction processed and finished")

                } catch {
                    print("❌ [NativeStore] Transaction verification failed:")
                    print("   Error: \(error.localizedDescription)")
                    print("   Error type: \(type(of: error))")
                }
            }
        }
    }

    // MARK: - Verify Transaction
    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            print("❌ [NativeStore] Transaction verification failed: \(error)")
            throw error
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Backend Sync
    private func syncSubscriptionWithBackend(productID: String, expirationDate: Date?) async throws {
        guard let userId = AuthService.shared.user?.uid else {
            throw NSError(domain: "NativeStore", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }

        let environment = getEnvironment()

        // Try receipt validation first (for App Review and production)
        // If it fails (sandbox/simulator), fallback to direct sync
        let useReceiptValidation = environment.contains("Production") || environment.contains("TestFlight")

        if useReceiptValidation {
            print("📱 [NativeStore] Using receipt validation (Production/TestFlight)")

            // Find the active transaction for receipt validation
            for await result in Transaction.currentEntitlements {
                do {
                    let transaction = try checkVerified(result)
                    if transaction.productID == productID {
                        // Try receipt validation (App Review compatible)
                        do {
                            _ = try await ReceiptValidationService.shared.verifyReceipt(
                                transaction: transaction,
                                userId: userId
                            )
                            print("✅ [NativeStore] Receipt validation successful")
                            return // Success, no need for fallback
                        } catch {
                            print("⚠️ [NativeStore] Receipt validation failed: \(error.localizedDescription)")
                            print("   Falling back to direct sync...")
                            // Continue to fallback below
                        }
                        break
                    }
                } catch {
                    print("⚠️ [NativeStore] Transaction verification failed")
                }
            }
        } else {
            print("🧪 [NativeStore] Using direct sync (Sandbox/Simulator)")
        }

        // Fallback: Direct sync (for Sandbox/Simulator or if receipt validation fails)
        print("🔄 [NativeStore] Syncing via direct API call...")

        // Determine tier from product ID
        let tier: String
        if productID.contains("yearly") {
            tier = "yearly"
        } else if productID.contains("monthly") {
            tier = "monthly"
        } else if productID.contains("lifetime") {
            tier = "lifetime"
        } else {
            tier = "premium"
        }

        // Create timestamp in required format (ISO8601)
        let timestampFormatter = ISO8601DateFormatter()
        timestampFormatter.formatOptions = [.withInternetDateTime]
        let timestamp = timestampFormatter.string(from: Date())

        // Prepare subscription data
        var subscriptionData: [String: Any] = [
            "user_id": userId,
            "timestamp": timestamp,
            "subscription_status": [
                "is_premium": true,
                "tier": tier,
                "product_id": productID,
                "platform": "ios",
                "is_active": true,
                "will_renew": expirationDate != nil // lifetime doesn't renew
            ]
        ]

        // Add expiration date if available
        if let expirationDate = expirationDate {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            subscriptionData["subscription_status"] = (subscriptionData["subscription_status"] as! [String: Any]).merging([
                "expiration_date": formatter.string(from: expirationDate)
            ]) { _, new in new }
        }

        // Send to backend
        _ = try await BraindumpsterAPI.shared.syncSubscriptionStatus(data: subscriptionData)
        print("✅ [NativeStore] Direct sync successful")
    }

    // MARK: - Helper Methods
    func product(for productID: String) -> Product? {
        return products.first { $0.id == productID }
    }

    var monthlyProduct: Product? {
        products.first { $0.id.contains("monthly") }
    }

    var yearlyProduct: Product? {
        products.first { $0.id.contains("yearly") }
    }

    var lifetimeProduct: Product? {
        products.first { $0.id.contains("lifetime") }
    }

    // MARK: - Environment Detection
    private func getEnvironment() -> String {
        #if DEBUG
        return "Xcode/Simulator (Sandbox)"
        #else
        // Check if TestFlight
        if Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" {
            return "TestFlight (Sandbox)"
        }
        return "Production (App Store)"
        #endif
    }

    // MARK: - Expiration Monitoring
    private func startExpirationMonitoring() async {
        print("⏰ [NativeStore] Starting expiration monitoring...")

        // Check expiration immediately
        await checkExpiration()

        // Schedule periodic checks (every 24 hours)
        await MainActor.run {
            expirationCheckTimer?.invalidate()
            expirationCheckTimer = Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { [weak self] _ in
                _Concurrency.Task {
                    await self?.checkExpiration()
                }
            }
        }
    }

    private func checkExpiration() async {
        guard let expirationDate = premiumExpirationDate else {
            // Lifetime subscription or no subscription
            await MainActor.run {
                daysUntilExpiration = nil
            }
            return
        }

        let now = Date()
        let timeInterval = expirationDate.timeIntervalSince(now)

        if timeInterval <= 0 {
            // Subscription expired
            print("⏰ [NativeStore] Subscription expired!")
            print("   Expiration date: \(expirationDate)")
            print("   Current date: \(now)")

            // Update purchase status to reflect expiration
            await updatePurchaseStatus()

            await MainActor.run {
                daysUntilExpiration = 0
            }
        } else {
            // Calculate days until expiration
            let days = Int(ceil(timeInterval / 86400))

            await MainActor.run {
                daysUntilExpiration = days
            }

            print("⏰ [NativeStore] Subscription status:")
            print("   Expires in: \(days) days")
            print("   Expiration date: \(expirationDate)")

            // Warn user if expiring soon (7 days or less)
            if days <= 7 {
                print("⚠️ [NativeStore] Subscription expiring soon!")
            }
        }
    }

    // MARK: - Check Billing Retry Status
    func checkBillingRetryStatus() async {
        print("💳 [NativeStore] Checking billing retry status...")

        var inRetry = false

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // Check if subscription is in billing retry
                if let subscription = transaction.subscription {
                    // Note: isInBillingRetryPeriod is available in iOS 15+
                    if #available(iOS 15.0, *) {
                        if subscription.isInBillingRetryPeriod {
                            inRetry = true
                            print("⚠️ [NativeStore] Subscription in billing retry")
                            print("   Product: \(transaction.productID)")
                            break
                        }
                    }
                }
            } catch {
                print("❌ [NativeStore] Failed to check billing retry: \(error.localizedDescription)")
            }
        }

        await MainActor.run {
            isInBillingRetry = inRetry
        }

        if inRetry {
            print("💳 [NativeStore] Billing retry active - user should update payment method")
        } else {
            print("✅ [NativeStore] No billing issues")
        }
    }
}
