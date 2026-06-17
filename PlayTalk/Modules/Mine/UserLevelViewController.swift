import UIKit

/// 用户等级页 - 对应 Android UserLevelActivity
class UserLevelViewController: UIViewController {

    private let levelGrowthValues = [0, 200, 2400, 4950, 9050, 12800, 21000, 24500, 49500, 59500, 128888]
    private let rights = ["Member Logo", "Member Logo", "Extra 3%", "Extra 5%", "Extra 7%", "Extra 9%", "Extra 11%", "Extra 13%", "Extra 15%", "Extra 17%"]

    private let user = UserManager.shared.currentUser ?? MockDataManager.shared.currentUser

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.backgroundColor = .clear
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let contentView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let avatarView: UIImageView = {
        let iv = UIImageView()
        iv.layer.cornerRadius = 24
        iv.layer.masksToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.bold(18)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let levelStartLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.regular(12)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let levelEndLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.regular(12)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let progressBackgroundView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.28)
        v.layer.cornerRadius = 4
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let progressFillView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 4
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let growthLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.regular(12)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let levelUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Level Up Now", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = Theme.Fonts.medium(12)
        button.layer.cornerRadius = 16
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var progressWidthConstraint: NSLayoutConstraint?
    private var levelUpGradient: CAGradientLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "My Level"
        view.backgroundColor = Theme.Colors.darkBackground
        setupUI()
        setupActions()
        loadUserLevel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadUserLevel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        levelUpGradient?.frame = levelUpButton.bounds
        updateProgressWidth()
    }

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])

        contentView.addArrangedSubview(makeLevelCard())
        contentView.addArrangedSubview(makeRuleTitle())
        contentView.addArrangedSubview(makeRuleLabel("1. The so-called title of your job and the responsibilities you undertake are not to take it lightly, but to look at it clearly"))
        contentView.addArrangedSubview(makeRuleLabel("2. If you upgrade from L0 to L3, you will get an additional 3% of gold coins. If your growth value is not enough to upgrade to L4, you will still get an additional 3% for your next recharge"))
        contentView.addArrangedSubview(makeLevelTable())
    }

    private func makeLevelCard() -> UIView {
        let card = UIImageView(image: UIImage(named: "bg_level_big"))
        card.isUserInteractionEnabled = true
        card.contentMode = .scaleToFill
        card.translatesAutoresizingMaskIntoConstraints = false
        card.heightAnchor.constraint(equalToConstant: 120).isActive = true

        avatarView.image = user.displayAvatarImage ?? UIImage(named: user.avatarImage)
        nameLabel.text = user.name
        applyLevelUpGradient()

        card.addSubview(avatarView)
        card.addSubview(nameLabel)
        card.addSubview(levelUpButton)
        card.addSubview(levelStartLabel)
        card.addSubview(levelEndLabel)
        card.addSubview(progressBackgroundView)
        progressBackgroundView.addSubview(progressFillView)
        card.addSubview(growthLabel)

        progressWidthConstraint = progressFillView.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            avatarView.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            avatarView.widthAnchor.constraint(equalToConstant: 48),
            avatarView.heightAnchor.constraint(equalToConstant: 48),

            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 16),
            nameLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: levelUpButton.leadingAnchor, constant: -12),

            levelUpButton.topAnchor.constraint(equalTo: card.topAnchor, constant: 26),
            levelUpButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),
            levelUpButton.heightAnchor.constraint(equalToConstant: 32),
            levelUpButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 112),

            levelStartLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            levelStartLabel.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 18),

            levelEndLabel.trailingAnchor.constraint(equalTo: levelUpButton.leadingAnchor, constant: 6),
            levelEndLabel.centerYAnchor.constraint(equalTo: levelStartLabel.centerYAnchor),

            progressBackgroundView.leadingAnchor.constraint(equalTo: levelStartLabel.trailingAnchor, constant: 4),
            progressBackgroundView.trailingAnchor.constraint(equalTo: levelEndLabel.leadingAnchor, constant: -4),
            progressBackgroundView.centerYAnchor.constraint(equalTo: levelStartLabel.centerYAnchor),
            progressBackgroundView.heightAnchor.constraint(equalToConstant: 8),

            progressFillView.leadingAnchor.constraint(equalTo: progressBackgroundView.leadingAnchor),
            progressFillView.topAnchor.constraint(equalTo: progressBackgroundView.topAnchor),
            progressFillView.bottomAnchor.constraint(equalTo: progressBackgroundView.bottomAnchor),
            progressWidthConstraint!,

            growthLabel.topAnchor.constraint(equalTo: progressBackgroundView.bottomAnchor, constant: 6),
            growthLabel.leadingAnchor.constraint(equalTo: progressBackgroundView.leadingAnchor),
            growthLabel.trailingAnchor.constraint(equalTo: progressBackgroundView.trailingAnchor)
        ])

        return card
    }

    private func makeRuleTitle() -> UILabel {
        let label = UILabel()
        label.text = "Level Rule"
        label.font = Theme.Fonts.bold(18)
        label.textColor = Theme.Colors.textPrimary
        return label
    }

    private func makeRuleLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = Theme.Fonts.regular(12)
        label.textColor = Theme.Colors.textSecondary
        label.numberOfLines = 0
        return label
    }

    private func makeLevelTable() -> UIView {
        let table = UIStackView()
        table.axis = .vertical
        table.spacing = 0
        table.backgroundColor = Theme.Colors.cardBackground
        table.layer.cornerRadius = Theme.Dimensions.cornerRadius
        table.clipsToBounds = true

        table.addArrangedSubview(makeTableRow(levelImage: nil, growth: "Growth Value", right: "Rights", isHeader: true))
        addSeparator(to: table)

        for level in 1...10 {
            table.addArrangedSubview(makeTableRow(levelImage: "bg_level_\(level)", growth: "\(levelGrowthValues[level])", right: rights[level - 1], isHeader: false))
            if level < 10 { addSeparator(to: table) }
        }

        return table
    }

    private func makeTableRow(levelImage: String?, growth: String, right: String, isHeader: Bool) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.distribution = .fillEqually
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        row.heightAnchor.constraint(equalToConstant: isHeader ? 48 : 60).isActive = true

        if let levelImage {
            let imageView = UIImageView(image: UIImage(named: levelImage))
            imageView.contentMode = .scaleAspectFit
            row.addArrangedSubview(imageView)
        } else {
            row.addArrangedSubview(makeCellLabel("Level", isHeader: true))
        }
        row.addArrangedSubview(makeCellLabel(growth, isHeader: isHeader))
        row.addArrangedSubview(makeCellLabel(right, isHeader: isHeader))
        return row
    }

    private func makeCellLabel(_ text: String, isHeader: Bool) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = isHeader ? Theme.Fonts.regular(14) : Theme.Fonts.regular(12)
        label.textColor = isHeader ? Theme.Colors.textSecondary : Theme.Colors.textPrimary
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }

    private func addSeparator(to stack: UIStackView) {
        let separator = UIView()
        separator.backgroundColor = Theme.Colors.separator
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        stack.addArrangedSubview(separator)
    }

    private func applyLevelUpGradient() {
        let gradient = CAGradientLayer()
        gradient.colors = [Theme.Colors.primaryPurple.cgColor, UIColor(hex: "#C084FC").cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 1)
        gradient.endPoint = CGPoint(x: 1, y: 0)
        levelUpButton.layer.insertSublayer(gradient, at: 0)
        levelUpGradient = gradient
    }

    private var currentProgress: CGFloat = 0

    private func loadUserLevel() {
        let userLevel = UserManager.shared.currentUser?.level ?? MockDataManager.shared.currentUser.level
        let growthValue = estimatedGrowthValue(for: userLevel)
        let currentLevel = calculateLevel(growthValue)
        let nextLevel = min(currentLevel + 1, 10)

        if growthValue == 0 {
            levelStartLabel.text = "L0"
            levelEndLabel.text = "L1"
            growthLabel.text = "Growth Value : 0/\(levelGrowthValues[1])"
            currentProgress = 0
            updateProgressWidth()
            return
        }

        let currentLevelMinGrowth = currentLevel > 1 ? levelGrowthValues[currentLevel - 1] : 0
        let nextLevelRequiredGrowth = levelGrowthValues[nextLevel]
        let currentLevelProgress = growthValue - currentLevelMinGrowth
        let currentLevelMaxProgress = nextLevelRequiredGrowth - currentLevelMinGrowth
        currentProgress = currentLevelMaxProgress == 0 ? 1 : CGFloat(currentLevelProgress) / CGFloat(currentLevelMaxProgress)

        levelStartLabel.text = "L\(currentLevel)"
        levelEndLabel.text = "L\(nextLevel)"
        growthLabel.text = "Growth Value : \(growthValue)/\(nextLevelRequiredGrowth)"
        updateProgressWidth()
    }

    private func estimatedGrowthValue(for level: Int) -> Int {
        guard level > 0 else { return 0 }
        return levelGrowthValues[min(level, 10)]
    }

    private func calculateLevel(_ growthValue: Int) -> Int {
        if growthValue <= 0 { return 0 }
        for index in stride(from: levelGrowthValues.count - 1, through: 1, by: -1) {
            if growthValue >= levelGrowthValues[index] { return index }
        }
        return 0
    }

    private func updateProgressWidth() {
        let clamped = max(0, min(currentProgress, 1))
        progressWidthConstraint?.constant = progressBackgroundView.bounds.width * clamped
    }

    private func setupActions() {
        levelUpButton.addTarget(self, action: #selector(levelUpTapped), for: .touchUpInside)
    }

    @objc private func levelUpTapped() {
        pushAppViewController(RechargeViewController(), animated: true)
    }
}
