import UIKit

/// 个人主页 - Mine 的 Homepage 和所有用户头像/消息入口都复用这个页面
class UserProfileViewController: UIViewController {

    var user: User?
    private var primaryActionButton: UIButton?

    private let profileBackgroundColor = UIColor(hex: "#191925")

    private let baseGiftCounts = [18, 8, 25, 13, 15, 5, 3, 4, 8, 11, 7, 21]
    private let baseGiftWallImageNames = ["gift_10", "gift_2", "gift_4", "gift_12", "gift_5", "gift_7", "gift_19", "gift_9", "gift_6", "gift_1", "gift_8", "gift_17"]

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

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        edgesForExtendedLayout = .all
        extendedLayoutIncludesOpaqueBars = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = profileBackgroundColor
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        scrollView.contentInsetAdjustmentBehavior = .never
        refreshUserState()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if navigationController?.topViewController !== self {
            navigationController?.setNavigationBarHidden(false, animated: animated)
        }
    }

    private func setupUI() {
        guard let user = user else { return }

        // ── 背景图直接钉到 view.topAnchor，彻底绕开 scrollView inset 问题 ──
        let heroBg = UIImageView(image: UIImage(named: profileBackgroundImage(for: user))
                                 ?? UIImage(named: "ic_mine_backpic")
                                 ?? UIImage(named: "bg_mine"))
        heroBg.contentMode = .scaleAspectFill
        heroBg.clipsToBounds = true
        heroBg.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(heroBg)

        let heroDim = ProfileGradientView(
            colors: [.clear, .clear, profileBackgroundColor.withAlphaComponent(0.92)],
            startPoint: CGPoint(x: 0.5, y: 0),
            endPoint: CGPoint(x: 0.5, y: 1),
            locations: [0, 0.55, 1]
        )
        heroDim.isUserInteractionEnabled = false
        heroDim.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(heroDim)

        // ── 其余内容区（深色背景）──
        let pageBackground = UIView()
        pageBackground.backgroundColor = profileBackgroundColor
        pageBackground.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageBackground)

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        let header = createHeader(user)
        let profileInfo = createProfileInfo(user)
        let actions = createActionBar(user)
        let giftWall = createGiftWall(user)

        contentView.addSubview(header)
        contentView.addSubview(profileInfo)
        contentView.addSubview(actions)
        contentView.addSubview(giftWall)

        NSLayoutConstraint.activate([
            // 背景图：从屏幕最顶端开始，固定 276pt 高
            heroBg.topAnchor.constraint(equalTo: view.topAnchor),
            heroBg.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            heroBg.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            heroBg.heightAnchor.constraint(equalToConstant: 276),

            heroDim.topAnchor.constraint(equalTo: view.topAnchor),
            heroDim.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            heroDim.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            heroDim.heightAnchor.constraint(equalToConstant: 276),

            pageBackground.topAnchor.constraint(equalTo: view.topAnchor, constant: 276),
            pageBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageBackground.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            // header 透明占位，高度与背景图一致
            header.topAnchor.constraint(equalTo: contentView.topAnchor),
            header.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 276),

            profileInfo.topAnchor.constraint(equalTo: header.bottomAnchor),
            profileInfo.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            profileInfo.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            actions.topAnchor.constraint(equalTo: profileInfo.bottomAnchor, constant: 16),
            actions.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 22),
            actions.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -22),
            actions.heightAnchor.constraint(equalToConstant: 42),

            giftWall.topAnchor.constraint(equalTo: actions.bottomAnchor, constant: 18),
            giftWall.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            giftWall.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            giftWall.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -80)
        ])
    }

    private func createHeader(_ user: User) -> UIView {
        // header 仅作透明占位 + 返回键容器，背景图已直接钉在 view 上
        let header = UIView()
        header.backgroundColor = .clear
        header.translatesAutoresizingMaskIntoConstraints = false

        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .white
        backButton.contentHorizontalAlignment = .left
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(backButton)

        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 22),
            backButton.topAnchor.constraint(equalTo: header.topAnchor, constant: 56),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40)
        ])

        return header
    }

    private func createProfileInfo(_ user: User) -> UIView {
        let container = UIView()
        container.backgroundColor = profileBackgroundColor
        container.translatesAutoresizingMaskIntoConstraints = false

        let avatar = UIImageView(image: user.displayAvatarImage ?? UIImage(named: user.avatarImage))
        avatar.contentMode = .scaleAspectFill
        avatar.layer.cornerRadius = 45
        avatar.layer.masksToBounds = true
        avatar.layer.borderWidth = 2
        avatar.layer.borderColor = profileBackgroundColor.cgColor
        avatar.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(avatar)

        let name = UILabel()
        name.text = user.name
        name.font = Theme.Fonts.bold(20)
        name.textColor = .white
        name.adjustsFontSizeToFitWidth = true
        name.minimumScaleFactor = 0.72
        name.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(name)

        let gender = makeImageIcon(imageName: user.gender == "female" ? "ic_gender_female" : "ic_gender_male", fallbackSystemName: user.gender == "female" ? "venus" : "mars")
        container.addSubview(gender)

        let level = makeLevelBadge(level: user.level)
        container.addSubview(level)

        let id = UILabel()
        id.text = "ID:\(user.id)"
        id.font = Theme.Fonts.regular(14)
        id.textColor = .white
        id.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(id)

        let game = makeTextPill(text: user.interests.split(separator: ",").first.map(String.init) ?? "PUBG")
        container.addSubview(game)

        let bio = UILabel()
        bio.text = user.bio.isEmpty ? "Welcome to GameMic! Let's game together!" : user.bio
        bio.font = Theme.Fonts.regular(16)
        bio.textColor = .white
        bio.numberOfLines = 0
        bio.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bio)

        NSLayoutConstraint.activate([
            avatar.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            avatar.topAnchor.constraint(equalTo: container.topAnchor, constant: -48),
            avatar.widthAnchor.constraint(equalToConstant: 90),
            avatar.heightAnchor.constraint(equalToConstant: 90),

            name.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 16),
            name.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            name.trailingAnchor.constraint(lessThanOrEqualTo: gender.leadingAnchor, constant: -8),

            gender.leadingAnchor.constraint(equalTo: name.trailingAnchor, constant: 8),
            gender.centerYAnchor.constraint(equalTo: name.centerYAnchor),
            gender.widthAnchor.constraint(equalToConstant: 24),
            gender.heightAnchor.constraint(equalToConstant: 24),

            level.leadingAnchor.constraint(equalTo: gender.trailingAnchor, constant: 6),
            level.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -16),
            level.centerYAnchor.constraint(equalTo: name.centerYAnchor),
            level.widthAnchor.constraint(equalToConstant: 50),
            level.heightAnchor.constraint(equalToConstant: 32),

            id.leadingAnchor.constraint(equalTo: name.leadingAnchor),
            id.topAnchor.constraint(equalTo: name.bottomAnchor, constant: 6),

            game.leadingAnchor.constraint(equalTo: id.trailingAnchor, constant: 10),
            game.centerYAnchor.constraint(equalTo: id.centerYAnchor),
            game.heightAnchor.constraint(equalToConstant: 26),

            bio.topAnchor.constraint(equalTo: avatar.bottomAnchor, constant: 18),
            bio.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 26),
            bio.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -26),
            bio.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func createActionBar(_ user: User) -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false

        let isCurrentUser = user.id == UserManager.shared.currentUser?.id
        let primary = UIButton(type: .system)
        primary.titleLabel?.font = Theme.Fonts.bold(14)
        primary.layer.cornerRadius = 21
        primary.addTarget(self, action: isCurrentUser ? #selector(editProfileTapped) : #selector(followTapped), for: .touchUpInside)
        primaryActionButton = primary
        updatePrimaryActionButton(primary, for: user)

        let chat = UIButton(type: .system)
        chat.setTitle(isCurrentUser ? "My Chat" : "Chat", for: .normal)
        chat.setTitleColor(.white, for: .normal)
        chat.titleLabel?.font = Theme.Fonts.bold(14)
        chat.backgroundColor = Theme.Colors.cardBackground
        chat.layer.cornerRadius = 21
        chat.addTarget(self, action: #selector(chatTapped), for: .touchUpInside)

        stack.addArrangedSubview(primary)
        stack.addArrangedSubview(chat)
        return stack
    }

    private func createGiftWall(_ user: User) -> UIView {
        let container = UIView()
        container.backgroundColor = Theme.Colors.cardBackground.withAlphaComponent(0.55)
        container.layer.cornerRadius = 20
        container.translatesAutoresizingMaskIntoConstraints = false

        let title = UILabel()
        title.text = "\(user.name)'s Gift Wall"
        title.font = Theme.Fonts.bold(20)
        title.textColor = .white
        title.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(title)

        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 20
        grid.distribution = .fillEqually
        grid.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(grid)

        let gifts = profileGiftWall(for: user)
        var giftIndex = 0
        for _ in 0..<3 {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 18
            row.distribution = .fillEqually
            grid.addArrangedSubview(row)

            for _ in 0..<4 {
                if giftIndex < gifts.count {
                    row.addArrangedSubview(makeGiftItem(imageName: gifts[giftIndex].imageName, count: gifts[giftIndex].count))
                } else {
                    let spacer = UIView()
                    spacer.translatesAutoresizingMaskIntoConstraints = false
                    row.addArrangedSubview(spacer)
                }
                giftIndex += 1
            }
        }

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            title.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            title.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            grid.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 22),
            grid.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            grid.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            grid.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -24)
        ])

        return container
    }

    private func profileBackgroundImage(for user: User) -> String {
        if user.id == UserManager.shared.currentUser?.id, UIImage(named: "ic_mine_backpic") != nil {
            return "ic_mine_backpic"
        }
        if UIImage(named: user.backgroundImage) != nil, user.backgroundImage != "bg_mine" {
            return user.backgroundImage
        }
        let backgrounds = ["ic_mine_backpic", "minecraft_1", "fortnite_1", "thesims_1", "bg_room_background"]
        return backgrounds[abs(user.id) % backgrounds.count]
    }

    private func profileGiftWall(for user: User) -> [(imageName: String, count: Int)] {
        if user.id == UserManager.shared.currentUser?.id,
           !UserManager.shared.isPresetAccountUserId(user.id) {
            return []
        }

        let offset = abs(user.id) % baseGiftWallImageNames.count
        let visibleCount = 6 + abs(user.id) % 7
        return (0..<visibleCount).map { index in
            let sourceIndex = (index + offset) % baseGiftWallImageNames.count
            let count = baseGiftCounts[sourceIndex] + (abs(user.id) % 5) * (index % 3 + 1)
            return (baseGiftWallImageNames[sourceIndex], count)
        }
    }

    private func makeTextPill(text: String) -> UIView {
        let pill = ProfileGradientView(colors: [UIColor(hex: "#65C8FF"), UIColor(hex: "#4B78FF")])
        pill.layer.cornerRadius = 13
        pill.clipsToBounds = true
        pill.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = text
        label.font = Theme.Fonts.bold(11)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        pill.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -10),
            label.centerYAnchor.constraint(equalTo: pill.centerYAnchor)
        ])
        return pill
    }

    private func makeImageIcon(imageName: String, fallbackSystemName: String) -> UIView {
        let imageView = UIImageView(image: UIImage(named: imageName) ?? UIImage(systemName: fallbackSystemName))
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }

    private func makeLevelBadge(level: Int) -> UIView {
        let imageName = "bg_level_\(min(max(level, 1), 10))"
        let imageView = UIImageView(image: UIImage(named: imageName) ?? UIImage(named: "bg_level_1"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }

    private func makeGiftItem(imageName: String, count: Int) -> UIView {
        let item = UIView()
        item.translatesAutoresizingMaskIntoConstraints = false

        let imageView = UIImageView(image: UIImage(named: imageName))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        item.addSubview(imageView)

        let countLabel = UILabel()
        countLabel.text = "x\(count)"
        countLabel.font = Theme.Fonts.medium(14)
        countLabel.textColor = .white
        countLabel.textAlignment = .center
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        item.addSubview(countLabel)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: item.topAnchor),
            imageView.centerXAnchor.constraint(equalTo: item.centerXAnchor),
            imageView.widthAnchor.constraint(equalTo: item.widthAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 52),

            countLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            countLabel.leadingAnchor.constraint(equalTo: item.leadingAnchor),
            countLabel.trailingAnchor.constraint(equalTo: item.trailingAnchor),
            countLabel.bottomAnchor.constraint(equalTo: item.bottomAnchor)
        ])
        return item
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
        if navigationController == nil {
            dismiss(animated: true)
        }
    }

    private func refreshUserState() {
        guard let user else { return }
        let syncedUser = MockDataManager.shared.userWithSyncedFollowState(user)
        self.user = syncedUser
        if let primaryActionButton {
            updatePrimaryActionButton(primaryActionButton, for: syncedUser)
        }
    }

    private func updatePrimaryActionButton(_ button: UIButton, for user: User) {
        let isCurrentUser = user.id == UserManager.shared.currentUser?.id
        let isFollowing = MockDataManager.shared.isFollowing(userId: user.id)
        button.setTitle(isCurrentUser ? "Edit Profile" : (isFollowing ? "Following" : "Follow"), for: .normal)
        button.setTitleColor(isCurrentUser ? .black : .white, for: .normal)
        button.backgroundColor = isCurrentUser ? Theme.Colors.primaryYellow : (isFollowing ? UIColor(hex: "#343545") : UIColor(hex: "#5A86FF"))
    }

    @objc private func editProfileTapped() {
        pushAppViewController(EditProfileViewController(), animated: true)
    }

    @objc private func followTapped() {
        guard let user else { return }
        let nextState = !MockDataManager.shared.isFollowing(userId: user.id)
        MockDataManager.shared.setFollowing(userId: user.id, isFollowing: nextState)
        refreshUserState()
        showToast(nextState ? "Followed" : "Unfollowed")
    }

    @objc private func chatTapped() {
        guard let user else { return }
        let vc = ChatViewController()
        vc.chatUser = Message(
            userId: user.id,
            avatarImage: user.displayAvatar,
            name: user.name,
            lastMessage: "",
            time: "",
            unreadCount: 0,
            timestamp: Date().timeIntervalSince1970,
            gender: user.gender,
            countryFlag: "",
            level: user.level,
            bio: user.bio
        )
        pushAppViewController(vc, animated: true)
    }
}

private final class ProfileGradientView: UIView {
    private let gradientLayer = CAGradientLayer()

    init(colors: [UIColor], startPoint: CGPoint = CGPoint(x: 0, y: 0.5), endPoint: CGPoint = CGPoint(x: 1, y: 0.5), locations: [NSNumber]? = nil) {
        super.init(frame: .zero)
        layer.insertSublayer(gradientLayer, at: 0)
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        gradientLayer.locations = locations
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
