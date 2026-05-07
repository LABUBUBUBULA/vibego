import UIKit

/// 场景代理 - 管理 App 窗口和根视图控制器
/// 对应 Android SplashActivity 的路由逻辑：
/// - 已登录 → 进入主页（MainTabBarController）
/// - 未登录 → 进入欢迎页（WelcomeViewController）
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)

        // 根据登录状态决定根页面（对应 Android SplashActivity 的 loginFlag 判断）
        if UserManager.shared.isLoggedIn {
            // 已登录 → 直接进主页
            window?.rootViewController = MainTabBarController()
        } else {
            // 未登录 → 显示欢迎页
            let welcomeVC = WelcomeViewController()
            let nav = UINavigationController(rootViewController: welcomeVC)
            window?.rootViewController = nav
        }

        window?.makeKeyAndVisible()
    }
}
