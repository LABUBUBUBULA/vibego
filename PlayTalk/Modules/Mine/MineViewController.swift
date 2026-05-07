import UIKit

/// 个人中心页 - 对应 Android GameMic 的 MineFragment
/// 布局（ScrollView）：背景图 → 头像+昵称+ID → 粉丝/关注/好友 → 余额/等级卡片 → 菜单列表 → 退出按钮
class MineViewController: UIViewController {

    // MARK: - 数据

    private let user = MockDataManager.shared.currentUser
    private let mockData = MockDataManager.shared

    // MARK: - UI 组件

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.backgroundColor = .clear
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Mine"
        view.backgroundColor = Theme.Colors.darkBackground
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - 界面搭建

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        // 1. 背景区域（320dp，对应 Android）
        let headerBg = UIView()
        headerBg.backgroundColor = Theme.Colors.primaryYellow.withAlphaComponent(0.1)
        headerBg.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerBg)

        // 2. 头像（90x90dp 圆形，对应 Android CardView）
        let avatarView = createAvatarView()
        contentView.addSubview(avatarView)

        // 3. 昵称（24sp bold）
        let nameLabel = UILabel()
        nameLabel.text = user.name
        nameLabel.font = Theme.Fonts.bold(24)
        nameLabel.textColor = Theme.Colors.textPrimary
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)

        // 4. 用户 ID（14sp gray）
        let idLabel = UILabel()
        idLabel.text = "ID: \(user.id)"
        idLabel.font = Theme.Fonts.regular(14)
        idLabel.textColor = Theme.Colors.textSecondary
        idLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(idLabel)

        // 5. 兴趣标签
        let interestStack = createInterestTags()
        contentView.addSubview(interestStack)

        // 6. 粉丝/关注/好友统计（3列，对应 Android 3列点击跳转）
        let statsView = createStatsView()
        contentView.addSubview(statsView)

        // 7. 余额和等级卡片（2列）
        let cardsView = createCardsView()
        contentView.addSubview(cardsView)

        // 8. 菜单列表（4项，对应 Android 的 Collection/Browse/Customer/Settings）
        let menuView = createMenuList()
        contentView.addSubview(menuView)

        // 9. 退出按钮
        let logoutButton = createLogoutButton()
        contentView.addSubview(logoutButton)

        NSLayoutConstraint.activate([
            headerBg.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerBg.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerBg.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerBg.heightAnchor.constraint(equalToConstant: 200),

            avatarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 80),
            avatarView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 90),
            avatarView.heightAnchor.constraint(equalToConstant: 90),

            nameLabel.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 12),
            nameLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            idLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            idLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            interestStack.topAnchor.constraint(equalTo: idLabel.bottomAnchor, constant: 12),
            interestStack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            interestStack.heightAnchor.constraint(equalToConstant: 28),

            statsView.topAnchor.constraint(equalTo: interestStack.bottomAnchor, constant: 24),
            statsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statsView.heightAnchor.constraint(equalToConstant: 60),

            cardsView.topAnchor.constraint(equalTo: statsView.bottomAnchor, constant: 16),
            cardsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardsView.heightAnchor.constraint(equalToConstant: 80),

            menuView.topAnchor.constraint(equalTo: cardsView.bottomAnchor, constant: 16),
            menuView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            menuView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            logoutButton.topAnchor.constraint(equalTo: menuView.bottomAnchor, constant: 24),
            logoutButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            logoutButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            logoutButton.heightAnchor.constraint(equalToConstant: 50),
            logoutButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }

    // MARK: - 头像视图

    /// 创建圆形头像（90x90dp，对应 Android 的 CardView 包裹）
    private func createAvatarView() -> UIView {
        let container = UIView()
        container.backgroundColor = Theme.Colors.primaryYellow.withAlphaComponent(0.3)
        container.layer.cornerRadius = 45
        container.layer.borderWidth = 3
        container.layer.borderColor = Theme.Colors.primaryYellow.cgColor
        container.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = String(user.name.prefix(1))
        label.font = Theme.Fonts.bold(36)
        label.textColor = Theme.Colors.primaryYellow
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }

    // MARK: - 兴趣标签

    /// 创建兴趣标签行（最多2个，对应 Android 的 interest tags）
    private func createInterestTags() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        let interests = user.interests.split(separator: ",").prefix(2)
        for interest in interests {
            let tag = UILabel()
            tag.text = "  \(interest)  "
            tag.font = Theme.Fonts.medium(12)
            tag.textColor = Theme.Colors.primaryYellow
            tag.backgroundColor = Theme.Colors.primaryYellow.withAlphaComponent(0.15)
            tag.layer.cornerRadius = 10
            tag.layer.masksToBounds = true
            stack.addArrangedSubview(tag)
        }
        return stack
    }

    // MARK: - 统计视图

    /// 创建粉丝/关注/好友统计（3列，对应 Android 的 3 个可点击列）
    private func createStatsView() -> UIView {
        let container = UIView()
        container.backgroundColor = Theme.Colors.cardBackground
        container.layer.cornerRadius = Theme.Dimensions.cornerRadius
        container.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        /// 格式化数字（如 487000 → "487K"）
        func formatCount(_ count: Int) -> String {
            if count >= 1000 {
                return String(format: "%.0fK", Double(count) / 1000.0)
            }
            return "\(count)"
        }

        let statsData: [(count: String, label: String)] = [
            (formatCount(mockData.fansCount), "Fans"),
            (formatCount(mockData.followingCount), "Following"),
            (formatCount(mockData.friendsCount), "Friends")
        ]

        for data in statsData {
            let item = UIView()

            let countLabel = UILabel()
            countLabel.text = data.count
            countLabel.font = Theme.Fonts.bold(18)
            countLabel.textColor = Theme.Colors.textPrimary
            countLabel.textAlignment = .center
            countLabel.translatesAutoresizingMaskIntoConstraints = false

            let titleLabel = UILabel()
            titleLabel.text = data.label
            titleLabel.font = Theme.Fonts.regular(12)
            titleLabel.textColor = Theme.Colors.textSecondary
            titleLabel.textAlignment = .center
            titleLabel.translatesAutoresizingMaskIntoConstraints = false

            item.addSubview(countLabel)
            item.addSubview(titleLabel)

            NSLayoutConstraint.activate([
                countLabel.centerXAnchor.constraint(equalTo: item.centerXAnchor),
                countLabel.topAnchor.constraint(equalTo: item.topAnchor, constant: 10),
                titleLabel.centerXAnchor.constraint(equalTo: item.centerXAnchor),
                titleLabel.topAnchor.constraint(equalTo: countLabel.bottomAnchor, constant: 2)
            ])

            stack.addArrangedSubview(item)
        }

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    // MARK: - 余额和等级卡片

    /// 创建余额/等级双卡片（对应 Android 的 Balance + Level 两列）
    private func createCardsView() -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false

        // 余额卡片
        let balanceCard = createInfoCard(title: "Balance", value: "\(mockData.coinBalance)", icon: "💰")
        // 等级卡片
        let levelCard = createInfoCard(title: "Level", value: "Lv.\(user.level)", icon: "⭐")

        stack.addArrangedSubview(balanceCard)
        stack.addArrangedSubview(levelCard)
        return stack
    }

    /// 创建信息卡片（余额/等级）
    private func createInfoCard(title: String, value: String, icon: String) -> UIView {
        let card = UIView()
        card.backgroundColor = Theme.Colors.cardBackground
        card.layer.cornerRadius = Theme.Dimensions.cornerRadius
        card.translatesAutoresizingMaskIntoConstraints = false

        let iconLabel = UILabel()
        iconLabel.text = icon
        iconLabel.font = UIFont.systemFont(ofSize: 24)
        iconLabel.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = Theme.Fonts.regular(12)
        titleLabel.textColor = Theme.Colors.textSecondary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = Theme.Fonts.bold(16)
        valueLabel.textColor = Theme.Colors.primaryYellow
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(iconLabel)
        card.addSubview(titleLabel)
        card.addSubview(valueLabel)

        NSLayoutConstraint.activate([
            iconLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            iconLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 8),
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),

            valueLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4)
        ])

        return card
    }

    // MARK: - 菜单列表

    /// 创建菜单列表（对应 Android 的 4 个菜单项，60dp 高度）
    private func createMenuList() -> UIView {
        let container = UIView()
        container.backgroundColor = Theme.Colors.cardBackground
        container.layer.cornerRadius = Theme.Dimensions.cornerRadius
        container.translatesAutoresizingMaskIntoConstraints = false

        let menuItems: [(icon: String, title: String)] = [
            ("⭐", "My Collection"),       // 对应 Android ic_collection
            ("🕐", "Browse Records"),       // 对应 Android ic_browse
            ("💬", "Customer Service"),      // 对应 Android ic_customer
            ("⚙️", "Settings")              // 对应 Android ic_settings
        ]

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        for (index, item) in menuItems.enumerated() {
            let row = createMenuRow(icon: item.icon, title: item.title, tag: index)
            stack.addArrangedSubview(row)

            // 行间分隔线（最后一行不加）
            if index < menuItems.count - 1 {
                let separator = UIView()
                separator.backgroundColor = Theme.Colors.separator
                separator.translatesAutoresizingMaskIntoConstraints = false
                stack.addArrangedSubview(separator)
                separator.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
            }
        }

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    /// 创建单个菜单行（60dp 高度）
    private func createMenuRow(icon: String, title: String, tag: Int) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 56).isActive = true

        let iconLabel = UILabel()
        iconLabel.text = icon
        iconLabel.font = UIFont.systemFont(ofSize: 20)
        iconLabel.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = Theme.Fonts.regular(15)
        titleLabel.textColor = Theme.Colors.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let arrowLabel = UILabel()
        arrowLabel.text = "›"
        arrowLabel.font = Theme.Fonts.regular(20)
        arrowLabel.textColor = Theme.Colors.textSecondary
        arrowLabel.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(iconLabel)
        row.addSubview(titleLabel)
        row.addSubview(arrowLabel)

        NSLayoutConstraint.activate([
            iconLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            iconLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            arrowLabel.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            arrowLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])

        // 点击手势
        row.tag = tag
        let tap = UITapGestureRecognizer(target: self, action: #selector(menuItemTapped(_:)))
        row.addGestureRecognizer(tap)

        return row
    }

    /// 菜单项点击（对应 Android 的 4 个跳转）
    @objc private func menuItemTapped(_ gesture: UITapGestureRecognizer) {
        guard let tag = gesture.view?.tag else { return }
        switch tag {
        case 0: break // TODO: CollectionActivity
        case 1: break // TODO: BrowseHistoryActivity
        case 2: break // TODO: CustomerServiceActivity
        case 3:
            let vc = SettingsViewController()
            navigationController?.pushViewController(vc, animated: true)
        default: break
        }
    }

    // MARK: - 退出按钮

    /// 创建退出登录按钮（对应 Android 的 Logout 按钮，黄色文字）
    private func createLogoutButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("Log Out", for: .normal)
        button.setTitleColor(Theme.Colors.primaryYellow, for: .normal)
        button.titleLabel?.font = Theme.Fonts.bold(16)
        button.backgroundColor = Theme.Colors.cardBackground
        button.layer.cornerRadius = Theme.Dimensions.cornerRadius
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        return button
    }

    /// 退出登录点击 - 弹出确认弹窗（对应 Android 的确认 Dialog）
    @objc private func logoutTapped() {
        let alert = UIAlertController(
            title: "Log Out",
            message: "Are you sure you want to log out?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { _ in
            // 清除用户数据，跳转到欢迎页（对应 Android → WelcomeActivity）
            UserManager.shared.logout()
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else { return }
            let nav = UINavigationController(rootViewController: WelcomeViewController())
            window.rootViewController = nav
            window.makeKeyAndVisible()
        })
        present(alert, animated: true)
    }
}
