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
    private let missingTransactionRetryDelays: [UInt64] = [2, 5, 10, 15]

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
        pid=\(normalizedBatchNo)
        callbackBytes=\(normalizedCallbackResult.utf8.count)
        path=\(GatewayConfig.Path.verifyPay)
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
                        let receipt = try await loadAppStoreReceiptData(refreshBeforeRead: true)
                        await MainActor.run {
                            verifyPurchase(
                                transaction: transaction,
                                receipt: receipt,
                                callbackResult: normalizedCallbackResult,
                                purchaseID: purchaseID
                            )
                        }
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
        attempt=\(attempt + 1)
        tx=\(transactionId)
        pid=\(transaction.productID)
        receiptBytes=\(receipt.count)
        callbackBytes=\(callbackResult.utf8.count)
        path=\(GatewayConfig.Path.verifyPay)
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
                code=\(code ?? "nil")
                message=\(message ?? "nil")
                """
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
                    let message = self.paymentMessage(
                        error.localizedDescription,
                        diagnostics: self.currentPaymentDiagnostic
                    )
                    self.finishPurchase(success: false, message: message)
                }
            }
        }
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
        try await withCheckedThrowingContinuation { continuation in
            receiptRefreshContinuation = continuation
            let request = SKReceiptRefreshRequest(receiptProperties: nil)
            receiptRefreshRequest = request
            request.delegate = self
            request.start()
        }
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
    private func finishPurchase(success: Bool, message: String) {
        print("💰 [Purchase] 结束: success=\(success), message=\(message)")
        hideLoading()
        isPurchasing = false
        activePurchaseID = nil

        if !success {
            showPaymentDiagnosticsIfNeeded(message)
        }

        // 通过 JS 通知 H5 购买结果，让 H5 自己处理 UI
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

        // 取消的不弹原生 alert，让 H5 处理
        if message == ObfuscatedBridgeText.Field.f13 { return }

        // 非取消的失败/成功才弹原生 alert
        guard let vc = presentingVC else { return }
        let alert = UIAlertController(
            title: success ? "Success" : "Failed",
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

    private func jsEscapedString(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
    }

    private func showPaymentDiagnosticsIfNeeded(_ message: String) {
        guard isPaymentDiagnosticsEnabled else { return }
        let diagnostic = """
        \(message)

        Diagnostics
        \(currentPaymentDiagnostic)
        """
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
