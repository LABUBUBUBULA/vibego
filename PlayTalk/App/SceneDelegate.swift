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

        // 全局键盘收起：点击输入框以外空白区域时，结束当前编辑状态。
        // cancelsTouchesInView=false，避免影响按钮、列表、麦位等原本点击事件。
        let keyboardDismissTap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        keyboardDismissTap.cancelsTouchesInView = false
        window?.addGestureRecognizer(keyboardDismissTap)

        window?.rootViewController = SplashViewController()
        window?.makeKeyAndVisible()
    }

    @objc private func dismissKeyboard() {
        window?.endEditing(true)
    }
}
