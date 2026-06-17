import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        setupTabBar()
        setupViewControllers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    private func setupTabBar() {
        // Tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Theme.Colors.tabBarBackground

        // Normal state
        appearance.stackedLayoutAppearance.normal.iconColor = Theme.Colors.textSecondary
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: Theme.Colors.textSecondary,
            .font: Theme.Fonts.regular(10)
        ]

        // Selected state
        appearance.stackedLayoutAppearance.selected.iconColor = Theme.Colors.primaryYellow
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: Theme.Colors.primaryYellow,
            .font: Theme.Fonts.medium(10)
        ]

        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }

        // Top border line
        tabBar.layer.borderWidth = 0.5
        tabBar.layer.borderColor = Theme.Colors.separator.cgColor
    }

    private func setupViewControllers() {
        let homeVC = HomeViewController()
        homeVC.tabBarItem = UITabBarItem(
            title: "Explore",
            image: UIImage(systemName: "gamecontroller"),
            selectedImage: UIImage(systemName: "gamecontroller.fill")
        )

        let forumVC = ForumViewController()
        forumVC.tabBarItem = UITabBarItem(
            title: "Community",
            image: UIImage(systemName: "flame"),
            selectedImage: UIImage(systemName: "flame.fill")
        )

        let messageVC = MessageViewController()
        messageVC.tabBarItem = UITabBarItem(
            title: "Chat",
            image: UIImage(systemName: "bubble.left.and.text.bubble.right"),
            selectedImage: UIImage(systemName: "bubble.left.and.text.bubble.right.fill")
        )

        let mineVC = MineViewController()
        mineVC.tabBarItem = UITabBarItem(
            title: "Profile",
            image: UIImage(systemName: "person.crop.circle"),
            selectedImage: UIImage(systemName: "person.crop.circle.fill")
        )

        viewControllers = [homeVC, forumVC, messageVC, mineVC]
    }
}

extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
}
