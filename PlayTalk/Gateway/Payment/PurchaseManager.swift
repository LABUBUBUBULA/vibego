import StoreKit
import UIKit

/// iOS 内购管理器 (StoreKit 2)
/// H5 调 rechargePay 传 batchNo（产品ID） + callbackJson
/// 流程: 发起内购 → 显示 Loading → 支付成功 → 调验单接口
final class PurchaseManager: NSObject {

    static let shared = PurchaseManager()
    private override init() {
        super.init()
    }

    private var currentCallbackJson: String = ""
    private var currentBatchNo: String = ""
    private weak var presentingVC: WebContainerViewController?
    private var loadingView: UIView?
    private var isPurchasing = false

    // MARK: - 发起购买

    func purchase(batchNo: String, callbackJson: String, from vc: WebContainerViewController) {
        // 防重复购买
        guard !isPurchasing else {
            print("�� [Purchase] ⚠️ 正在购买中，忽略重复请求")
            return
        }
        isPurchasing = true

        print("💰 [Purchase] 开始购买: batchNo=\(batchNo), callbackJson=\(callbackJson)")
        currentCallbackJson = callbackJson
        currentBatchNo = batchNo
        presentingVC = vc

        showLoading(on: vc)

        Task {
            do {
                print("💰 [Purchase] 查询商品: [\(batchNo)]")
                let products = try await Product.products(for: [batchNo])
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
                        await transaction.finish()
                        await MainActor.run {
                            verifyPurchase(
                                transactionId: String(transaction.id),
                                receipt: transaction.jsonRepresentation,
                                callbackJson: callbackJson
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
                        finishPurchase(success: false, message: "cancelled")
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

    /// 验单接口: /opi/v1/order/receip (末尾 p)
    /// 参数通配符：t → transactionId, p → payload, c → callbackResult
    private func verifyPurchase(transactionId: String, receipt: Data, callbackJson: String) {
        let payload = receipt.base64EncodedString()

        let params: [String: Any] = [
            "trt": transactionId,                // 末尾 t
            "plp": payload,                      // 末尾 p
            "cbc": callbackJson                  // 末尾 c
        ]

        print("💰 [Purchase] 验单请求: transactionId=\(transactionId)")
        GatewayAPI.shared.request(path: GatewayConfig.Path.verifyPay, params: params) { [weak self] code, _, message in
            print("💰 [Purchase] 验单结果: code=\(code ?? "nil"), message=\(message ?? "nil")")

            if code == "0" || code == "0000" {
                print("💰 [Purchase] ✅ 购买成功")
                self?.finishPurchase(success: true, message: "Purchase successful!")

            } else {
                self?.finishPurchase(success: false, message: message ?? "Verification failed")
            }
        }
    }

    // MARK: - 统一结束购买

    /// 购买结束（成功/失败）：隐藏loading + 通知H5 + 重置状态
    private func finishPurchase(success: Bool, message: String) {
        print("💰 [Purchase] 结束: success=\(success), message=\(message)")
        hideLoading()
        isPurchasing = false

        // 通过 JS 通知 H5 购买结果，让 H5 自己处理 UI
        let state = success ? "success" : "failed"
        let safeMessage = message.replacingOccurrences(of: "'", with: "\\'")
        let js = """
        window.dispatchEvent(new CustomEvent('nativePayResult', {
            detail: { state: '\(state)', message: '\(safeMessage)' }
        }));
        """
        presentingVC?.webView.evaluateJavaScript(js, completionHandler: nil)

        // 取消的不弹原生 alert，让 H5 处理
        if message == "cancelled" { return }

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

        // 超时保护：15秒后自动关闭
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
            if self?.loadingView != nil {
                print("💰 [Purchase] ⚠️ Loading 超时，自动关闭")
                self?.finishPurchase(success: false, message: "Request timed out")
            }
        }

        loadingView = overlay
    }

    private func hideLoading() {
        loadingView?.removeFromSuperview()
        loadingView = nil
    }
}
