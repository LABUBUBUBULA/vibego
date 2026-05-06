import UIKit

/// 消息列表 Cell - 对应 Android 的 item_message.xml
/// 布局：圆形头像(56dp) + 未读角标 | 昵称 + 最后消息 | 时间
class MessageCell: UITableViewCell {
    static let reuseId = "MessageCell"

    // MARK: - UI 组件

    /// 头像容器（56x56dp 圆形，对应 Android）
    private let avatarView: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.Colors.primaryYellow.withAlphaComponent(0.3)
        v.layer.cornerRadius = 28
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// 头像占位文字
    private let avatarLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.bold(18)
        label.textColor = Theme.Colors.primaryYellow
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 未读角标（20x20dp 红色圆点，在头像右上角）
    private let unreadBadge: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.bold(10)
        label.textColor = .white
        label.backgroundColor = .systemRed
        label.textAlignment = .center
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    /// 昵称（16sp bold 白色）
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.bold(16)
        label.textColor = Theme.Colors.textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 最后消息预览（14sp 灰色，单行省略）
    private let lastMessageLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.regular(14)
        label.textColor = Theme.Colors.textSecondary
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 时间（12sp 灰色，右上角）
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.regular(12)
        label.textColor = Theme.Colors.textSecondary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - 初始化

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 布局

    private func setupUI() {
        contentView.addSubview(avatarView)
        avatarView.addSubview(avatarLabel)
        contentView.addSubview(unreadBadge)
        contentView.addSubview(nameLabel)
        contentView.addSubview(lastMessageLabel)
        contentView.addSubview(timeLabel)

        NSLayoutConstraint.activate([
            // 头像（56x56dp）
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 56),
            avatarView.heightAnchor.constraint(equalToConstant: 56),

            avatarLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),

            // 未读角标（头像右上角，20x20dp）
            unreadBadge.topAnchor.constraint(equalTo: avatarView.topAnchor, constant: -4),
            unreadBadge.trailingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 4),
            unreadBadge.widthAnchor.constraint(equalToConstant: 20),
            unreadBadge.heightAnchor.constraint(equalToConstant: 20),

            // 昵称
            nameLabel.topAnchor.constraint(equalTo: avatarView.topAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: -8),

            // 最后消息
            lastMessageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            lastMessageLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            lastMessageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // 时间
            timeLabel.topAnchor.constraint(equalTo: nameLabel.topAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    // MARK: - 数据绑定

    /// 绑定消息数据到 Cell
    func configure(with message: Message) {
        // 头像用名字首字母
        avatarLabel.text = String(message.name.prefix(1))
        nameLabel.text = message.name
        lastMessageLabel.text = message.lastMessage
        timeLabel.text = message.time

        // 未读角标显示
        if message.unreadCount > 0 {
            unreadBadge.isHidden = false
            unreadBadge.text = "\(message.unreadCount)"
        } else {
            unreadBadge.isHidden = true
        }
    }
}
