import UIKit

/// 兴趣选择页 - 对应 Android GameMic 的 SelectInterestsActivity
/// 4个游戏卡片可选（最多2个）：Mobile Legends / Roblox / Brawl Stars / Among Us
/// 选完后保存用户资料，跳转主页
class SelectInterestsViewController: UIViewController {

    // MARK: - 传入数据（从完善资料页传来）

    var nickname: String = ""
    var gender: String = "male"
    var avatarUri: String?

    // MARK: - 状态

    /// 已选中的游戏列表（最多2个，对应 Android selectedGames）
    private var selectedGames: [String] = []
    /// 最大可选数量
    private let maxSelection = 2

    /// 4个游戏数据
    private let games: [(name: String, image: String)] = [
        ("Mobile Legends", "ph_pubg"),
        ("Roblox", "ph_minecraft"),
        ("Brawl Stars", "ph_fortnite"),
        ("Among Us", "ph_thesims")
    ]

    // MARK: - UI 组件

    /// 提示文字
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Select your interests"
        label.font = Theme.Fonts.bold(24)
        label.textColor = Theme.Colors.textPrimary
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 副标题
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Choose up to 2 games"
        label.font = Theme.Fonts.regular(14)
        label.textColor = Theme.Colors.textSecondary
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 游戏卡片网格（2x2）
    private let gridStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 16
        sv.distribution = .fillEqually
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    /// 开始按钮（对应 Android btn_start）
    private let startButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Start", for: .normal)
        btn.setTitleColor(Theme.Colors.darkerBackground, for: .normal)
        btn.titleLabel?.font = Theme.Fonts.bold(16)
        btn.backgroundColor = Theme.Colors.primaryYellow
        btn.layer.cornerRadius = 25
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    /// 跳过按钮（对应 Android tv_skip）
    private let skipButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Skip", for: .normal)
        btn.setTitleColor(Theme.Colors.textSecondary, for: .normal)
        btn.titleLabel?.font = Theme.Fonts.regular(14)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    /// 游戏卡片视图数组（用于更新选中状态）
    private var gameCardViews: [UIView] = []
    /// 游戏勾选图标数组
    private var checkIcons: [UIImageView] = []

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Interests"
        view.backgroundColor = Theme.Colors.darkBackground
        setupUI()
        setupActions()
    }

    // MARK: - 界面搭建

    private func setupUI() {
        navigationItem.leftBarButtonItem = makeAppBackButton(action: #selector(backTapped))

        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(gridStack)
        view.addSubview(startButton)
        view.addSubview(skipButton)

        // 创建 2x2 网格
        let topRow = UIStackView()
        topRow.axis = .horizontal
        topRow.spacing = 16
        topRow.distribution = .fillEqually

        let bottomRow = UIStackView()
        bottomRow.axis = .horizontal
        bottomRow.spacing = 16
        bottomRow.distribution = .fillEqually

        for (index, game) in games.enumerated() {
            let card = createGameCard(name: game.name, image: game.image, tag: index)
            if index < 2 {
                topRow.addArrangedSubview(card)
            } else {
                bottomRow.addArrangedSubview(card)
            }
        }

        gridStack.addArrangedSubview(topRow)
        gridStack.addArrangedSubview(bottomRow)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // 游戏卡片网格
            gridStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            gridStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            gridStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            gridStack.heightAnchor.constraint(equalToConstant: 320),

            // 开始按钮
            startButton.bottomAnchor.constraint(equalTo: skipButton.topAnchor, constant: -16),
            startButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            startButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            startButton.heightAnchor.constraint(equalToConstant: 50),

            // 跳过按钮
            skipButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            skipButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    /// 创建游戏卡片（对应 Android card_pubg 等 4 个卡片）
    /// 包含：游戏封面图 + 游戏名 + 勾选图标 + 半透明遮罩
    private func createGameCard(name: String, image: String, tag: Int) -> UIView {
        let card = UIView()
        card.backgroundColor = Theme.Colors.cardBackground
        card.layer.cornerRadius = 16
        card.layer.masksToBounds = true
        card.tag = tag

        // 游戏封面图
        let imageView = UIImageView()
        imageView.image = UIImage(named: image)
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(imageView)

        // 游戏名称
        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = Theme.Fonts.bold(16)
        nameLabel.textColor = .white
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(nameLabel)

        // 勾选图标（对应 Android iv_pubg_check 等）
        let checkIcon = UIImageView()
        checkIcon.image = UIImage(named: "ic_checkbox_checked")
        checkIcon.isHidden = true
        checkIcon.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(checkIcon)
        checkIcons.append(checkIcon)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: card.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: card.bottomAnchor),

            nameLabel.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),

            checkIcon.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),
            checkIcon.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8),
            checkIcon.widthAnchor.constraint(equalToConstant: 24),
            checkIcon.heightAnchor.constraint(equalToConstant: 24)
        ])

        // 点击手势
        let tap = UITapGestureRecognizer(target: self, action: #selector(gameCardTapped(_:)))
        card.addGestureRecognizer(tap)
        card.isUserInteractionEnabled = true
        gameCardViews.append(card)

        return card
    }

    // MARK: - 事件

    private func setupActions() {
        startButton.addTarget(self, action: #selector(startTapped), for: .touchUpInside)
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    /// 游戏卡片点击 - 切换选中状态（对应 Android toggle 逻辑，最多2个）
    @objc private func gameCardTapped(_ gesture: UITapGestureRecognizer) {
        guard let tag = gesture.view?.tag else { return }
        let gameName = games[tag].name

        if selectedGames.contains(gameName) {
            // 取消选中
            selectedGames.removeAll { $0 == gameName }
        } else {
            // 检查是否超过最大选择数（对应 Android "You can select up to 2 games"）
            guard selectedGames.count < maxSelection else {
                showToast("You can select up to 2 games")
                return
            }
            selectedGames.append(gameName)
        }

        updateSelectionUI()
    }

    /// 更新所有卡片的选中状态 UI
    private func updateSelectionUI() {
        for (index, game) in games.enumerated() {
            let isSelected = selectedGames.contains(game.name)
            if index < checkIcons.count {
                checkIcons[index].isHidden = !isSelected
            }
            if index < gameCardViews.count {
                gameCardViews[index].alpha = isSelected ? 0.7 : 1.0
            }
        }
    }

    /// 开始按钮 - 保存资料并进入主页
    @objc private func startTapped() {
        saveProfileAndNavigate()
    }

    /// 跳过按钮 - 不选兴趣直接进入主页（对应 Android tv_skip）
    @objc private func skipTapped() {
        saveProfileAndNavigate()
    }

    /// 保存用户资料并跳转主页（对应 Android saveUserProfile → MainActivity）
    private func saveProfileAndNavigate() {
        let interests = selectedGames.joined(separator: ",")

        // 更新用户资料（对应 Android UserManager.updateUserProfile）
        UserManager.shared.updateUserProfile(
            nickname: nickname,
            gender: gender,
            avatarUri: avatarUri,
            country: "",
            countryFlag: "",
            interests: interests
        )

        showToast("Welcome to VibeGo!")

        // 延迟跳转主页
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.navigateToMain()
        }
    }

    /// 跳转主页
    private func navigateToMain() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        window.rootViewController = AppNavigationController(rootViewController: MainTabBarController())
        window.makeKeyAndVisible()
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
    }

}
