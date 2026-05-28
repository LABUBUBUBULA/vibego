import Foundation
import UIKit
import CoreTelephony

/// 网关网络请求层
final class GatewayAPI: NSObject, URLSessionDelegate {

    static let shared = GatewayAPI()
    private override init() { super.init() }

    /// 自定义 URLSession
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config, delegate: nil, delegateQueue: nil)
    }()


    // MARK: - 通用请求

    func request(
        path: String,
        params: [String: Any],
        completion: @escaping (_ code: String?, _ data: [String: Any]?, _ message: String?) -> Void
    ) {
        guard let url = URL(string: GatewayConfig.baseURL + path) else {
            completion(nil, nil, "Invalid URL")
            return
        }

        guard let encrypted = AESCrypto.encryptJSON(params) else {
            completion(nil, nil, "Encryption failed")
            return
        }

        let appVersion = GatewayConfig.appVersion
        let deviceId = GatewayConfig.deviceId
        let pushToken = GatewayConfig.pushToken
        let appId = GatewayConfig.appId
        let loginToken = GatewayConfig.loginToken
        let osVer = UIDevice.current.systemVersion
        let model = UIDevice.current.model
        let bundleId = Bundle.main.bundleIdentifier ?? ""
        let tz = String(TimeZone.current.secondsFromGMT() / 3600)
        let trace = UUID().uuidString.prefix(8).lowercased()
        let ts = "\(Int(Date().timeIntervalSince1970 * 1000))"

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(appVersion, forHTTPHeaderField: "appVersion")
        req.setValue(deviceId, forHTTPHeaderField: "deviceNo")
        req.setValue(pushToken, forHTTPHeaderField: "pushToken")
        req.setValue(appId, forHTTPHeaderField: "appId")
        if let token = loginToken, !token.isEmpty {
            req.setValue(token, forHTTPHeaderField: "loginToken")
        }
        req.setValue(trace, forHTTPHeaderField: "x-gm-trace")
        req.setValue(ts, forHTTPHeaderField: "x-gm-ts")
        req.setValue("ios", forHTTPHeaderField: "x-gm-platform")
        req.setValue(osVer, forHTTPHeaderField: "x-gm-osver")
        req.setValue(model, forHTTPHeaderField: "x-gm-model")
        req.setValue(bundleId, forHTTPHeaderField: "x-gm-pkg")
        req.setValue(tz, forHTTPHeaderField: "x-gm-tz")

        // Body: 纯 hex 加密字符串（跟 Android 一致）
        req.httpBody = encrypted.data(using: .utf8)

        // ── 请求日志 ──
        let headers = req.allHTTPHeaderFields?.map { "\($0.key):\($0.value)" }.joined(separator: ", ") ?? ""
        if let jsonData = try? JSONSerialization.data(withJSONObject: params),
           let jsonStr = String(data: jsonData, encoding: .utf8) {
            print("📤 [\(path)] 请求头: {\(headers)}")
            print("�� [\(path)] 请求参数: \(jsonStr)")
        }

        session.dataTask(with: req) { data, response, error in
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

            guard let data = data, error == nil else {
                print("📥 [\(path)] ❌ 网络错误: \(error?.localizedDescription ?? "unknown")")
                DispatchQueue.main.async { completion(nil, nil, error?.localizedDescription ?? "Network error") }
                return
            }

            // ── 响应日志 ──
            Self.logResponse(path: path, statusCode: statusCode, data: data)

            Self.parseResponse(data: data, completion: completion)
        }.resume()
    }

    // MARK: - 异步上报

    func reportAsync(path: String, params: [String: Any]) {
        request(path: path, params: params) { _, _, _ in }
    }

    // MARK: - 响应日志

    private static func logResponse(path: String, statusCode: Int, data: Data) {
        let rawBody = String(data: data, encoding: .utf8) ?? "nil"

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("�� [\(path)] status=\(statusCode) 原始返回: \(rawBody)")
            return
        }

        let code = json["code"].map { "\($0)" } ?? "nil"
        let message = json["message"] as? String ?? ""

        // 解密 result 或 data 字段
        var decryptedStr = ""
        if let resultStr = json["result"] as? String, let decrypted = AESCrypto.decryptToJSON(resultStr) {
            if let d = try? JSONSerialization.data(withJSONObject: decrypted), let s = String(data: d, encoding: .utf8) {
                decryptedStr = s
            }
        } else if let dataStr = json["data"] as? String, let decrypted = AESCrypto.decryptToJSON(dataStr) {
            if let d = try? JSONSerialization.data(withJSONObject: decrypted), let s = String(data: d, encoding: .utf8) {
                decryptedStr = s
            }
        }

        if decryptedStr.isEmpty {
            print("📥 [\(path)] status=\(statusCode) code=\(code) message=\(message)")
        } else {
            print("📥 [\(path)] status=\(statusCode) code=\(code) message=\(message) data=\(decryptedStr)")
        }
    }

    // MARK: - 响应解析

    private static func parseResponse(
        data: Data,
        completion: @escaping (_ code: String?, _ data: [String: Any]?, _ message: String?) -> Void
    ) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            DispatchQueue.main.async { completion(nil, nil, "Invalid response") }
            return
        }

        let code: String? = json["code"].map { "\($0)" }
        let message = json["message"] as? String

        // Android 响应格式: {"code":"0000","message":"success","result":"<hex密文>"}
        var resultData: [String: Any]?
        if let resultStr = json["result"] as? String {
            resultData = AESCrypto.decryptToJSON(resultStr)
        } else if let dataStr = json["data"] as? String {
            resultData = AESCrypto.decryptToJSON(dataStr)
        } else if let dataDict = json["data"] as? [String: Any] {
            resultData = dataDict
        }

        DispatchQueue.main.async {
            completion(code, resultData, message)
        }
    }

    // MARK: - 工具方法

    static var isSimCardInserted: Int {
        let info = CTTelephonyNetworkInfo()
        if let carriers = info.serviceSubscriberCellularProviders {
            for (_, carrier) in carriers {
                if let name = carrier.carrierName, !name.isEmpty { return 1 }
            }
        }
        return 0
    }

    static var isVPNActive: Int {
        guard let cfDict = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any],
              let scoped = cfDict["__SCOPED__"] as? [String: Any] else { return 0 }
        for key in scoped.keys {
            if key.contains("tap") || key.contains("tun") || key.contains("ppp") || key.contains("ipsec") || key.contains("utun") { return 1 }
        }
        return 0
    }

    static var systemLanguages: [String] { Locale.preferredLanguages }
    static var timezone: String { TimeZone.current.identifier }
}
