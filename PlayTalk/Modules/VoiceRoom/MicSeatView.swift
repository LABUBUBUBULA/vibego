import UIKit

/// 麦位视图 - 对应 Android voice room 的单个麦位布局
/// 布局：60x60 头像区域（圆形） + 用户名标签
/// 状态：空位(+图标) / 有人(头像) / 锁定(🔒图标) / 房主(host标签)
class MicSeatView: UIView {

    // MARK: - UI 组件

    /// 头像背景容器（60x60dp 圆形）
    private let avatarContainer: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.Colors.cardBackground
        v.layer.cornerRadius = 30
        v.layer.masksToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// 头像图片（有人时显示）
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 28
        iv.layer.masksToBounds = true
        iv.isHidden = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    /// 状态图标（空位显示"+"，锁定显示"🔒"）
    private let statusIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "ic_room_add")
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    /// 用户名/麦位标签
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.regular(11)
        label.textColor = Theme.Colors.textSecondary
        label.textAlignment = .center
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 房主标识（对应 Android "host" badge）
    private let hostBadge: UILabel = {
        let label = UILabel()
        label.text = "Host"
        label.font = Theme.Fonts.bold(9)
        label.textColor = Theme.Colors.darkerBackground
        label.backgroundColor = Theme.Colors.primaryYellow
        label.textAlignment = .center
        label.layer.cornerRadius = 6
        label.layer.masksToBounds = true
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - 初始化

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 布局

    private func setupUI() {
        addSubview(avatarContainer)
        avatarContainer.addSubview(avatarImageView)
        avatarContainer.addSubview(statusIcon)
        addSubview(nameLabel)
        addSubview(hostBadge)

        NSLayoutConstraint.activate([
            // 头像容器（60x60，居中）
            avatarContainer.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            avatarContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            avatarContainer.widthAnchor.constraint(equalToConstant: 60),
            avatarContainer.heightAnchor.constraint(equalToConstant: 60),

            // 头像图片
            avatarImageView.centerXAnchor.constraint(equalTo: avatarContainer.centerXAnchor),
            avatarImageView.centerYAnchor.constraint(equalTo: avatarContainer.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 56),
            avatarImageView.heightAnchor.constraint(equalToConstant: 56),

            // 状态图标（居中）
            statusIcon.centerXAnchor.constraint(equalTo: avatarContainer.centerXAnchor),
            statusIcon.centerYAnchor.constraint(equalTo: avatarContainer.centerYAnchor),
            statusIcon.widthAnchor.constraint(equalToConstant: 24),
            statusIcon.heightAnchor.constraint(equalToConstant: 24),

            // 用户名
            nameLabel.topAnchor.constraint(equalTo: avatarContainer.bottomAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),

            // 房主标识（头像右下角）
            hostBadge.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor, constant: 2),
            hostBadge.trailingAnchor.constraint(equalTo: avatarContainer.trailingAnchor, constant: 4),
            hostBadge.widthAnchor.constraint(equalToConstant: 32),
            hostBadge.heightAnchor.constraint(equalToConstant: 14)
        ])
    }

    // MARK: - 配置

    /// 配置麦位显示状态
    /// - Parameters:
    ///   - avatarImage: 头像图片名（有人时使用）
    ///   - username: 用户名或麦位标签
    ///   - isHost: 是否为房主位
    ///   - isEmpty: 是否空位
    ///   - isLocked: 是否锁定
    func configure(avatarImage: String, username: String, isHost: Bool, isEmpty: Bool, isLocked: Bool) {
        nameLabel.text = username
        hostBadge.isHidden = !isHost

        if isEmpty {
            // 空位状态
            avatarImageView.isHidden = true
            statusIcon.isHidden = false
            statusIcon.image = isLocked ? UIImage(named: "ic_room_lock") : UIImage(named: "ic_room_add")
            avatarContainer.backgroundColor = Theme.Colors.cardBackground
        } else {
            // 有人状态
            avatarImageView.isHidden = false
            avatarImageView.image = UIImage(named: avatarImage)
            statusIcon.isHidden = true
            avatarContainer.backgroundColor = Theme.Colors.primaryYellow.withAlphaComponent(0.2)
        }
    }
}
