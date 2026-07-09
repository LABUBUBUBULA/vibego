import StoreKit
import UIKit

/// iOS 内购管理器 (StoreKit 2)
/// H5 发起内购
/// 流程: 发起内购 → 显示 Loading → 支付成功 → 调验单接口
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
    private var receiptRefreshContinuation: CheckedContinuation<Void, Error>?
    private var receiptRefreshRequest: SKReceiptRefreshRequest?
    private var receiptRefreshTask: Task<Void, Error>?
    private let missingTransactionRetryDelays: [UInt64] = [2, 5, 10, 15]
    private let pendingVerificationRetryDelays: [UInt64] = [30, 60, 120, 300, 600]
    private var updatesTask: Task<Void, Never>?
    private var unfinishedTask: Task<Void, Never>?
    private var pendingRetryTasks: [String: Task<Void, Never>] = [:]
    private let pendingCallbacksKey = "PurchaseManager.pendingCallbacksByTx"
    private let lastUnfinishedTxKey = "PurchaseManager.lastUnfinishedTx"
    private let lastUnfinishedPidKey = "PurchaseManager.lastUnfinishedPid"
    private let lastUnfinishedAtKey = "PurchaseManager.lastUnfinishedAt"
    private let lastUnfinishedReasonKey = "PurchaseManager.lastUnfinishedReason"

    // MARK: - 未完成交易补验

    func start() {
        if updatesTask == nil {
            updatesTask = Task { [weak self] in
                for await result in Transaction.updates {
                    await self?.handlePendingTransactionResult(result, reason: "updates")
                }
            }
        }

        retryUnfinishedTransactions(reason: "start")
    }

    func retryUnfinishedTransactions(reason: String) {
        guard unfinishedTask == nil else { return }

        unfinishedTask = Task { [weak self] in
            defer {
                self?.unfinishedTask = nil
            }
            for await result in Transaction.unfinished {
                await self?.handlePendingTransactionResult(result, reason: reason)
            }
        }
    }

    private func handlePendingTransactionResult(
        _ result: VerificationResult<Transaction>,
        reason: String
    ) async {
        switch result {
        case .verified(let transaction):
            let transactionId = String(transaction.id)
            guard let callbackResult = pendingCallback(for: transactionId) else {
                return
            }
            guard !isPurchasing else {
                schedulePendingVerificationRetry(
                    transaction: transaction,
                    callbackResult: callbackResult,
                    attempt: 0
                )
                return
            }
            await verifyPendingTransaction(
                transaction: transaction,
                callbackResult: callbackResult,
                reason: reason,
                attempt: 0
            )

        case .unverified(_, let error):
            print("💰 [Purchase] unfinished transaction unverified: \(error.localizedDescription)")
        }
    }

    // MARK: - 发起购买

    func purchase(batchNo: String, callbackResult: String, from vc: WebContainerViewController) {
        // 防重复购买
        guard !isPurchasing else {
            print("�� [Purchase] ⚠️ 正在购买中，忽略重复请求")
            return
        }

        let normalizedBatchNo = batchNo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedBatchNo.isEmpty else {
            print("💰 [Purchase] ❌ missing product id")
            return
        }

        let normalizedCallbackResult = callbackResult.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedCallbackResult.isEmpty else {
            print("💰 [Purchase] ❌ missing callback result")
            return
        }

        isPurchasing = true
        let purchaseID = UUID()
        activePurchaseID = purchaseID
        currentPaymentDiagnostic = """
        stage=start
        purchaseID=\(purchaseID.uuidString)
        pid=\(normalizedBatchNo)
        callbackBytes=\(normalizedCallbackResult.utf8.count)
        path=\(GatewayConfig.Path.verifyPay)
        \(lastUnfinishedTransactionDiagnostic())
        """

        print("💰 [Purchase] 开始购买")
        currentCallbackResult = normalizedCallbackResult
        currentBatchNo = normalizedBatchNo
        presentingVC = vc

        showLoading(on: vc)

        Task {
            do {
                print("💰 [Purchase] 查询商品: [\(normalizedBatchNo)]")
                let products = try await Product.products(for: [normalizedBatchNo])
                print("💰 [Purchase] 查询结果: \(products.count) 个商品")
                guard let product = products.first else {
                    print("💰 [Purchase] ❌ 商品未找到")
                    await MainActor.run {
                        finishPurchase(success: false, message: "Product not found")
                    }
                    return
                }

                print("💰 [Purchase] 发起购买: \(product.displayName) - \(product.displayPrice)")
                let result = try await product.purchase()
                switch result {
                case .success(let verification):
                    switch verification {
                    case .verified(let transaction):
                        rememberPendingCallback(
                            transactionId: String(transaction.id),
                            callbackResult: normalizedCallbackResult
                        )
                        do {
                            let receipt = try await loadAppStoreReceiptData(refreshBeforeRead: true)
                            await MainActor.run {
                                verifyPurchase(
                                    transaction: transaction,
                                    receipt: receipt,
                                    callbackResult: normalizedCallbackResult,
                                    purchaseID: purchaseID
                                )
                            }
                        } catch {
                            await MainActor.run {
                                rememberPendingVerification(
                                    transaction: transaction,
                                    callbackResult: normalizedCallbackResult,
                                    code: nil,
                                    message: error.localizedDescription
                                )
                                schedulePendingVerificationRetry(
                                    transaction: transaction,
                                    callbackResult: normalizedCallbackResult,
                                    attempt: 0
                                )
                                let message = paymentMessage(
                                    "Purchase is processing. Please wait.",
                                    diagnostics: currentPaymentDiagnostic
                                )
                                finishPurchase(success: false, message: message, alertTitle: "Processing")
                            }
                        }
                        return
                    case .unverified(_, let error):
                        await MainActor.run {
                            finishPurchase(success: false, message: error.localizedDescription)
                        }
                    }
                case .pending:
                    await MainActor.run {
                        finishPurchase(success: false, message: "Purchase pending approval")
                    }
                case .userCancelled:
                    await MainActor.run {
                        finishPurchase(success: false, message: ObfuscatedBridgeText.Field.f13)
                    }
                @unknown default:
                    await MainActor.run {
                        finishPurchase(success: false, message: "Unknown error")
                    }
                }
            } catch {
                await MainActor.run {
                    finishPurchase(success: false, message: error.localizedDescription)
                }
            }
        }
    }

    // MARK: - 验单接口

    /// 验单接口
    /// 参数通配符：t → 交易ID, p → 验单凭据, c → 前端回调JSON
    private func verifyPurchase(
        transaction: Transaction,
        receipt: Data,
        callbackResult: String,
        purchaseID: UUID,
        attempt: Int = 0
    ) {
        let transactionId = String(transaction.id)
        let payload = receipt.base64EncodedString()

        let params: [String: Any] = [
            "trt": transactionId,                // 末尾 t
            "plp": payload,                      // 末尾 p
            "cbc": callbackResult                // 末尾 c
        ]
        let diagnostic = """
        stage=verify
        purchaseID=\(purchaseID.uuidString)
        attempt=\(attempt + 1)
        tx=\(transactionId)
        originalTx=\(transaction.originalID)
        sameAsLastUnfinishedTx=\(transactionId == lastUnfinishedTransactionID() ? "true" : "false")
        pid=\(transaction.productID)
        purchaseDate=\(iso8601String(from: transaction.purchaseDate))
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

        print("💰 [Purchase] 验单请求: transactionId=\(transactionId), productId=\(transaction.productID), receiptBytes=\(receipt.count)")
        GatewayAPI.shared.request(path: GatewayConfig.Path.verifyPay, params: params) { [weak self] code, _, message in
            guard self?.activePurchaseID == purchaseID else { return }
            print("💰 [Purchase] 验单结果: code=\(code ?? "nil"), message=\(message ?? "nil")")

            if code == "0" || code == "0000" {
                Task {
                    await transaction.finish()
                    await MainActor.run {
                        self?.clearUnfinishedTransactionIfNeeded(transactionId: transactionId)
                        self?.removePendingCallback(transactionId: transactionId)
                        self?.cancelPendingRetry(transactionId: transactionId)
                        print("💰 [Purchase] ✅ 购买成功")
                        self?.finishPurchase(success: true, message: "Purchase successful!")
                    }
                }

            } else {
                if let self,
                   self.shouldRetryMissingTransaction(code: code, message: message),
                   attempt < self.missingTransactionRetryDelays.count {
                    self.retryPurchaseVerification(
                        transaction: transaction,
                        callbackResult: callbackResult,
                        purchaseID: purchaseID,
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
                if let self, self.shouldKeepTransactionPending(code: code, message: message) {
                    self.rememberPendingVerification(
                        transaction: transaction,
                        callbackResult: callbackResult,
                        code: code,
                        message: message
                    )
                    self.schedulePendingVerificationRetry(
                        transaction: transaction,
                        callbackResult: callbackResult,
                        attempt: 0
                    )
                    let displayMessage = self.paymentMessage(
                        "Purchase is processing. Please wait.",
                        diagnostics: detail
                    )
                    self.finishPurchase(success: false, message: displayMessage, alertTitle: "Processing")
                    return
                }

                self?.rememberUnfinishedTransaction(transaction: transaction, code: code, message: message)
                let displayMessage = self?.paymentMessage(
                    message ?? "Verification failed",
                    diagnostics: detail
                ) ?? (message ?? "Verification failed")
                self?.finishPurchase(success: false, message: displayMessage)
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
        transaction: Transaction,
        callbackResult: String,
        purchaseID: UUID,
        nextAttempt: Int
    ) {
        let delay = missingTransactionRetryDelays[nextAttempt - 1]
        currentPaymentDiagnostic += """

        retryAfterSeconds=\(delay)
        retryAttempt=\(nextAttempt + 1)
        """

        Task { [weak self] in
            try? await Task.sleep(nanoseconds: delay * 1_000_000_000)
            guard let self, self.activePurchaseID == purchaseID else {
                return
            }

            do {
                let refreshedReceipt = try await self.loadAppStoreReceiptData(refreshBeforeRead: true)
                await MainActor.run {
                    guard self.activePurchaseID == purchaseID else { return }
                    self.verifyPurchase(
                        transaction: transaction,
                        receipt: refreshedReceipt,
                        callbackResult: callbackResult,
                        purchaseID: purchaseID,
                        attempt: nextAttempt
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
                    let message = self.paymentMessage(
                        "Purchase is processing. Please wait.",
                        diagnostics: self.currentPaymentDiagnostic
                    )
                    self.finishPurchase(success: false, message: message, alertTitle: "Processing")
                }
            }
        }
    }

    private func verifyPendingTransaction(
        transaction: Transaction,
        callbackResult: String,
        reason: String,
        attempt: Int
    ) async {
        let transactionId = String(transaction.id)
        pendingRetryTasks[transactionId] = nil
        guard !isPurchasing else {
            schedulePendingVerificationRetry(
                transaction: transaction,
                callbackResult: callbackResult,
                attempt: attempt
            )
            return
        }

        do {
            let receipt = try await loadAppStoreReceiptData(refreshBeforeRead: true)
            let payload = receipt.base64EncodedString()
            let params: [String: Any] = [
                "trt": transactionId,
                "plp": payload,
                "cbc": callbackResult
            ]
            let diagnostic = """
            stage=pending_verify
            reason=\(reason)
            attempt=\(attempt + 1)
            tx=\(transactionId)
            originalTx=\(transaction.originalID)
            sameAsLastUnfinishedTx=\(transactionId == lastUnfinishedTransactionID() ? "true" : "false")
            pid=\(transaction.productID)
            purchaseDate=\(iso8601String(from: transaction.purchaseDate))
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

            print("💰 [Purchase] 补验请求: transactionId=\(transactionId), reason=\(reason), attempt=\(attempt + 1)")
            let response = await requestVerification(params: params)
            print("💰 [Purchase] 补验结果: code=\(response.code ?? "nil"), message=\(response.message ?? "nil")")

            if response.code == "0" || response.code == "0000" {
                await transaction.finish()
                await MainActor.run {
                    self.clearUnfinishedTransactionIfNeeded(transactionId: transactionId)
                    self.removePendingCallback(transactionId: transactionId)
                    self.cancelPendingRetry(transactionId: transactionId)
                    self.notifyH5PurchaseResult(success: true, message: "Purchase successful!")
                    print("💰 [Purchase] ✅ 补验成功")
                }
                return
            }

            rememberPendingVerification(
                transaction: transaction,
                callbackResult: callbackResult,
                code: response.code,
                message: response.message
            )

            if shouldKeepTransactionPending(code: response.code, message: response.message) {
                schedulePendingVerificationRetry(
                    transaction: transaction,
                    callbackResult: callbackResult,
                    attempt: attempt + 1
                )
            }
        } catch {
            rememberPendingVerification(
                transaction: transaction,
                callbackResult: callbackResult,
                code: nil,
                message: error.localizedDescription
            )
            schedulePendingVerificationRetry(
                transaction: transaction,
                callbackResult: callbackResult,
                attempt: attempt + 1
            )
        }
    }

    private func requestVerification(params: [String: Any]) async -> (code: String?, message: String?) {
        await withCheckedContinuation { continuation in
            GatewayAPI.shared.request(path: GatewayConfig.Path.verifyPay, params: params) { code, _, message in
                continuation.resume(returning: (code, message))
            }
        }
    }

    private func schedulePendingVerificationRetry(
        transaction: Transaction,
        callbackResult: String,
        attempt: Int
    ) {
        let transactionId = String(transaction.id)
        guard pendingRetryTasks[transactionId] == nil else { return }

        let delay = pendingVerificationRetryDelay(for: attempt)
        print("💰 [Purchase] 安排补验: transactionId=\(transactionId), delay=\(delay), attempt=\(attempt + 1)")
        pendingRetryTasks[transactionId] = Task { [weak self] in
            try? await Task.sleep(nanoseconds: delay * 1_000_000_000)
            await self?.verifyPendingTransaction(
                transaction: transaction,
                callbackResult: callbackResult,
                reason: "scheduled_retry",
                attempt: attempt
            )
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

    private func lastUnfinishedTransactionDiagnostic() -> String {
        guard let tx = UserDefaults.standard.string(forKey: lastUnfinishedTxKey), !tx.isEmpty else {
            return """
            lastUnfinishedTx=none
            pendingCallbackCount=\(pendingCallbackMap().count)
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
        """
    }

    private func rememberPendingVerification(
        transaction: Transaction,
        callbackResult: String,
        code: String?,
        message: String?
    ) {
        rememberPendingCallback(transactionId: String(transaction.id), callbackResult: callbackResult)
        rememberUnfinishedTransaction(transaction: transaction, code: code, message: message)
    }

    private func rememberUnfinishedTransaction(transaction: Transaction, code: String?, message: String?) {
        let tx = String(transaction.id)
        UserDefaults.standard.set(tx, forKey: lastUnfinishedTxKey)
        UserDefaults.standard.set(transaction.productID, forKey: lastUnfinishedPidKey)
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

    private func iso8601String(from date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    private enum ReceiptError: LocalizedError {
        case missingReceipt

        var errorDescription: String? {
            return "Receipt not found"
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

extension PurchaseManager: SKRequestDelegate {
    func requestDidFinish(_ request: SKRequest) {
        completeReceiptRefresh(.success(()))
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        completeReceiptRefresh(.failure(error))
    }
}
