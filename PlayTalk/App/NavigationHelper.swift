import UIKit

final class AppNavigationController: UINavigationController, UINavigationControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self

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
        let isMainTabs = viewController is MainTabBarController
        setNavigationBarHidden(isMainTabs, animated: animated)
    }
}

extension UIViewController {
    func makeAppBackButton(action: Selector) -> UIBarButtonItem {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "ic_back")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .white
        button.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        button.imageEdgeInsets = UIEdgeInsets(top: 6, left: 2, bottom: 6, right: 10)
        button.contentHorizontalAlignment = .left
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
