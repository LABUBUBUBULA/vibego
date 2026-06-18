import Foundation
import StoreKit

@MainActor
final class CoinPurchaseManager {
    static let shared = CoinPurchaseManager()

    struct Package: Equatable {
        let coins: Int
        let fallbackPrice: String
        let productId: String
    }

    let packages: [Package] = [
        Package(coins: 100, fallbackPrice: "$0.99", productId: "com.vibego.coins100"),
        Package(coins: 500, fallbackPrice: "$4.99", productId: "com.vibego.coins500"),
        Package(coins: 1000, fallbackPrice: "$9.99", productId: "com.vibego.coins1000"),
        Package(coins: 5000, fallbackPrice: "$49.99", productId: "com.vibego.coins5000"),
        Package(coins: 10000, fallbackPrice: "$99.99", productId: "com.vibego.coins10000"),
    ]

    private var updatesTask: Task<Void, Never>?

    private init() {}

    func start() {
        if updatesTask == nil {
            updatesTask = Task { [weak self] in
                for await result in Transaction.updates {
                    do {
                        _ = try await self?.handleTransactionResult(result)
                    } catch {
                        print("💰 [CoinPurchase] update handling failed: \(error.localizedDescription)")
                    }
                }
            }
        }

        processUnfinishedTransactions()
    }

    private func processUnfinishedTransactions() {
        Task { [weak self] in
            for await result in Transaction.unfinished {
                do {
                    _ = try await self?.handleTransactionResult(result)
                } catch {
                    print("💰 [CoinPurchase] unfinished handling failed: \(error.localizedDescription)")
                }
            }
        }
    }

    func purchase(_ package: Package) async throws -> Int {
        let products = try await Product.products(for: [package.productId])
        guard let product = products.first else {
            throw PurchaseError.productNotFound
        }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            return try await handleTransactionResult(verification)
        case .pending:
            throw PurchaseError.pending
        case .userCancelled:
            throw PurchaseError.cancelled
        @unknown default:
            throw PurchaseError.unknown
        }
    }

    private func handleTransactionResult(
        _ result: VerificationResult<Transaction>
    ) async throws -> Int {
        switch result {
        case .verified(let transaction):
            guard let package = package(for: transaction.productID) else {
                throw PurchaseError.unknownProduct(transaction.productID)
            }
            guard UserManager.shared.isLoggedIn else {
                throw PurchaseError.noActiveUser
            }

            if !isTransactionDelivered(transaction.id) {
                MockDataManager.shared.addCoins(package.coins)
                markTransactionDelivered(transaction.id)
            }
            await transaction.finish()
            return package.coins

        case .unverified(_, let error):
            throw error
        }
    }

    private func package(for productId: String) -> Package? {
        packages.first { $0.productId == productId }
    }

    private func isTransactionDelivered(_ transactionId: UInt64) -> Bool {
        let key = "CoinPurchaseManager.deliveredTransactionIds"
        let ids = Set(UserDefaults.standard.array(forKey: key) as? [String] ?? [])
        return ids.contains(String(transactionId))
    }

    private func markTransactionDelivered(_ transactionId: UInt64) {
        let key = "CoinPurchaseManager.deliveredTransactionIds"
        var ids = Set(UserDefaults.standard.array(forKey: key) as? [String] ?? [])
        let id = String(transactionId)
        ids.insert(id)
        UserDefaults.standard.set(Array(ids), forKey: key)
    }
}

enum PurchaseError: LocalizedError {
    case productNotFound
    case pending
    case cancelled
    case unknown
    case unknownProduct(String)
    case noActiveUser

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Product not found"
        case .pending:
            return "Purchase pending approval"
        case .cancelled:
            return nil
        case .unknown:
            return "Unknown purchase error"
        case .unknownProduct(let productId):
            return "Unknown product: \(productId)"
        case .noActiveUser:
            return "No active user"
        }
    }
}
