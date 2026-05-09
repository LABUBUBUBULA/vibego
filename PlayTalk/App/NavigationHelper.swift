import UIKit

final class AppNavigationController: UINavigationController, UINavigationControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        let isMainTabs = viewController is MainTabBarController
        setNavigationBarHidden(isMainTabs, animated: animated)
    }
}

extension UIViewController {
    var appNavigationController: UINavigationController? {
        if let nav = navigationController {
            return nav
        }
        if let tab = tabBarController, let nav = tab.navigationController {
            return nav
        }
        return view.window?.rootViewController as? UINavigationController
    }

    func pushAppViewController(_ viewController: UIViewController, animated: Bool = true) {
        viewController.hidesBottomBarWhenPushed = true
        appNavigationController?.pushViewController(viewController, animated: animated)
    }

    func showMainTabsAsRoot() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        window.rootViewController = AppNavigationController(rootViewController: MainTabBarController())
        window.makeKeyAndVisible()
    }
}
