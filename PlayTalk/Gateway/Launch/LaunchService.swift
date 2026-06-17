import Foundation
import CoreTelephony

/// 启动接口调用 + A/B 分流判断
final class LaunchService {

    static let shared = LaunchService()
    private init() {}

    enum LaunchResult {
        case enterOriginal                              // 进入 A 包
        case enterWebLoggedIn(url: String)              // 进入 B 包，已登录，直接加载 H5
        case enterWebNeedLogin(url: String, needLocation: Bool)  // 进入 B 包，需登录
    }

    /// 调用启动接口
    func checkLaunch(completion: @escaping (LaunchResult) -> Void) {
        // 上报 app_open 事件
        BehaviorTracker.shared.track(.appOpen)

        // 参数通配符：最后一个字母匹配
        // d → useSimCard, n → useVpn, g → debug, e → language, t → timezone
        let params: [String: Any] = [
            "smd": GatewayAPI.isSimCardInserted,          // 末尾 d
            "vpn": GatewayAPI.isVPNActive,                // 末尾 n
            "dbg": 1,                                      // 末尾 g（调试模式，返回详细错误原因）
            "lne": GatewayAPI.systemLanguages,             // 末尾 e（数组）
            "tzt": GatewayAPI.timezone                     // 末尾 t
        ]

        GatewayAPI.shared.request(path: GatewayConfig.Path.launchCheck, params: params) { code, data, _ in
            guard code == "0000", let data = data else {
                // code != 0000 → 进入 A 包
                BehaviorTracker.shared.track(.originalView)
                completion(.enterOriginal)
                return
            }

            let loginFlag = (data["loginFlag"] as? Int)
                ?? (Int(data["loginFlag"] as? String ?? "") ?? 0)
            let locationFlag = (data["locationFlag"] as? Int)
                ?? (Int(data["locationFlag"] as? String ?? "") ?? 0)
            let openValue = data["openValue"] as? String ?? ""

            print("🟢 [Launch] config loaded")

            // 缓存到 Config
            GatewayConfig.loginFlag = loginFlag
            GatewayConfig.locationFlag = locationFlag
            GatewayConfig.h5OpenValue = openValue

            BehaviorTracker.shared.track(.normalView)

            if loginFlag == 1, let token = GatewayConfig.loginToken, !token.isEmpty {
                // 已登录 → 拼接 H5 地址
                let fullURL = Self.buildH5URL(baseURL: openValue, token: token)
                print("🟢 [Launch] session restored")
                completion(.enterWebLoggedIn(url: fullURL))
            } else {
                // 需要登录
                print("🟢 [Launch] login required")
                completion(.enterWebNeedLogin(url: openValue, needLocation: locationFlag == 1))
            }
        }
    }

    /// 拼接 H5 完整地址
    /// 格式: https://xxxx/?openParams=AES加密后参数&appId=appId
    static func buildH5URL(baseURL: String, token: String) -> String {
        let timestamp = "\(Int(Date().timeIntervalSince1970 * 1000))"
        let paramsDict: [String: String] = [
            "token": token,
            "timestamp": timestamp
        ]
        guard let paramsJSON = try? JSONSerialization.data(withJSONObject: paramsDict),
              let paramsString = String(data: paramsJSON, encoding: .utf8),
              let encrypted = AESCrypto.encrypt(paramsString) else {
            return baseURL
        }
        let separator = baseURL.contains("?") ? "&" : "?"
        return "\(baseURL)\(separator)openParams=\(encrypted)&appId=\(GatewayConfig.appId)"
    }
}
