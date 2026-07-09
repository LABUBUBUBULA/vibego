import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("🟢 [App] didFinishLaunching")
        PushPermissionManager.shared.registerForRemoteNotifications(application)
        Task { @MainActor in
            CoinPurchaseManager.shared.start()
        }
        PurchaseManager.shared.start()
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    // MARK: - APNs 推送注册

    /// APNs 注册成功 → 拿到 device token → 存到 GatewayConfig
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("🔔 [Push] token: \(token)")
        GatewayConfig.pushToken = token
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("🔔 [Push] 注册失败: \(error.localizedDescription)")
    }
}
