import Foundation
import WebKit
import AVFoundation

/// JS Bridge 消息回调协议
protocol WebScriptHandlerDelegate: AnyObject {
    func handleRechargePay(batchNo: String, callbackResult: String)
    func handleOpenBrowser(type: String, url: String)
    func handlePageLoaded()
    func handleClose()
    func handleRequestPermission()
}

/// WKScriptMessageHandler 代理（避免循环引用）
/// H5 通过 WKScriptMessageHandler 调用
class WebScriptHandler: NSObject, WKScriptMessageHandler {

    weak var delegate: WebScriptHandlerDelegate?

    init(delegate: WebScriptHandlerDelegate) {
        self.delegate = delegate
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {

        print("🔌 [JSBridge] 收到消息: name=\(message.name), body=\(message.body)")

        switch message.name {

        case ObfuscatedBridgeText.Handler.h0, ObfuscatedBridgeText.Handler.h5:
            // 支付消息
            if let body = message.body as? [String: Any] {
                let batchNo = body[ObfuscatedBridgeText.Field.f0] as? String ?? ""
                let callbackResult = parseCallbackResult(from: body)
                print("🔌 [JSBridge] payment message parsed")
                delegate?.handleRechargePay(batchNo: batchNo, callbackResult: callbackResult)
            } else if let batchNo = message.body as? String {
                print("🔌 [JSBridge] payment string message parsed")
                delegate?.handleRechargePay(batchNo: batchNo, callbackResult: "")
            }

        case ObfuscatedBridgeText.Handler.h1:
            // 外部打开消息
            if let body = message.body as? [String: Any],
               let url = body[ObfuscatedBridgeText.Field.f3] as? String {
                let type = body[ObfuscatedBridgeText.Field.f4] as? String ?? ObfuscatedBridgeText.Field.f14
                print("🔌 [JSBridge] open message parsed")
                delegate?.handleOpenBrowser(type: type, url: url)
            } else {
                print("🔌 [JSBridge] open message parse failed: \(message.body)")
            }

        case ObfuscatedBridgeText.Handler.h2:
            print("🔌 [JSBridge] page event")
            delegate?.handlePageLoaded()

        case ObfuscatedBridgeText.Handler.h3:
            print("🔌 [JSBridge] Close")
            delegate?.handleClose()

        case ObfuscatedBridgeText.Handler.h4:
            print("🔌 [JSBridge] permission event")
            delegate?.handleRequestPermission()

        default:
            print("🔌 [JSBridge] ⚠️ 未知消息: \(message.name)")
            break
        }
    }

    private func parseCallbackResult(from body: [String: Any]) -> String {
        if let result = stringifyBridgeJSON(body[ObfuscatedBridgeText.Field.f15]) {
            return result
        }

        if let orderCode = body[ObfuscatedBridgeText.Field.f2],
           let result = stringifyBridgeJSON([ObfuscatedBridgeText.Field.f2: orderCode]) {
            return result
        }

        return ""
    }

    private func stringifyBridgeJSON(_ value: Any?) -> String? {
        guard let value, !(value is NSNull) else { return nil }

        if let string = value as? String {
            return string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : string
        }

        guard JSONSerialization.isValidJSONObject(value),
              let data = try? JSONSerialization.data(withJSONObject: value),
              let string = String(data: data, encoding: .utf8),
              !string.isEmpty else {
            return nil
        }
        return string
    }
}
