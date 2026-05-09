import UIKit

/// 用户等级页 - 对应 Android UserLevelActivity
/// 展示当前等级、成长值进度，Level Up Now 跳转充值页。
class UserLevelViewController: UIViewController {

    private let levelGrowthValues = [0, 200, 2400, 4950, 9050, 12800, 21000, 24500, 49500, 59500, 128888]

    private let levelStartLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.bold(16)
        label.textColor = Theme.Colors.primaryYellow
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let levelEndLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.bold(16)
        label.textColor = Theme.Colors.primaryYellow
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let progressBackgroundView: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.Colors.separator
        v.layer.cornerRadius = 6
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let progressFillView: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.Colors.primaryYellow
        v.layer.cornerRadius = 6
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let growthLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.regular(14)
        label.textColor = Theme.Colors.textSecondary
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let levelUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Level Up Now", for: .normal)
        button.setTitleColor(Theme.Colors.darkerBackground, for: .normal)
        button.titleLabel?.font = Theme.Fonts.bold(16)
        button.backgroundColor = Theme.Colors.primaryYellow
        button.layer.cornerRadius = 22
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var fillWidthConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "User Level"
        view.backgroundColor = Theme.Colors.darkBackground
        setupUI()
        setupActions()
        loadUserLevel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadUserLevel()
    }

    private func setupUI() {
        let card = UIView()
        card.backgroundColor = Theme.Colors.cardBackground
        card.layer.cornerRadius = Theme.Dimensions.cornerRadius
        card.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "⭐ Level Growth"
        titleLabel.font = Theme.Fonts.bold(22)
        titleLabel.textColor = Theme.Colors.textPrimary
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(card)
        card.addSubview(titleLabel)
        card.addSubview(levelStartLabel)
        card.addSubview(levelEndLabel)
        card.addSubview(progressBackgroundView)
        progressBackgroundView.addSubview(progressFillView)
        card.addSubview(growthLabel)
        card.addSubview(levelUpButton)

        fillWidthConstraint = progressFillView.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 28),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            levelStartLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 36),
            levelStartLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),

            levelEndLabel.centerYAnchor.constraint(equalTo: levelStartLabel.centerYAnchor),
            levelEndLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),

            progressBackgroundView.topAnchor.constraint(equalTo: levelStartLabel.bottomAnchor, constant: 14),
            progressBackgroundView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            progressBackgroundView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),
            progressBackgroundView.heightAnchor.constraint(equalToConstant: 12),

            progressFillView.leadingAnchor.constraint(equalTo: progressBackgroundView.leadingAnchor),
            progressFillView.topAnchor.constraint(equalTo: progressBackgroundView.topAnchor),
            progressFillView.bottomAnchor.constraint(equalTo: progressBackgroundView.bottomAnchor),
            fillWidthConstraint!,

            growthLabel.topAnchor.constraint(equalTo: progressBackgroundView.bottomAnchor, constant: 16),
            growthLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            growthLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            levelUpButton.topAnchor.constraint(equalTo: growthLabel.bottomAnchor, constant: 32),
            levelUpButton.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 32),
            levelUpButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -32),
            levelUpButton.heightAnchor.constraint(equalToConstant: 44),
            levelUpButton.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -28)
        ])
    }

    private func setupActions() {
        levelUpButton.addTarget(self, action: #selector(levelUpTapped), for: .touchUpInside)
    }

    private func loadUserLevel() {
        let userLevel = UserManager.shared.currentUser?.level ?? MockDataManager.shared.currentUser.level
        let growthValue = estimatedGrowthValue(for: userLevel)
        let currentLevel = calculateLevel(growthValue)
        let nextLevel = min(currentLevel + 1, 10)

        if growthValue == 0 {
            levelStartLabel.text = "L0"
            levelEndLabel.text = "L1"
            growthLabel.text = "Growth Value : 0/200"
            updateProgress(0)
            return
        }

        let currentLevelMinGrowth = currentLevel > 1 ? levelGrowthValues[currentLevel - 1] : 0
        let nextLevelRequiredGrowth = levelGrowthValues[nextLevel]
        let currentLevelProgress = growthValue - currentLevelMinGrowth
        let currentLevelMaxProgress = nextLevelRequiredGrowth - currentLevelMinGrowth
        let progress = currentLevelMaxProgress == 0 ? 1 : CGFloat(currentLevelProgress) / CGFloat(currentLevelMaxProgress)

        levelStartLabel.text = "L\(currentLevel)"
        levelEndLabel.text = "L\(nextLevel)"
        growthLabel.text = "Growth Value : \(growthValue)/\(nextLevelRequiredGrowth)"
        updateProgress(progress)
    }

    private func estimatedGrowthValue(for level: Int) -> Int {
        guard level > 0 else { return 0 }
        let safeLevel = min(level, 10)
        return levelGrowthValues[safeLevel]
    }

    private func calculateLevel(_ growthValue: Int) -> Int {
        if growthValue <= 0 { return 0 }
        for index in stride(from: levelGrowthValues.count - 1, through: 1, by: -1) {
            if growthValue >= levelGrowthValues[index] {
                return index
            }
        }
        return 0
    }

    private func updateProgress(_ progress: CGFloat) {
        view.layoutIfNeeded()
        let clamped = max(0, min(progress, 1))
        fillWidthConstraint?.constant = progressBackgroundView.bounds.width * clamped
    }

    @objc private func levelUpTapped() {
        navigationController?.pushViewController(RechargeViewController(), animated: true)
    }
}
