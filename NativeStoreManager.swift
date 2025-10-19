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

    private var updateListenerTask: _Concurrency.Task<Void, Never>?

    private init() {
        // Start listening for transactions
        updateListenerTask = listenForTransactions()

        // Load products and check purchase status
        _Concurrency.Task {
            await loadProducts()
            await updatePurchaseStatus()
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
}
