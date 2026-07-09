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

        case ObfuscatedBridgeText.Handler.h0:
            // 支付消息
            if let body = message.body as? [String: Any] {
                handlePaymentBody(body)
            } else if let bodyString = message.body as? String,
                      let body = parseJSONStringDictionary(bodyString) {
                handlePaymentBody(body)
            } else {
                print("🔌 [JSBridge] payment message parse failed: \(message.body)")
            }

        case ObfuscatedBridgeText.Handler.h5:
            print("🔌 [JSBridge] product id message ignored; waiting for payment payload")

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
        if let result = stringifyBridgeJSON(body[ObfuscatedBridgeText.Field.f1]) {
            return result
        }

        if let result = stringifyBridgeJSON(body[ObfuscatedBridgeText.Field.f15]) {
            return result
        }

        if let orderCode = body[ObfuscatedBridgeText.Field.f2],
           let result = stringifyBridgeJSON([ObfuscatedBridgeText.Field.f2: orderCode]) {
            return result
        }

        return fallbackCallbackResult(from: body) ?? ""
    }

    private func handlePaymentBody(_ body: [String: Any]) {
        let batchNo = body[ObfuscatedBridgeText.Field.f0] as? String ?? ""
        let callbackResult = parseCallbackResult(from: body)
        print("🔌 [JSBridge] payment message parsed")
        delegate?.handleRechargePay(batchNo: batchNo, callbackResult: callbackResult)
    }

    private func parseJSONStringDictionary(_ string: String) -> [String: Any]? {
        guard let data = string.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return dict
    }

    private func fallbackCallbackResult(from body: [String: Any]) -> String? {
        var payload = body
        payload.removeValue(forKey: ObfuscatedBridgeText.Field.f0)
        payload = payload.compactMapValues { value in
            if value is NSNull { return nil }
            if let string = value as? String, string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return nil
            }
            return value
        }
        guard !payload.isEmpty else { return nil }
        return stringifyBridgeJSON(payload)
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
