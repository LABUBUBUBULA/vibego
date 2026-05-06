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
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(
            title: "Home",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )

        let forumVC = ForumViewController()
        let forumNav = UINavigationController(rootViewController: forumVC)
        forumNav.tabBarItem = UITabBarItem(
            title: "Forum",
            image: UIImage(systemName: "bubble.left.and.bubble.right"),
            selectedImage: UIImage(systemName: "bubble.left.and.bubble.right.fill")
        )

        let messageVC = MessageViewController()
        let messageNav = UINavigationController(rootViewController: messageVC)
        messageNav.tabBarItem = UITabBarItem(
            title: "Messages",
            image: UIImage(systemName: "message"),
            selectedImage: UIImage(systemName: "message.fill")
        )

        let mineVC = MineViewController()
        let mineNav = UINavigationController(rootViewController: mineVC)
        mineNav.tabBarItem = UITabBarItem(
            title: "Mine",
            image: UIImage(systemName: "person"),
            selectedImage: UIImage(systemName: "person.fill")
        )

        // Configure navigation bar appearance for all tabs
        [homeNav, forumNav, messageNav, mineNav].forEach { nav in
            let navAppearance = UINavigationBarAppearance()
            navAppearance.configureWithOpaqueBackground()
            navAppearance.backgroundColor = Theme.Colors.darkBackground
            navAppearance.titleTextAttributes = [.foregroundColor: Theme.Colors.textPrimary]
            navAppearance.largeTitleTextAttributes = [.foregroundColor: Theme.Colors.textPrimary]
            nav.navigationBar.standardAppearance = navAppearance
            nav.navigationBar.scrollEdgeAppearance = navAppearance
            nav.navigationBar.tintColor = Theme.Colors.primaryYellow
        }

        viewControllers = [homeNav, forumNav, messageNav, mineNav]
    }
}
