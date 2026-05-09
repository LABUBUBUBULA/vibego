import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        setupViewControllers()
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
            title: "Home",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )

        let forumVC = ForumViewController()
        forumVC.tabBarItem = UITabBarItem(
            title: "Forum",
            image: UIImage(systemName: "bubble.left.and.bubble.right"),
            selectedImage: UIImage(systemName: "bubble.left.and.bubble.right.fill")
        )

        let messageVC = MessageViewController()
        messageVC.tabBarItem = UITabBarItem(
            title: "Messages",
            image: UIImage(systemName: "message"),
            selectedImage: UIImage(systemName: "message.fill")
        )

        let mineVC = MineViewController()
        mineVC.tabBarItem = UITabBarItem(
            title: "Mine",
            image: UIImage(systemName: "person"),
            selectedImage: UIImage(systemName: "person.fill")
        )

        viewControllers = [homeVC, forumVC, messageVC, mineVC]
    }
}
