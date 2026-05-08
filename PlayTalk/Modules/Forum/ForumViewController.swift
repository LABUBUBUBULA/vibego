import UIKit

/// 论坛页 - 对应 Android GameMic 的 ForumFragment
/// 布局：标题 → 横幅图 → 热帖排行(5条) → 游戏频道(4个)
class ForumViewController: UIViewController {

    // MARK: - 数据

    private let hotPosts = MockDataManager.shared.hotPosts
    private let channels = MockDataManager.shared.gameChannels

    // MARK: - UI 组件

    /// 主滚动视图
    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.backgroundColor = .clear
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    /// 内容容器
    private let contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Game forum"    // 对应 Android 的 "Game forum" 标题（28sp bold）
        view.backgroundColor = Theme.Colors.darkBackground
        setupUI()
    }

    // MARK: - 界面搭建

    private func setupUI() {
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

        // 横幅区域（120dp 高度，对应 Android banner）
        let bannerView = createBannerView()
        contentView.addSubview(bannerView)

        // 热帖排行卡片
        let hotPostsCard = createHotPostsCard()
        contentView.addSubview(hotPostsCard)

        // 游戏频道卡片
        let channelsCard = createChannelsCard()
        contentView.addSubview(channelsCard)

        NSLayoutConstraint.activate([
            bannerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            bannerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bannerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            bannerView.heightAnchor.constraint(equalToConstant: 120),

            hotPostsCard.topAnchor.constraint(equalTo: bannerView.bottomAnchor, constant: 16),
            hotPostsCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            hotPostsCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            channelsCard.topAnchor.constraint(equalTo: hotPostsCard.bottomAnchor, constant: 16),
            channelsCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            channelsCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            channelsCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }

    // MARK: - 横幅视图

    /// 创建横幅区域（对应 Android 的 banner image 120dp）
    private func createBannerView() -> UIView {
        let view = UIView()
        view.backgroundColor = Theme.Colors.primaryYellow.withAlphaComponent(0.15)
        view.layer.cornerRadius = Theme.Dimensions.cornerRadius
        view.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "🎮 Game Forum"
        label.font = Theme.Fonts.bold(24)
        label.textColor = Theme.Colors.primaryYellow
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        return view
    }

    // MARK: - 热帖排行卡片

    /// 创建热帖排行卡片（对应 Android "All-service hot list"）
    /// 5 条热帖，前3名有排名图标，4-5名用数字
    private func createHotPostsCard() -> UIView {
        let card = UIView()
        card.backgroundColor = Theme.Colors.cardBackground
        card.layer.cornerRadius = Theme.Dimensions.cornerRadius
        card.translatesAutoresizingMaskIntoConstraints = false

        // 标题
        let titleLabel = UILabel()
        titleLabel.text = "🔥 All-service hot list"
        titleLabel.font = Theme.Fonts.bold(16)
        titleLabel.textColor = Theme.Colors.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
        ])

        // 5 条热帖
        var previousView: UIView = titleLabel
        for (index, post) in hotPosts.enumerated() {
            let row = createHotPostRow(rank: index + 1, post: post)
            card.addSubview(row)

            NSLayoutConstraint.activate([
                row.topAnchor.constraint(equalTo: previousView.bottomAnchor, constant: 12),
                row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
                row.heightAnchor.constraint(equalToConstant: 24)
            ])
            previousView = row

            // 最后一条设置底部约束
            if index == hotPosts.count - 1 {
                row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16).isActive = true
            }
        }

        return card
    }

    /// 创建单条热帖行
    /// - Parameters:
    ///   - rank: 排名 1-5
    ///   - post: 帖子数据
    private func createHotPostRow(rank: Int, post: Post) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false

        // 排名标识（1-3用特殊颜色，4-5用普通数字）
        let rankLabel = UILabel()
        rankLabel.font = Theme.Fonts.bold(14)
        rankLabel.textAlignment = .center
        rankLabel.translatesAutoresizingMaskIntoConstraints = false

        switch rank {
        case 1: rankLabel.text = "🥇"; rankLabel.textColor = UIColor(hex: "#FFD700")
        case 2: rankLabel.text = "🥈"; rankLabel.textColor = UIColor(hex: "#C0C0C0")
        case 3: rankLabel.text = "🥉"; rankLabel.textColor = UIColor(hex: "#CD7F32")
        default: rankLabel.text = "\(rank)"; rankLabel.textColor = Theme.Colors.textSecondary
        }

        // 帖子标题（省略）
        let titleLabel = UILabel()
        titleLabel.text = post.title
        titleLabel.font = Theme.Fonts.regular(14)
        titleLabel.textColor = Theme.Colors.textPrimary
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // 浏览量（黄色，对应 Android 火焰图标 + 数字）
        let viewCountLabel = UILabel()
        viewCountLabel.text = "🔥 \(post.viewCountText)"
        viewCountLabel.font = Theme.Fonts.regular(12)
        viewCountLabel.textColor = Theme.Colors.primaryYellow
        viewCountLabel.translatesAutoresizingMaskIntoConstraints = false
        viewCountLabel.setContentHuggingPriority(.required, for: .horizontal)

        row.addSubview(rankLabel)
        row.addSubview(titleLabel)
        row.addSubview(viewCountLabel)

        NSLayoutConstraint.activate([
            rankLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            rankLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            rankLabel.widthAnchor.constraint(equalToConstant: 28),

            titleLabel.leadingAnchor.constraint(equalTo: rankLabel.trailingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: viewCountLabel.leadingAnchor, constant: -8),

            viewCountLabel.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            viewCountLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])

        return row
    }

    // MARK: - 游戏频道卡片

    /// 创建游戏频道卡片（对应 Android "All Channels"）
    /// 4 个游戏频道入口：PUBG / Minecraft / Fortnite / TheSims
    private func createChannelsCard() -> UIView {
        let card = UIView()
        card.backgroundColor = Theme.Colors.cardBackground
        card.layer.cornerRadius = Theme.Dimensions.cornerRadius
        card.translatesAutoresizingMaskIntoConstraints = false

        // 标题
        let titleLabel = UILabel()
        titleLabel.text = "All Channels"
        titleLabel.font = Theme.Fonts.bold(16)
        titleLabel.textColor = Theme.Colors.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
        ])

        // 4 个频道行（对应 Android 的 4 个可点击频道）
        var previousView: UIView = titleLabel
        for (index, channel) in channels.enumerated() {
            let row = createChannelRow(channel: channel)
            card.addSubview(row)

            NSLayoutConstraint.activate([
                row.topAnchor.constraint(equalTo: previousView.bottomAnchor, constant: 12),
                row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
                row.heightAnchor.constraint(equalToConstant: 56) // 对应 Android 56dp
            ])
            previousView = row

            if index == channels.count - 1 {
                row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16).isActive = true
            }
        }

        return card
    }

    /// 创建单个频道行
    /// 布局：56x56 封面 | 游戏名 + 讨论人数 | 右箭头
    private func createChannelRow(channel: MockDataManager.GameChannel) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false

        // 频道封面（48x48dp，8dp 圆角）— 使用真实游戏图片
        let coverView = UIImageView()
        coverView.image = UIImage(named: channel.coverImage)
        coverView.backgroundColor = Theme.Colors.primaryYellow.withAlphaComponent(0.15)
        coverView.layer.cornerRadius = 8
        coverView.layer.masksToBounds = true
        coverView.contentMode = .scaleAspectFill
        coverView.translatesAutoresizingMaskIntoConstraints = false

        // 游戏名称（16sp bold）
        let nameLabel = UILabel()
        nameLabel.text = channel.name
        nameLabel.font = Theme.Fonts.bold(16)
        nameLabel.textColor = Theme.Colors.textPrimary
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        // 讨论人数（12sp gray）
        let countLabel = UILabel()
        countLabel.text = channel.discussionCount
        countLabel.font = Theme.Fonts.regular(12)
        countLabel.textColor = Theme.Colors.textSecondary
        countLabel.translatesAutoresizingMaskIntoConstraints = false

        // 右箭头
        let arrowLabel = UILabel()
        arrowLabel.text = "›"
        arrowLabel.font = Theme.Fonts.regular(24)
        arrowLabel.textColor = Theme.Colors.textSecondary
        arrowLabel.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(coverView)
        row.addSubview(nameLabel)
        row.addSubview(countLabel)
        row.addSubview(arrowLabel)

        NSLayoutConstraint.activate([
            coverView.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            coverView.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            coverView.widthAnchor.constraint(equalToConstant: 48),
            coverView.heightAnchor.constraint(equalToConstant: 48),

            nameLabel.topAnchor.constraint(equalTo: row.topAnchor, constant: 6),
            nameLabel.leadingAnchor.constraint(equalTo: coverView.trailingAnchor, constant: 12),

            countLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            countLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),

            arrowLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            arrowLabel.trailingAnchor.constraint(equalTo: row.trailingAnchor)
        ])

        // 点击进入游戏频道详情
        row.isUserInteractionEnabled = true
        row.accessibilityLabel = channel.name
        let tap = UITapGestureRecognizer(target: self, action: #selector(channelTapped(_:)))
        row.addGestureRecognizer(tap)

        return row
    }

    /// 游戏频道点击 → GameForumViewController
    @objc private func channelTapped(_ gesture: UITapGestureRecognizer) {
        let gameName = gesture.view?.accessibilityLabel ?? ""
        let vc = GameForumViewController()
        vc.gameName = gameName
        navigationController?.pushViewController(vc, animated: true)
    }
}
