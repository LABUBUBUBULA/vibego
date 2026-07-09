import StoreKit
import UIKit

/// iOS 内购管理器 (StoreKit 1)
/// H5 发起内购
/// 流程: 发起内购 -> 显示 Loading -> 支付成功 -> 调验单接口
final class PurchaseManager: NSObject {

    static let shared = PurchaseManager()
    private override init() {
        super.init()
    }

    private var currentCallbackResult: String = ""
    private var currentBatchNo: String = ""
    private weak var presentingVC: WebContainerViewController?
    private var loadingView: UIView?
    private var isPurchasing = false
    private var activePurchaseID: UUID?
    private var currentPaymentDiagnostic: String = ""

    private var isPaymentQueueObserverAdded = false
    private var productRequest: SKProductsRequest?
    private var productRequestCompletion: ((Result<SKProduct, Error>) -> Void)?
    private var receiptRefreshContinuation: CheckedContinuation<Void, Error>?
    private var receiptRefreshRequest: SKReceiptRefreshRequest?
    private var receiptRefreshTask: Task<Void, Error>?

    private let missingTransactionRetryDelays: [UInt64] = [2, 5, 10, 15]
    private let pendingVerificationRetryDelays: [UInt64] = [30, 60, 120, 300, 600]
    private var pendingRetryTasks: [String: Task<Void, Never>] = [:]
    private let pendingCallbacksKey = "PurchaseManager.pendingCallbacksByTx"
    private let pendingProductCallbacksKey = "PurchaseManager.pendingCallbacksByProduct"
    private let lastUnfinishedTxKey = "PurchaseManager.lastUnfinishedTx"
    private let lastUnfinishedPidKey = "PurchaseManager.lastUnfinishedPid"
    private let lastUnfinishedAtKey = "PurchaseManager.lastUnfinishedAt"
    private let lastUnfinishedReasonKey = "PurchaseManager.lastUnfinishedReason"

    // MARK: - StoreKit 1 lifecycle

    func start() {
        guard !isPaymentQueueObserverAdded else { return }
        SKPaymentQueue.default().add(self)
        isPaymentQueueObserverAdded = true
        retryUnfinishedTransactions(reason: "start")
    }

