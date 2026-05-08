import UIKit

/// 语音房卡片 Cell - 对应 Android 的 item_game_discussion.xml
/// 布局：左侧封面(84x84) | 右侧标题+热度+标签+描述
class RoomCell: UITableViewCell {
    static let reuseId = "RoomCell"

    // MARK: - UI 组件

    /// 卡片容器（对应 Android CardView，16dp 圆角，深色背景）
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.Colors.cardBackground
        v.layer.cornerRadius = 16
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// 房间封面图片（84x84，12dp 圆角）
    private let coverImageView: UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = Theme.Colors.primaryYellow.withAlphaComponent(0.2)
        iv.layer.cornerRadius = 12
        iv.layer.masksToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    /// 房间标题（最多1行省略）
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.bold(15)
        label.textColor = Theme.Colors.textPrimary
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 热度标签（火焰图标 + 数字，黄色）
    private let hotLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.medium(12)
        label.textColor = Theme.Colors.primaryYellow
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 游戏分类标签（如 "PUBG"，有色背景）
    private let gameTagLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.medium(11)
        label.textColor = Theme.Colors.primaryYellow
        label.backgroundColor = Theme.Colors.primaryYellow.withAlphaComponent(0.15)
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 房间描述（最多2行，灰色，12sp）
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.regular(12)
        label.textColor = Theme.Colors.textSecondary
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 在线人数
    private let memberCountLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.regular(11)
        label.textColor = Theme.Colors.primaryGreen
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
        contentView.addSubview(containerView)
        containerView.addSubview(coverImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(hotLabel)
        containerView.addSubview(gameTagLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(memberCountLabel)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            coverImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            coverImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            coverImageView.widthAnchor.constraint(equalToConstant: 84),
            coverImageView.heightAnchor.constraint(equalToConstant: 84),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: coverImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: hotLabel.leadingAnchor, constant: -8),

            hotLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            hotLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),

            gameTagLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            gameTagLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            gameTagLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 50),
            gameTagLabel.heightAnchor.constraint(equalToConstant: 20),

            memberCountLabel.centerYAnchor.constraint(equalTo: gameTagLabel.centerYAnchor),
            memberCountLabel.leadingAnchor.constraint(equalTo: gameTagLabel.trailingAnchor, constant: 8),

            descriptionLabel.topAnchor.constraint(equalTo: gameTagLabel.bottomAnchor, constant: 6),
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
        ])
    }

    // MARK: - 数据绑定

    /// 绑定语音房数据到 Cell — 使用真实图片
    func configure(with room: VoiceRoom) {
        titleLabel.text = room.title
        hotLabel.text = "🔥 \(room.hotCountText)"
        gameTagLabel.text = "  \(room.gameTag)  "
        descriptionLabel.text = room.description
        memberCountLabel.text = "👥 \(room.memberCount) online"
        // 加载真实封面图片（对应 Android coverResId）
        coverImageView.image = UIImage(named: room.coverImage)
    }
}
