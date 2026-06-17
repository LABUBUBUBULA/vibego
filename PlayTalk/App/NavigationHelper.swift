import UIKit

final class AppNavigationController: UINavigationController, UINavigationControllerDelegate, UIGestureRecognizerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        interactivePopGestureRecognizer?.delegate = self
        interactivePopGestureRecognizer?.isEnabled = true

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Theme.Colors.darkerBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.tintColor = .white
    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        let shouldHide = viewController is MainTabBarController
            || viewController is UserProfileViewController
        setNavigationBarHidden(shouldHide, animated: animated)
        // 导航栏隐藏时系统会禁用侧滑手势，必须每次重新启用
        interactivePopGestureRecognizer?.isEnabled = true
        interactivePopGestureRecognizer?.delegate = self
    }

    // MARK: - UIGestureRecognizerDelegate

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}

extension UIViewController {
    func makeAppBackButton(action: Selector) -> UIBarButtonItem {
        let button = UIButton(type: .system)
        // 缩放图片到 14x14 避免 Configuration 渲染原始尺寸
        let rawImage = UIImage(named: "ic_back")?.withRenderingMode(.alwaysTemplate)
        let targetSize = CGSize(width: 14, height: 14)
        let resized = UIGraphicsImageRenderer(size: targetSize).image { _ in
            rawImage?.draw(in: CGRect(origin: .zero, size: targetSize))
        }.withRenderingMode(.alwaysTemplate)
        var config = UIButton.Configuration.plain()
        config.image = resized
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 14)
        button.configuration = config
        button.tintColor = .white
        button.frame = CGRect(x: 0, y: 0, width: 32, height: 44)
        button.addTarget(self, action: action, for: .touchUpInside)
        return UIBarButtonItem(customView: button)
    }

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

    func showToast(_ message: String) {
        let toast = UILabel()
        toast.text = message
        toast.font = Theme.Fonts.regular(14)
        toast.textColor = .white
        toast.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toast.textAlignment = .center
        toast.layer.cornerRadius = 8
        toast.layer.masksToBounds = true
        toast.numberOfLines = 0
        toast.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toast)

        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),
            toast.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            toast.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40),
            toast.heightAnchor.constraint(greaterThanOrEqualToConstant: 36)
        ])

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            UIView.animate(withDuration: 0.3, animations: { toast.alpha = 0 }) { _ in
                toast.removeFromSuperview()
            }
        }
    }
}