    func retryUnfinishedTransactions(reason: String) {
        let transactions = SKPaymentQueue.default().transactions
        guard !transactions.isEmpty else { return }

        print("💰 [Purchase] retry StoreKit1 transactions: count=\(transactions.count), reason=\(reason)")
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                handlePurchasedTransaction(transaction, reason: reason)
            case .failed:
                handleFailedTransaction(transaction)
            case .purchasing, .deferred:
                continue
            @unknown default:
                continue
            }
        }
    }

    // MARK: - 发起购买

    func purchase(batchNo: String, callbackResult: String, from vc: WebContainerViewController) {
        guard !isPurchasing else {
            print("💰 [Purchase] 正在购买中，忽略重复请求")
            return
        }

        let normalizedBatchNo = batchNo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedBatchNo.isEmpty else {
            print("💰 [Purchase] missing product id")
            return
        }

        let normalizedCallbackResult = callbackResult.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedCallbackResult.isEmpty else {
            print("💰 [Purchase] missing callback result")
            return
        }

        presentingVC = vc

        guard SKPaymentQueue.canMakePayments() else {
            finishPurchase(success: false, message: "In-app purchases are not available")
            return
        }

        start()
        isPurchasing = true
        let purchaseID = UUID()
        activePurchaseID = purchaseID
        currentCallbackResult = normalizedCallbackResult
        currentBatchNo = normalizedBatchNo
        rememberPendingProductCallback(productID: normalizedBatchNo, callbackResult: normalizedCallbackResult)

        currentPaymentDiagnostic = """
        stage=start
        storeKit=1
        purchaseID=\(purchaseID.uuidString)
        pid=\(normalizedBatchNo)
        callbackBytes=\(normalizedCallbackResult.utf8.count)
        path=\(GatewayConfig.Path.verifyPay)
        \(lastUnfinishedTransactionDiagnostic())
        """

        print("💰 [Purchase] StoreKit1 开始购买")
        showLoading(on: vc)

        requestProduct(productID: normalizedBatchNo) { [weak self] result in
            guard let self, self.activePurchaseID == purchaseID else { return }

            switch result {
            case .success(let product):
                print("💰 [Purchase] StoreKit1 商品: \(product.productIdentifier) - \(self.localizedPrice(for: product))")
                let payment = SKPayment(product: product)
                SKPaymentQueue.default().add(payment)

            case .failure(let error):
                self.removePendingProductCallback(productID: normalizedBatchNo)
                self.finishPurchase(success: false, message: error.localizedDescription)
            }
        }
    }

    private func requestProduct(
        productID: String,
        completion: @escaping (Result<SKProduct, Error>) -> Void
    ) {
        productRequest?.cancel()
        productRequestCompletion = completion

        let request = SKProductsRequest(productIdentifiers: [productID])
        productRequest = request
        request.delegate = self
        print("💰 [Purchase] StoreKit1 查询商品: [\(productID)]")
        request.start()
    }

    private func completeProductRequest(_ result: Result<SKProduct, Error>) {
        let completion = productRequestCompletion
        productRequestCompletion = nil
        productRequest = nil
        completion?(result)
    }

    private func handlePurchasedTransaction(_ transaction: SKPaymentTransaction, reason: String) {
        let productID = transaction.payment.productIdentifier
        let purchaseID = isCurrentProduct(productID) ? activePurchaseID : nil

        guard let transactionId = transactionIdentifier(for: transaction) else {
            let diagnostic = """
            stage=storekit1_transaction
            storeKit=1
            reason=\(reason)
            tx=nil
            pid=\(productID)
            state=\(storeKitStateDescription(transaction.transactionState))
            message=missing transaction id
            \(lastUnfinishedTransactionDiagnostic())
            """
            currentPaymentDiagnostic = diagnostic
            if purchaseID != nil {
                finishPurchase(
                    success: false,
                    message: paymentMessage("missing transaction id", diagnostics: diagnostic)
                )
            }
            return
        }

        guard let callbackResult = callbackResult(for: transaction) else {
            let diagnostic = """
            stage=storekit1_transaction
            storeKit=1
            reason=\(reason)
            tx=\(transactionId)
            pid=\(productID)
            state=\(storeKitStateDescription(transaction.transactionState))
            message=missing purchase request
            \(lastUnfinishedTransactionDiagnostic())
            """
            currentPaymentDiagnostic = diagnostic
            rememberUnfinishedTransaction(transaction: transaction, code: nil, message: "missing purchase request")
            if purchaseID != nil {
                finishPurchase(
                    success: false,
                    message: paymentMessage("missing purchase request", diagnostics: diagnostic)
                )
            }
            return
        }

        rememberPendingCallback(transactionId: transactionId, callbackResult: callbackResult)
        startVerification(
            transaction: transaction,
            callbackResult: callbackResult,
            purchaseID: purchaseID,
            reason: reason,
            attempt: 0
        )
    }

    private func handleFailedTransaction(_ transaction: SKPaymentTransaction) {
        SKPaymentQueue.default().finishTransaction(transaction)

        let productID = transaction.payment.productIdentifier
        removePendingProductCallback(productID: productID)

        guard isCurrentProduct(productID) else { return }

        let error = transaction.error as? SKError
        if error?.code == .paymentCancelled {
            finishPurchase(success: false, message: ObfuscatedBridgeText.Field.f13)
            return
        }

        let message = transaction.error?.localizedDescription ?? "Purchase failed"
        currentPaymentDiagnostic = """
        stage=storekit1_failed
        storeKit=1
        pid=\(productID)
        error=\(message)
        \(lastUnfinishedTransactionDiagnostic())
        """
        finishPurchase(success: false, message: message)
    }

    private func isCurrentProduct(_ productID: String) -> Bool {
        activePurchaseID != nil && productID == currentBatchNo
    }

    private func callbackResult(for transaction: SKPaymentTransaction) -> String? {
        let productID = transaction.payment.productIdentifier

        if isCurrentProduct(productID), !currentCallbackResult.isEmpty {
            return currentCallbackResult
        }

        if let transactionId = transactionIdentifier(for: transaction),
           let callbackResult = pendingCallback(for: transactionId) {
            return callbackResult
        }

        return pendingProductCallback(for: productID)
    }

    private func transactionIdentifier(for transaction: SKPaymentTransaction) -> String? {
        if let id = transaction.transactionIdentifier, !id.isEmpty {
            return id
        }
        if let id = transaction.original?.transactionIdentifier, !id.isEmpty {
            return id
        }
        return nil
    }

    private func originalTransactionIdentifier(for transaction: SKPaymentTransaction) -> String {
        transaction.original?.transactionIdentifier ?? "nil"
    }

    private func storeKitStateDescription(_ state: SKPaymentTransactionState) -> String {
        switch state {
        case .purchasing: return "purchasing"
        case .purchased: return "purchased"
        case .failed: return "failed"
        case .restored: return "restored"
        case .deferred: return "deferred"
        @unknown default: return "unknown"
        }
    }

    private func localizedPrice(for product: SKProduct) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        return formatter.string(from: product.price) ?? product.price.stringValue
    }

    // MARK: - 验单接口

    private func startVerification(
        transaction: SKPaymentTransaction,
        callbackResult: String,
        purchaseID: UUID?,
        reason: String,
        attempt: Int
    ) {
        guard let transactionId = transactionIdentifier(for: transaction) else {
            if purchaseID != nil {
                finishPurchase(success: false, message: "missing transaction id")
            }
            return
        }

        if let purchaseID, activePurchaseID != purchaseID {
            return
        }

        currentPaymentDiagnostic = """
        stage=receipt
        storeKit=1
        reason=\(reason)
        purchaseID=\(purchaseID?.uuidString ?? "none")
        attempt=\(attempt + 1)
        tx=\(transactionId)
        originalTx=\(originalTransactionIdentifier(for: transaction))
        pid=\(transaction.payment.productIdentifier)
        transactionDate=\(iso8601String(from: transaction.transactionDate))
        callbackBytes=\(callbackResult.utf8.count)
        path=\(GatewayConfig.Path.verifyPay)
        \(lastUnfinishedTransactionDiagnostic())
        """

        Task { [weak self] in
            guard let self else { return }
            do {
                let receipt = try await self.loadAppStoreReceiptData(refreshBeforeRead: true)
                await MainActor.run {
                    self.sendVerificationRequest(
                        transaction: transaction,
                        receipt: receipt,
                        callbackResult: callbackResult,
                        purchaseID: purchaseID,
                        reason: reason,
                        attempt: attempt
                    )
                }
            } catch {
                await MainActor.run {
                    self.rememberPendingVerification(
                        transaction: transaction,
                        callbackResult: callbackResult,
                        code: nil,
                        message: error.localizedDescription
                    )
                    self.schedulePendingVerificationRetry(
                        transaction: transaction,
                        callbackResult: callbackResult,
                        attempt: 0
                    )

                    if purchaseID != nil {
                        let message = self.paymentMessage(
                            "Purchase is processing. Please wait.",
                            diagnostics: self.currentPaymentDiagnostic
                        )
                        self.finishPurchase(success: false, message: message, alertTitle: "Processing")
                    }
                }
            }
        }
    }

    private func sendVerificationRequest(
        transaction: SKPaymentTransaction,
        receipt: Data,
        callbackResult: String,
        purchaseID: UUID?,
        reason: String,
        attempt: Int
    ) {
        guard let transactionId = transactionIdentifier(for: transaction) else {
            if purchaseID != nil {
                finishPurchase(success: false, message: "missing transaction id")
            }
            return
        }

        if let purchaseID, activePurchaseID != purchaseID {
            return
        }

        let payload = receipt.base64EncodedString()
        let params: [String: Any] = [
            "trt": transactionId,
            "plp": payload,
            "cbc": callbackResult
        ]

        let diagnostic = """
        stage=\(purchaseID == nil ? "pending_verify" : "verify")
        storeKit=1
        reason=\(reason)
        purchaseID=\(purchaseID?.uuidString ?? "none")
        attempt=\(attempt + 1)
        tx=\(transactionId)
        originalTx=\(originalTransactionIdentifier(for: transaction))
        sameAsLastUnfinishedTx=\(transactionId == lastUnfinishedTransactionID() ? "true" : "false")
        pid=\(transaction.payment.productIdentifier)
        transactionDate=\(iso8601String(from: transaction.transactionDate))
        receiptBytes=\(receipt.count)
        callbackBytes=\(callbackResult.utf8.count)
        path=\(GatewayConfig.Path.verifyPay)
        decryptedRequestParams.trt=\(transactionId)
        decryptedRequestParams.plpBytes=\(receipt.count)
        decryptedRequestParams.plpBase64Bytes=\(payload.utf8.count)
        decryptedRequestParams.plpPrefix=\(payload.prefix(80))
        decryptedRequestParams.plpSuffix=\(payload.suffix(48))
        decryptedRequestParams.cbc=\(callbackResult)
        \(lastUnfinishedTransactionDiagnostic())
        """
        currentPaymentDiagnostic = diagnostic

        print("💰 [Purchase] StoreKit1 验单请求: transactionId=\(transactionId), productId=\(transaction.payment.productIdentifier), receiptBytes=\(receipt.count)")
        GatewayAPI.shared.request(path: GatewayConfig.Path.verifyPay, params: params) { [weak self] code, _, message in
            guard let self else { return }
            if let purchaseID, self.activePurchaseID != purchaseID {
                return
            }

            print("💰 [Purchase] StoreKit1 验单结果: code=\(code ?? "nil"), message=\(message ?? "nil")")

            if code == "0" || code == "0000" {
                SKPaymentQueue.default().finishTransaction(transaction)
                self.clearUnfinishedTransactionIfNeeded(transactionId: transactionId)
                self.removePendingCallback(transactionId: transactionId)
                self.removePendingProductCallback(productID: transaction.payment.productIdentifier)
                self.cancelPendingRetry(transactionId: transactionId)

                if purchaseID != nil {
                    print("💰 [Purchase] StoreKit1 购买成功")
                    self.finishPurchase(success: true, message: "Purchase successful!")
                } else {
                    print("💰 [Purchase] StoreKit1 补验成功")
                    self.notifyH5PurchaseResult(success: true, message: "Purchase successful!")
                }
                return
            }

            if self.shouldRetryMissingTransaction(code: code, message: message),
               purchaseID != nil,
               attempt < self.missingTransactionRetryDelays.count {
                self.retryPurchaseVerification(
                    transaction: transaction,
                    callbackResult: callbackResult,
                    purchaseID: purchaseID,
                    reason: reason,
                    nextAttempt: attempt + 1
                )
                return
            }

            let detail = """
            \(diagnostic)
            backendResponse=received
            code=\(code ?? "nil")
            message=\(message ?? "nil")
            """

            if self.shouldKeepTransactionPending(code: code, message: message) {
                self.rememberPendingVerification(
                    transaction: transaction,
                    callbackResult: callbackResult,
                    code: code,
                    message: message
                )
                self.schedulePendingVerificationRetry(
                    transaction: transaction,
                    callbackResult: callbackResult,
                    attempt: purchaseID == nil ? attempt + 1 : 0
                )

                if purchaseID != nil {
                    let displayMessage = self.paymentMessage(
                        "Purchase is processing. Please wait.",
                        diagnostics: detail
                    )
                    self.finishPurchase(success: false, message: displayMessage, alertTitle: "Processing")
                }
                return
            }

            self.rememberUnfinishedTransaction(transaction: transaction, code: code, message: message)
            let displayMessage = self.paymentMessage(
                message ?? "Verification failed",
                diagnostics: detail
            )
            if purchaseID != nil {
                self.finishPurchase(success: false, message: displayMessage)
            } else {
                self.notifyH5PurchaseResult(success: false, message: message ?? "Verification failed")
            }
        }
    }

    private func shouldRetryMissingTransaction(code: String?, message: String?) -> Bool {
        let normalizedMessage = (message ?? "").lowercased()
        return code == "1033" || normalizedMessage.contains("not in the transaction list")
    }

    private func shouldKeepTransactionPending(code: String?, message: String?) -> Bool {
        code == nil || shouldRetryMissingTransaction(code: code, message: message)
    }

    private func retryPurchaseVerification(
        transaction: SKPaymentTransaction,
        callbackResult: String,
        purchaseID: UUID?,
        reason: String,
        nextAttempt: Int
    ) {
        let delay = missingTransactionRetryDelays[nextAttempt - 1]
        currentPaymentDiagnostic += """

        retryAfterSeconds=\(delay)
        retryAttempt=\(nextAttempt + 1)
        """

        Task { [weak self] in
            try? await Task.sleep(nanoseconds: delay * 1_000_000_000)
            await MainActor.run {
                guard let self else { return }
                if let purchaseID, self.activePurchaseID != purchaseID {
                    return
                }
                self.startVerification(
                    transaction: transaction,
                    callbackResult: callbackResult,
                    purchaseID: purchaseID,
                    reason: reason,
                    attempt: nextAttempt
                )
            }
        }
    }

    private func verifyPendingTransaction(
        transaction: SKPaymentTransaction,
        callbackResult: String,
        reason: String,
        attempt: Int
    ) {
        guard let transactionId = transactionIdentifier(for: transaction) else {
            rememberUnfinishedTransaction(transaction: transaction, code: nil, message: "missing transaction id")
            return
        }

        pendingRetryTasks[transactionId] = nil
        guard !isPurchasing else {
            schedulePendingVerificationRetry(
                transaction: transaction,
                callbackResult: callbackResult,
                attempt: attempt
            )
            return
        }

        startVerification(
            transaction: transaction,
            callbackResult: callbackResult,
            purchaseID: nil,
            reason: reason,
            attempt: attempt
        )
    }

    private func schedulePendingVerificationRetry(
        transaction: SKPaymentTransaction,
        callbackResult: String,
        attempt: Int
    ) {
        guard let transactionId = transactionIdentifier(for: transaction) else { return }
        guard pendingRetryTasks[transactionId] == nil else { return }

        let delay = pendingVerificationRetryDelay(for: attempt)
        print("💰 [Purchase] StoreKit1 安排补验: transactionId=\(transactionId), delay=\(delay), attempt=\(attempt + 1)")
        pendingRetryTasks[transactionId] = Task { [weak self] in
            try? await Task.sleep(nanoseconds: delay * 1_000_000_000)
            await MainActor.run {
                self?.verifyPendingTransaction(
                    transaction: transaction,
                    callbackResult: callbackResult,
                    reason: "scheduled_retry",
                    attempt: attempt
                )
            }
        }
    }

    private func pendingVerificationRetryDelay(for attempt: Int) -> UInt64 {
        let index = min(attempt, pendingVerificationRetryDelays.count - 1)
        return pendingVerificationRetryDelays[index]
    }

    private func cancelPendingRetry(transactionId: String) {
        pendingRetryTasks[transactionId]?.cancel()
        pendingRetryTasks[transactionId] = nil
    }

    private func loadAppStoreReceiptData(refreshBeforeRead: Bool = false) async throws -> Data {
        if !refreshBeforeRead, let data = currentAppStoreReceiptData() {
            return data
        }

        let receiptPath = Bundle.main.appStoreReceiptURL?.path ?? "nil"
        currentPaymentDiagnostic += """

        receiptStage=\(refreshBeforeRead ? "refresh_before_verify" : "missing_before_refresh")
        receiptPath=\(receiptPath)
        """

        do {
            try await refreshAppStoreReceipt()
        } catch {
            currentPaymentDiagnostic += """

            receiptRefreshError=\(error.localizedDescription)
            """
            throw error
        }

        if let data = currentAppStoreReceiptData() {
            return data
        }

        currentPaymentDiagnostic += """

        receiptStage=missing_after_refresh
        receiptPath=\(receiptPath)
        """

        throw ReceiptError.missingReceipt
    }

    private func currentAppStoreReceiptData() -> Data? {
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              let data = try? Data(contentsOf: receiptURL),
              !data.isEmpty else {
            return nil
        }
        return data
    }

    private func refreshAppStoreReceipt() async throws {
        if let receiptRefreshTask {
            try await receiptRefreshTask.value
            return
        }

        let task = Task<Void, Error> {
            try await withCheckedThrowingContinuation { continuation in
                receiptRefreshContinuation = continuation
                let request = SKReceiptRefreshRequest(receiptProperties: nil)
                receiptRefreshRequest = request
                request.delegate = self
                request.start()
            }
        }
        receiptRefreshTask = task
        defer { receiptRefreshTask = nil }
        try await task.value
    }

    private func completeReceiptRefresh(_ result: Result<Void, Error>) {
        guard let continuation = receiptRefreshContinuation else { return }
        receiptRefreshContinuation = nil
        receiptRefreshRequest = nil

        switch result {
        case .success:
            continuation.resume()
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }

    private func lastUnfinishedTransactionID() -> String? {
        UserDefaults.standard.string(forKey: lastUnfinishedTxKey)
    }

    private func pendingCallbackMap() -> [String: String] {
        UserDefaults.standard.dictionary(forKey: pendingCallbacksKey) as? [String: String] ?? [:]
    }

    private func pendingCallback(for transactionId: String) -> String? {
        guard let callbackResult = pendingCallbackMap()[transactionId],
              !callbackResult.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return callbackResult
    }

    private func rememberPendingCallback(transactionId: String, callbackResult: String) {
        let normalizedCallbackResult = callbackResult.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !transactionId.isEmpty, !normalizedCallbackResult.isEmpty else { return }

        var map = pendingCallbackMap()
        map[transactionId] = normalizedCallbackResult
        UserDefaults.standard.set(map, forKey: pendingCallbacksKey)
    }

    private func removePendingCallback(transactionId: String) {
        var map = pendingCallbackMap()
        map.removeValue(forKey: transactionId)
        UserDefaults.standard.set(map, forKey: pendingCallbacksKey)
    }

    private func pendingProductCallbackMap() -> [String: String] {
        UserDefaults.standard.dictionary(forKey: pendingProductCallbacksKey) as? [String: String] ?? [:]
    }

    private func pendingProductCallback(for productID: String) -> String? {
        guard let callbackResult = pendingProductCallbackMap()[productID],
              !callbackResult.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return callbackResult
    }

    private func rememberPendingProductCallback(productID: String, callbackResult: String) {
        let normalizedCallbackResult = callbackResult.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !productID.isEmpty, !normalizedCallbackResult.isEmpty else { return }

        var map = pendingProductCallbackMap()
        map[productID] = normalizedCallbackResult
        UserDefaults.standard.set(map, forKey: pendingProductCallbacksKey)
    }

    private func removePendingProductCallback(productID: String) {
        var map = pendingProductCallbackMap()
        map.removeValue(forKey: productID)
        UserDefaults.standard.set(map, forKey: pendingProductCallbacksKey)
    }

    private func lastUnfinishedTransactionDiagnostic() -> String {
        guard let tx = UserDefaults.standard.string(forKey: lastUnfinishedTxKey), !tx.isEmpty else {
            return """
            lastUnfinishedTx=none
            pendingCallbackCount=\(pendingCallbackMap().count)
            pendingProductCallbackCount=\(pendingProductCallbackMap().count)
            """
        }

        let pid = UserDefaults.standard.string(forKey: lastUnfinishedPidKey) ?? "nil"
        let at = UserDefaults.standard.string(forKey: lastUnfinishedAtKey) ?? "nil"
        let reason = UserDefaults.standard.string(forKey: lastUnfinishedReasonKey) ?? "nil"
        return """
        lastUnfinishedTx=\(tx)
        lastUnfinishedPid=\(pid)
        lastUnfinishedAt=\(at)
        lastUnfinishedReason=\(reason)
        pendingCallbackCount=\(pendingCallbackMap().count)
        pendingProductCallbackCount=\(pendingProductCallbackMap().count)
        """
    }

    private func rememberPendingVerification(
        transaction: SKPaymentTransaction,
        callbackResult: String,
        code: String?,
        message: String?
    ) {
        if let transactionId = transactionIdentifier(for: transaction) {
            rememberPendingCallback(transactionId: transactionId, callbackResult: callbackResult)
        }
        rememberPendingProductCallback(
            productID: transaction.payment.productIdentifier,
            callbackResult: callbackResult
        )
        rememberUnfinishedTransaction(transaction: transaction, code: code, message: message)
    }

    private func rememberUnfinishedTransaction(transaction: SKPaymentTransaction, code: String?, message: String?) {
        let tx = transactionIdentifier(for: transaction) ?? "nil"
        UserDefaults.standard.set(tx, forKey: lastUnfinishedTxKey)
        UserDefaults.standard.set(transaction.payment.productIdentifier, forKey: lastUnfinishedPidKey)
        UserDefaults.standard.set(iso8601String(from: Date()), forKey: lastUnfinishedAtKey)
        UserDefaults.standard.set("\(code ?? "nil"):\(message ?? "nil")", forKey: lastUnfinishedReasonKey)
    }

    private func clearUnfinishedTransactionIfNeeded(transactionId: String) {
        guard UserDefaults.standard.string(forKey: lastUnfinishedTxKey) == transactionId else { return }
        UserDefaults.standard.removeObject(forKey: lastUnfinishedTxKey)
        UserDefaults.standard.removeObject(forKey: lastUnfinishedPidKey)
        UserDefaults.standard.removeObject(forKey: lastUnfinishedAtKey)
        UserDefaults.standard.removeObject(forKey: lastUnfinishedReasonKey)
    }

    private func iso8601String(from date: Date?) -> String {
        guard let date else { return "nil" }
        return ISO8601DateFormatter().string(from: date)
    }

    private enum ReceiptError: LocalizedError {
        case missingReceipt

        var errorDescription: String? {
            return "Receipt not found"
        }
    }

    private enum ProductLookupError: LocalizedError {
        case productNotFound(String, [String])
        case paymentsUnavailable

        var errorDescription: String? {
            switch self {
            case .productNotFound(let productID, let invalidIDs):
                if invalidIDs.isEmpty {
                    return "Product not found: \(productID)"
                }
                return "Product not found: \(productID), invalid=\(invalidIDs.joined(separator: ","))"
            case .paymentsUnavailable:
                return "In-app purchases are not available"
            }
        }
    }

    private var isPaymentDiagnosticsEnabled: Bool {
        if let enabled = Bundle.main.object(forInfoDictionaryKey: "PaymentDebugEnabled") as? Bool {
            return enabled
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "PaymentDebugEnabled") as? String {
            return ["1", "true", "yes"].contains(value.lowercased())
        }
        return false
    }

    private func paymentMessage(_ message: String, diagnostics: String) -> String {
        guard isPaymentDiagnosticsEnabled else { return message }
        return """
        \(message)

        Diagnostics
        \(diagnostics)
        """
    }

    // MARK: - 统一结束购买

    /// 购买结束（成功/失败）：隐藏loading + 通知H5 + 重置状态
    private func finishPurchase(success: Bool, message: String, alertTitle: String? = nil) {
        print("💰 [Purchase] 结束: success=\(success), message=\(message)")
        hideLoading()
        isPurchasing = false
        activePurchaseID = nil
        productRequest?.cancel()
        productRequest = nil
        productRequestCompletion = nil

        if !success {
            showPaymentDiagnosticsIfNeeded(message)
        }

        notifyH5PurchaseResult(success: success, message: message)

        // 取消的不弹原生 alert，让 H5 处理
        if message == ObfuscatedBridgeText.Field.f13 { return }

        // 非取消的失败/成功才弹原生 alert
        guard let vc = presentingVC else { return }
        let alert = UIAlertController(
            title: alertTitle ?? (success ? "Success" : "Failed"),
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        // 确保能弹出：先关闭已有弹窗
        if let presented = vc.presentedViewController {
            presented.dismiss(animated: false) {
                vc.present(alert, animated: true)
            }
        } else {
            vc.present(alert, animated: true)
        }
    }

    private func notifyH5PurchaseResult(success: Bool, message: String) {
        let state = success ? ObfuscatedBridgeText.Field.f11 : ObfuscatedBridgeText.Field.f12
        let safeMessage = jsEscapedString(message)
        let event = ObfuscatedBridgeText.Event.e2
        let stateKey = ObfuscatedBridgeText.Field.f5
        let messageKey = ObfuscatedBridgeText.Field.f6
        let js = """
        window.dispatchEvent(new CustomEvent('\(event)', {
            detail: { '\(stateKey)': '\(state)', '\(messageKey)': '\(safeMessage)' }
        }));
        """
        presentingVC?.webView.evaluateJavaScript(js, completionHandler: nil)
    }

    private func jsEscapedString(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
    }

    private func showPaymentDiagnosticsIfNeeded(_ message: String) {
        guard isPaymentDiagnosticsEnabled else { return }
        let diagnostic: String
        if message.contains("\nDiagnostics\n") {
            diagnostic = message
        } else {
            diagnostic = """
            \(message)

            Diagnostics
            \(currentPaymentDiagnostic)
            """
        }
        UIPasteboard.general.string = diagnostic
        showDebugOverlay(text: diagnostic)
    }

    private func showDebugOverlay(text: String) {
        guard let view = presentingVC?.view else { return }

        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.88)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.accessibilityIdentifier = "PaymentDebugOverlay"

        let title = UILabel()
        title.text = "Payment diagnostics copied"
        title.font = Theme.Fonts.bold(16)
        title.textColor = .white
        title.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = text
        label.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        label.textColor = .white
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        let button = UIButton(type: .system)
        button.setTitle("Close", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = Theme.Fonts.bold(15)
        button.backgroundColor = Theme.Colors.primaryYellow.withAlphaComponent(0.25)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addAction(UIAction { _ in overlay.removeFromSuperview() }, for: .touchUpInside)

        overlay.addSubview(title)
        overlay.addSubview(label)
        overlay.addSubview(button)
        view.addSubview(overlay)

        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            title.topAnchor.constraint(equalTo: overlay.safeAreaLayoutGuide.topAnchor, constant: 28),
            title.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 20),
            title.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -20),

            label.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 16),
            label.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -20),

            button.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 20),
            button.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -20),
            button.bottomAnchor.constraint(equalTo: overlay.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            button.heightAnchor.constraint(equalToConstant: 48),
            label.bottomAnchor.constraint(lessThanOrEqualTo: button.topAnchor, constant: -20)
        ])
    }

    // MARK: - Loading UI

    private func showLoading(on vc: UIViewController) {
        // 先清理旧的 loading
        hideLoading()

        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlay.translatesAutoresizingMaskIntoConstraints = false

        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .white
        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "Processing payment..."
        label.font = Theme.Fonts.medium(14)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false

        overlay.addSubview(spinner)
        overlay.addSubview(label)
        vc.view.addSubview(overlay)

        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: vc.view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor),
            spinner.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
            label.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            label.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 12),
        ])

        loadingView = overlay
    }

    private func hideLoading() {
        loadingView?.removeFromSuperview()
        loadingView = nil
    }
}

