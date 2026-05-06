import UIKit

/// 场景代理 - 管理 App 窗口和根视图控制器
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)
        // 设置主页面为 TabBar 控制器（4个Tab）
        window?.rootViewController = MainTabBarController()
        window?.makeKeyAndVisible()
    }
}
