import WebKit
import AVFoundation

/// JS Bridge 消息回调协议
protocol WebScriptHandlerDelegate: AnyObject {
    func handleRechargePay(batchNo: String, callbackJson: String)
    func handleOpenBrowser(type: String, url: String)
    func handlePageLoaded()
    func handleClose()
    func handleRequestPermission()
}

/// WKScriptMessageHandler 代理（避免循环引用）
/// H5 通过 window.webkit.messageHandlers.xxx.postMessage() 调用
class WebScriptHandler: NSObject, WKScriptMessageHandler {

    weak var delegate: WebScriptHandlerDelegate?

    init(delegate: WebScriptHandlerDelegate) {
        self.delegate = delegate
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {

        print("🔌 [JSBridge] 收到消息: name=\(message.name), body=\(message.body)")

        switch message.name {

        case "rechargePay", "Pay":
            // rechargePay({batchNo, callbackJson}) 或 Pay(batchNo)
            if let body = message.body as? [String: Any] {
                let batchNo = body["batchNo"] as? String ?? ""
                let callbackJson = body["callbackJson"] as? String
                    ?? body["orderCode"] as? String ?? ""
                print("🔌 [JSBridge] rechargePay → batchNo=\(batchNo), callbackJson=\(callbackJson)")
                delegate?.handleRechargePay(batchNo: batchNo, callbackJson: callbackJson)
            } else if let batchNo = message.body as? String {
                print("🔌 [JSBridge] rechargePay → batchNo=\(batchNo) (string)")
                delegate?.handleRechargePay(batchNo: batchNo, callbackJson: "")
            }

        case "openBrowser":
            // openBrowser({type, url})
            if let body = message.body as? [String: Any],
               let url = body["url"] as? String {
                let type = body["type"] as? String ?? "system"
                print("🔌 [JSBridge] openBrowser → type=\(type), url=\(url)")
                delegate?.handleOpenBrowser(type: type, url: url)
            } else {
                print("🔌 [JSBridge] openBrowser ❌ 参数解析失败: \(message.body)")
            }

        case "pageLoaded":
            print("🔌 [JSBridge] pageLoaded")
            delegate?.handlePageLoaded()

        case "Close":
            print("🔌 [JSBridge] Close")
            delegate?.handleClose()

        case "requestPermission":
            print("🔌 [JSBridge] requestPermission")
            delegate?.handleRequestPermission()

        default:
            print("🔌 [JSBridge] ⚠️ 未知消息: \(message.name)")
            break
        }
    }
}
