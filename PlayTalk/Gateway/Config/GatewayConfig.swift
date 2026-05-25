import UIKit

/// 网关配置 - 集中管理所有可配置参数
struct GatewayConfig {

    // MARK: - 服务端

    static let baseURL = "https://opi.zi2j7pji.link"

    /// 系统分配的应用ID（动态获取方法，后期可换）
    static var appId: String {
        return _appId
    }
    private static var _appId = "56743268"

    static func updateAppId(_ newId: String) {
        _appId = newId
    }

    // MARK: - AES 加解密

    static let aesKey = "nsoftt4kobejp7rb"
    static let aesIV  = "tvmi0z9aus0rzjug"

    // MARK: - 接口路径（通配符模式，最后一个字母匹配即可）

    struct Path {
        static let launch       = "/opi/v1/app/server/info"          // 末尾 o → 不行，没有o。实际末尾字母要匹配
        // 启动接口末尾 o
        static let launchCheck  = "/opi/v1/get/app/configo"
        // 登录接口末尾 l
        static let login        = "/opi/v1/user/portal"
        // 内购验单接口末尾 p
        static let verifyPay    = "/opi/v1/order/receip"
        // 用户行为上报末尾 v
        static let behaviorReport = "/opi/v1/track/activv"
        // Adjust上报末尾 j
        static let adjustReport = "/opi/v1/report/eventj"
        // H5加载上报末尾 t
        static let h5LoadReport = "/opi/v1/page/resultt"
    }

    // MARK: - 设备ID

    private static let deviceIdKey = "GatewayConfig.deviceId"

    /// 获取设备唯一标识（优先 identifierForVendor，取不到则生成UUID持久化）
    static var deviceId: String {
        if let cached = UserDefaults.standard.string(forKey: deviceIdKey), !cached.isEmpty {
            return cached
        }
        let id = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        UserDefaults.standard.set(id, forKey: deviceIdKey)
        return id
    }

    // MARK: - Token 管理

    private static let tokenKey = "GatewayConfig.loginToken"
    private static let passwordKey = "GatewayConfig.password"

    static var loginToken: String? {
        get { UserDefaults.standard.string(forKey: tokenKey) }
        set { UserDefaults.standard.set(newValue, forKey: tokenKey) }
    }

    static var savedPassword: String? {
        get { UserDefaults.standard.string(forKey: passwordKey) }
        set { UserDefaults.standard.set(newValue, forKey: passwordKey) }
    }

    static func clearTokens() {
        loginToken = nil
        savedPassword = nil
    }

    // MARK: - 启动接口返回数据缓存

    static var h5OpenValue: String?     // H5 域名地址
    static var locationFlag: Int = 0    // 是否需要强制定位
    static var loginFlag: Int = 0       // 是否已登录

    // MARK: - App 版本

    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    // MARK: - Push Token

    private static let pushTokenKey = "GatewayConfig.pushToken"

    static var pushToken: String {
        get { UserDefaults.standard.string(forKey: pushTokenKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: pushTokenKey) }
    }
}