extension PurchaseManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        guard let productRequest, request === productRequest else { return }

        if let product = response.products.first {
            completeProductRequest(.success(product))
        } else {
            completeProductRequest(.failure(
                ProductLookupError.productNotFound(
                    currentBatchNo,
                    response.invalidProductIdentifiers
                )
            ))
        }
    }

    func requestDidFinish(_ request: SKRequest) {
        if let receiptRefreshRequest, request === receiptRefreshRequest {
            completeReceiptRefresh(.success(()))
        }
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        if let receiptRefreshRequest, request === receiptRefreshRequest {
            completeReceiptRefresh(.failure(error))
        } else if let productRequest, request === productRequest {
            completeProductRequest(.failure(error))
        }
    }
}

extension PurchaseManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                handlePurchasedTransaction(transaction, reason: "updated_transactions")
            case .failed:
                handleFailedTransaction(transaction)
            case .purchasing:
                print("💰 [Purchase] StoreKit1 purchasing: \(transaction.payment.productIdentifier)")
            case .deferred:
                if isCurrentProduct(transaction.payment.productIdentifier) {
                    finishPurchase(success: false, message: "Purchase pending approval")
                }
            @unknown default:
                print("💰 [Purchase] StoreKit1 unknown transaction state")
            }
        }
    }

    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        print("💰 [Purchase] restore failed: \(error.localizedDescription)")
    }

    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        print("💰 [Purchase] restore finished")
    }
}
