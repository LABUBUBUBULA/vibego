import UIKit

class MineViewController: UIViewController {

    private var user: User {
        UserManager.shared.currentUser ?? MockDataManager.shared.users[0]
    }
    private let mockData = MockDataManager.shared

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.backgroundColor = .clear
        sv.showsVerticalScrollIndicator = false
        sv.contentInsetAdjustmentBehavior = .never
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Colors.darkerBackground
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        rebuildUI()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // push 到子页面时恢复导航栏，切tab时由 MainTabBarController 统一管理
        if let nav = navigationController, nav.viewControllers.count > 1 {
            navigationController?.setNavigationBarHidden(false, animated: animated)
        }
    }

    private func rebuildUI() {
        view.subviews.forEach { $0.removeFromSuperview() }
        scrollView.subviews.forEach { $0.removeFromSuperview() }
        contentView.subviews.forEach { $0.removeFromSuperview() }
        setupUI()
    }

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        let header = createHeader()
        let statsView = createStatsView()
        let cardsView = createCardsView()
        let menuStack = createMenuList()
        let logoutButton = createLogoutButton()

        contentView.addSubview(header)
        contentView.addSubview(statsView)
        contentView.addSubview(cardsView)
        contentView.addSubview(menuStack)
        contentView.addSubview(logoutButton)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            header.topAnchor.constraint(equalTo: contentView.topAnchor),
            header.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 210),

            statsView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 14),
            statsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            statsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            statsView.heightAnchor.constraint(equalToConstant: 64),

            cardsView.topAnchor.constraint(equalTo: statsView.bottomAnchor, constant: 16),
            cardsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            cardsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            cardsView.heightAnchor.constraint(equalToConstant: 66),

            menuStack.topAnchor.constraint(equalTo: cardsView.bottomAnchor, constant: 28),
            menuStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            menuStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            logoutButton.topAnchor.constraint(equalTo: menuStack.bottomAnchor, constant: 32),
            logoutButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            logoutButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            logoutButton.heightAnchor.constraint(equalToConstant: 64),
            logoutButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -48)
        ])
    }

    private func createHeader() -> UIView {
        let header = UIView()
        header.translatesAutoresizingMaskIntoConstraints = false
        header.clipsToBounds = true

        let bg = UIImageView(image: UIImage(named: "bg_mine"))
        bg.contentMode = .scaleAspectFill
        bg.alpha = 0.55
        bg.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(bg)

        let dim = UIView()
        dim.backgroundColor = Theme.Colors.darkerBackground.withAlphaComponent(0.42)
        dim.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(dim)

        let avatar = UIImageView(image: user.displayAvatarImage ?? UIImage(named: user.avatarImage))
        avatar.contentMode = .scaleAspectFill
        avatar.layer.cornerRadius = 31
        avatar.layer.masksToBounds = true
        avatar.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(avatar)

        let nameLabel = UILabel()
        nameLabel.text = user.name
        nameLabel.font = Theme.Fonts.bold(24)
        nameLabel.textColor = .white
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(nameLabel)

        let idLabel = UILabel()
        idLabel.text = "ID:\(user.id)"
        idLabel.font = Theme.Fonts.regular(13)
        idLabel.textColor = Theme.Colors.textSecondary
        idLabel.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(idLabel)

        let badgesStack = UIStackView()
        badgesStack.axis = .horizontal
        badgesStack.alignment = .center
        badgesStack.spacing = 10
        badgesStack.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(badgesStack)

        let level = makeLevelIcon(level: user.level)
        badgesStack.addArrangedSubview(level)

        let game = makeGamePill(text: user.interests.split(separator: ",").first.map(String.init) ?? "PUBG")
        badgesStack.addArrangedSubview(game)

        let edit = UIButton(type: .system)
        edit.setImage(UIImage(named: "ic_edit") ?? UIImage(systemName: "pencil"), for: .normal)
        edit.tintColor = .white
        edit.translatesAutoresizingMaskIntoConstraints = false
        edit.addTarget(self, action: #selector(editProfileTapped), for: .touchUpInside)
        header.addSubview(edit)

        let homepageWrap = UIView()
        homepageWrap.backgroundColor = .clear
        homepageWrap.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(homepageWrap)

        let homepage = UIButton(type: .system)
        var homepageCfg = UIButton.Configuration.plain()
        homepageCfg.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)
        homepageCfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs
            a.font = Theme.Fonts.bold(12)
            a.foregroundColor = UIColor.white
            return a
        }
        homepageCfg.title = "Homepage ›"
        homepage.configuration = homepageCfg
        homepage.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        homepage.layer.cornerRadius = 12
        homepage.translatesAutoresizingMaskIntoConstraints = false
        homepage.addTarget(self, action: #selector(homepageTapped), for: .touchUpInside)
        homepageWrap.addSubview(homepage)

        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: header.topAnchor),
            bg.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            bg.bottomAnchor.constraint(equalTo: header.bottomAnchor),

            dim.topAnchor.constraint(equalTo: header.topAnchor),
            dim.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            dim.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            dim.bottomAnchor.constraint(equalTo: header.bottomAnchor),

            avatar.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 22),
            avatar.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -32),
            avatar.widthAnchor.constraint(equalToConstant: 62),
            avatar.heightAnchor.constraint(equalToConstant: 62),

            nameLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 14),
            nameLabel.topAnchor.constraint(equalTo: avatar.topAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: edit.leadingAnchor, constant: -12),

            idLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            idLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5),

            badgesStack.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            badgesStack.topAnchor.constraint(equalTo: idLabel.bottomAnchor, constant: 10),
            badgesStack.trailingAnchor.constraint(lessThanOrEqualTo: homepageWrap.leadingAnchor, constant: -10),
            badgesStack.heightAnchor.constraint(equalToConstant: 24),

            level.widthAnchor.constraint(equalToConstant: 60),
            level.heightAnchor.constraint(equalToConstant: 24),
            game.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            game.heightAnchor.constraint(equalToConstant: 24),

            edit.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -26),
            edit.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            edit.widthAnchor.constraint(equalToConstant: 34),
            edit.heightAnchor.constraint(equalToConstant: 34),

            homepageWrap.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -18),
            homepageWrap.centerYAnchor.constraint(equalTo: badgesStack.centerYAnchor),
            homepageWrap.widthAnchor.constraint(equalToConstant: 112),
            homepageWrap.heightAnchor.constraint(equalToConstant: 26),

            homepage.topAnchor.constraint(equalTo: homepageWrap.topAnchor),
            homepage.leadingAnchor.constraint(equalTo: homepageWrap.leadingAnchor),
            homepage.trailingAnchor.constraint(equalTo: homepageWrap.trailingAnchor),
            homepage.bottomAnchor.constraint(equalTo: homepageWrap.bottomAnchor)
        ])

        return header
    }

    private func makeLevelIcon(level: Int) -> UIImageView {
        let imageName = "bg_level_\(min(max(level, 1), 10))"
        let imageView = UIImageView(image: UIImage(named: imageName) ?? UIImage(named: "level_badge"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }

    private func makeGamePill(text: String) -> UIView {
        let view = GradientView(colors: [UIColor(hex: "#65C8FF"), UIColor(hex: "#4B78FF")])
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = text
        label.font = Theme.Fonts.bold(11)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        return view
    }

    private func createStatsView() -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false

        let statsData: [(count: String, label: String)] = [
            (formatCount(mockData.fansCount), "Fans"),
            (formatCount(mockData.followingCount), "Follow"),
            (formatCount(mockData.friendsCount), "Friends")
        ]

        for (index, data) in statsData.enumerated() {
            let item = UIView()
            item.tag = index
            item.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(statsTapped(_:))))
            item.isUserInteractionEnabled = true

            let countLabel = UILabel()
            countLabel.text = data.count
            countLabel.font = Theme.Fonts.bold(27)
            countLabel.textColor = .white
            countLabel.textAlignment = .center
            countLabel.translatesAutoresizingMaskIntoConstraints = false

            let titleLabel = UILabel()
            titleLabel.text = data.label
            titleLabel.font = Theme.Fonts.regular(14)
            titleLabel.textColor = Theme.Colors.textSecondary
            titleLabel.textAlignment = .center
            titleLabel.translatesAutoresizingMaskIntoConstraints = false

            item.addSubview(countLabel)
            item.addSubview(titleLabel)

            NSLayoutConstraint.activate([
                countLabel.centerXAnchor.constraint(equalTo: item.centerXAnchor),
                countLabel.topAnchor.constraint(equalTo: item.topAnchor),
                titleLabel.centerXAnchor.constraint(equalTo: item.centerXAnchor),
                titleLabel.topAnchor.constraint(equalTo: countLabel.bottomAnchor, constant: 8)
            ])

            stack.addArrangedSubview(item)
        }

        return stack
    }

    private func createCardsView() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 16
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false

        let balanceCard = createInfoCard(title: "Banlance", value: formatBalance(mockData.coinBalance), background: "bg_balance")
        balanceCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(rechargeTapped)))
        balanceCard.isUserInteractionEnabled = true

        let levelCard = createInfoCard(title: "Level", value: String(format: "%02d", user.level), background: "bg_level")
        levelCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(levelTapped)))
        levelCard.isUserInteractionEnabled = true

        stack.addArrangedSubview(balanceCard)
        stack.addArrangedSubview(levelCard)
        return stack
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        }
        if count >= 10_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }

    private func formatBalance(_ balance: Int) -> String {
        if balance >= 1_000_000 {
            return String(format: "%.1fM", Double(balance) / 1_000_000)
        }
        if balance >= 10_000 {
            return String(format: "%.1fK", Double(balance) / 1_000)
        }
        return "\(balance)"
    }

    private func createInfoCard(title: String, value: String, background: String) -> UIView {
        let card = UIView()
        card.layer.cornerRadius = 12
        card.clipsToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false

        let bg = UIImageView(image: UIImage(named: background))
        bg.contentMode = .scaleAspectFill
        bg.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = Theme.Fonts.bold(16)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = Theme.Fonts.bold(16)
        valueLabel.textColor = .white
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(bg)
        card.addSubview(titleLabel)
        card.addSubview(valueLabel)

        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: card.topAnchor),
            bg.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            bg.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            valueLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2)
        ])

        return card
    }

    private func createMenuList() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        let menuItems: [(icon: String, title: String)] = [
            ("ic_collection", "My collection"),
            ("ic_browse", "Browse records"),
            ("ic_customer", "Customer service"),
            ("ic_settings", "Settings")
        ]

        for (index, item) in menuItems.enumerated() {
            stack.addArrangedSubview(createMenuRow(icon: item.icon, title: item.title, tag: index))
        }

        return stack
    }

    private func createMenuRow(icon: String, title: String, tag: Int) -> UIView {
        let row = UIView()
        row.backgroundColor = Theme.Colors.cardBackground
        row.layer.cornerRadius = 12
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 58).isActive = true

        let iconView = UIImageView(image: UIImage(named: icon))
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = Theme.Fonts.regular(16)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let arrowLabel = UILabel()
        arrowLabel.text = "›"
        arrowLabel.font = Theme.Fonts.regular(36)
        arrowLabel.textColor = Theme.Colors.textSecondary
        arrowLabel.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(iconView)
        row.addSubview(titleLabel)
        row.addSubview(arrowLabel)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 22),
            iconView.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 18),
            titleLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            arrowLabel.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -24),
            arrowLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])

        row.tag = tag
        row.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(menuItemTapped(_:))))
        return row
    }

    @objc private func editProfileTapped() {
        pushAppViewController(EditProfileViewController(), animated: true)
    }

    @objc private func homepageTapped() {
        let vc = UserProfileViewController()
        vc.user = user
        pushAppViewController(vc, animated: true)
    }

    @objc private func rechargeTapped() {
        pushAppViewController(RechargeViewController(), animated: true)
    }

    @objc private func levelTapped() {
        pushAppViewController(UserLevelViewController(), animated: true)
    }

    @objc private func statsTapped(_ gesture: UITapGestureRecognizer) {
        guard let tag = gesture.view?.tag else { return }
        let vc = FansViewController()
        switch tag {
        case 0: vc.listType = .fans
        case 1: vc.listType = .following
        case 2: vc.listType = .friends
        default: return
        }
        pushAppViewController(vc, animated: true)
    }

    @objc private func menuItemTapped(_ gesture: UITapGestureRecognizer) {
        guard let tag = gesture.view?.tag else { return }
        switch tag {
        case 0:
            let vc = RoomListViewController()
            vc.listType = .collection
            pushAppViewController(vc, animated: true)
        case 1:
            let vc = RoomListViewController()
            vc.listType = .browseHistory
            pushAppViewController(vc, animated: true)
        case 2:
            pushAppViewController(CustomerServiceViewController(), animated: true)
        case 3:
            pushAppViewController(SettingsViewController(), animated: true)
        default:
            break
        }
    }

    private func createLogoutButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("Log Out", for: .normal)
        button.setTitleColor(Theme.Colors.primaryYellow, for: .normal)
        button.titleLabel?.font = Theme.Fonts.bold(18)
        button.backgroundColor = Theme.Colors.cardBackground
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        return button
    }

    @objc private func logoutTapped() {
        let alert = UIAlertController(
            title: "Log Out",
            message: "Are you sure you want to log out?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { _ in
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

private final class GradientView: UIView {
    private let gradientLayer = CAGradientLayer()
    private let colors: [UIColor]

    init(colors: [UIColor]) {
        self.colors = colors
        super.init(frame: .zero)
        layer.insertSublayer(gradientLayer, at: 0)
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.colors = colors.map { $0.cgColor }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}
