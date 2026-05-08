import UIKit

/// 他人主页 - 对应 Android GameMic 的 UserProfileActivity
/// 布局：背景图 → 头像+昵称+签名 → 关注按钮 → 粉丝/关注统计
class UserProfileViewController: UIViewController {

    // MARK: - 传入数据

    var user: User?

    // MARK: - UI 组件

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.backgroundColor = .clear
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
        title = user?.name ?? "Profile"
        view.backgroundColor = Theme.Colors.darkBackground
        setupUI()
    }

    // MARK: - 界面搭建

    private func setupUI() {
        guard let user = user else { return }

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        // 头像（90x90 圆形）— 使用真实头像图片
        let avatarView = UIImageView()
        avatarView.image = UIImage(named: user.avatarImage)
        avatarView.backgroundColor = Theme.Colors.primaryYellow.withAlphaComponent(0.3)
        avatarView.layer.cornerRadius = 45
        avatarView.layer.masksToBounds = true
        avatarView.layer.borderWidth = 3
        avatarView.layer.borderColor = Theme.Colors.primaryYellow.cgColor
        avatarView.contentMode = .scaleAspectFill
        avatarView.translatesAutoresizingMaskIntoConstraints = false

        // 昵称
        let nameLabel = UILabel()
        nameLabel.text = user.name
        nameLabel.font = Theme.Fonts.bold(24)
        nameLabel.textColor = Theme.Colors.textPrimary
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        // ID
        let idLabel = UILabel()
        idLabel.text = "ID: \(user.id)"
        idLabel.font = Theme.Fonts.regular(14)
        idLabel.textColor = Theme.Colors.textSecondary
        idLabel.textAlignment = .center
        idLabel.translatesAutoresizingMaskIntoConstraints = false

        // 签名
        let bioLabel = UILabel()
        bioLabel.text = user.bio
        bioLabel.font = Theme.Fonts.regular(14)
        bioLabel.textColor = Theme.Colors.textSecondary
        bioLabel.textAlignment = .center
        bioLabel.numberOfLines = 3
        bioLabel.translatesAutoresizingMaskIntoConstraints = false

        // 关注按钮
        let followButton = UIButton(type: .system)
        followButton.setTitle(user.isFollowing ? "Following" : "Follow", for: .normal)
        followButton.setTitleColor(user.isFollowing ? Theme.Colors.textSecondary : Theme.Colors.darkerBackground, for: .normal)
        followButton.titleLabel?.font = Theme.Fonts.bold(14)
        followButton.backgroundColor = user.isFollowing ? Theme.Colors.cardBackground : Theme.Colors.primaryYellow
        followButton.layer.cornerRadius = 20
        followButton.translatesAutoresizingMaskIntoConstraints = false

        // 等级
        let levelLabel = UILabel()
        levelLabel.text = "⭐ Lv.\(user.level)"
        levelLabel.font = Theme.Fonts.medium(14)
        levelLabel.textColor = Theme.Colors.primaryYellow
        levelLabel.textAlignment = .center
        levelLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(idLabel)
        contentView.addSubview(bioLabel)
        contentView.addSubview(followButton)
        contentView.addSubview(levelLabel)

        NSLayoutConstraint.activate([
            avatarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            avatarView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 90),
            avatarView.heightAnchor.constraint(equalToConstant: 90),

            nameLabel.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 12),
            nameLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            levelLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            levelLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            idLabel.topAnchor.constraint(equalTo: levelLabel.bottomAnchor, constant: 4),
            idLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            bioLabel.topAnchor.constraint(equalTo: idLabel.bottomAnchor, constant: 12),
            bioLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            bioLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),

            followButton.topAnchor.constraint(equalTo: bioLabel.bottomAnchor, constant: 20),
            followButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            followButton.widthAnchor.constraint(equalToConstant: 140),
            followButton.heightAnchor.constraint(equalToConstant: 40),
            followButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
}
