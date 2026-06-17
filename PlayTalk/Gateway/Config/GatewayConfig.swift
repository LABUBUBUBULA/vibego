import UIKit
import Security

/// 网关配置 - 集中管理所有可配置参数
struct GatewayConfig {

    // MARK: - 服务端

    static let baseURL = ObfuscatedGatewayText.g0

    /// 系统分配的应用ID（动态获取方法，后期可换）
    static var appId: String {
        return _appId
    }
    private static var _appId = ObfuscatedGatewayText.g1

    static func updateAppId(_ newId: String) {
        _appId = newId
    }

    // MARK: - AES 加解密

    static let aesKey = ObfuscatedGatewayText.g2
    static let aesIV  = ObfuscatedGatewayText.g3

    // MARK: - 接口路径（通配符模式，最后一个字母匹配即可）

    struct Path {
        static let launch       = ObfuscatedGatewayText.Path.p0      // 末尾 o → 不行，没有o。实际末尾字母要匹配
        // 启动接口末尾 o
        static let launchCheck  = ObfuscatedGatewayText.Path.p1
        // 登录接口末尾 l
        static let login        = ObfuscatedGatewayText.Path.p2
        // 内购验单接口末尾 p
        static let verifyPay    = ObfuscatedGatewayText.Path.p3
        // 用户行为上报末尾 v
        static let behaviorReport = ObfuscatedGatewayText.Path.p4
        // Adjust上报末尾 j
        static let adjustReport = ObfuscatedGatewayText.Path.p5
        // H5加载上报末尾 t
        static let h5LoadReport = ObfuscatedGatewayText.Path.p6
    }

    // MARK: - 设备ID

    private static let deviceIdKey = ObfuscatedGatewayText.StorageKey.k0

    /// 获取设备唯一标识：Keychain 持久化，尽量避免卸载重装后变化。
    static var deviceId: String {
        if let cached = KeychainDeviceIdStore.read(), !cached.isEmpty {
            UserDefaults.standard.set(cached, forKey: deviceIdKey)
            return cached
        }

        if let legacy = UserDefaults.standard.string(forKey: deviceIdKey), !legacy.isEmpty {
            KeychainDeviceIdStore.save(legacy)
            return legacy
        }

        let id = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        KeychainDeviceIdStore.save(id)
        UserDefaults.standard.set(id, forKey: deviceIdKey)
        return id
    }

    // MARK: - Token 管理

    private static let tokenKey = ObfuscatedGatewayText.StorageKey.k1
    private static let passwordKey = ObfuscatedGatewayText.StorageKey.k2

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

    private static let pushTokenKey = ObfuscatedGatewayText.StorageKey.k3

    static var pushToken: String {
        get { UserDefaults.standard.string(forKey: pushTokenKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: pushTokenKey) }
    }
}

private enum KeychainDeviceIdStore {
    private static var service: String {
        let bundleId = Bundle.main.bundleIdentifier ?? ObfuscatedGatewayText.g4
        return "\(bundleId).device"
    }
    private static let account = ObfuscatedGatewayText.g5

    static func read() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8),
              !value.isEmpty else {
            return nil
        }
        return value
    }

    static func save(_ value: String) {
        guard !value.isEmpty, let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var item = query
            item[kSecValueData as String] = data
            item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            SecItemAdd(item as CFDictionary, nil)
        }
    }
}
