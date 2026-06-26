import UIKit

/// 游戏频道详情页 - 对应 Android GameMic 的 GameForumActivity
/// 展示某个游戏分类下的帖子列表
/// 从 ForumViewController 的频道点击进入
class GameForumViewController: UIViewController {

    // MARK: - 传入数据

    /// 游戏名称（如 "PUBG"）
    var gameName: String = ""

    // MARK: - 数据

    /// 该游戏分类下的帖子列表（Mock）
    private var posts: [Post] = []

    // MARK: - UI 组件

    /// 帖子列表
    private lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.delegate = self
        tv.dataSource = self
        tv.register(PostCell.self, forCellReuseIdentifier: PostCell.reuseId)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    /// 发帖按钮（对应 Android 右上角发帖入口）
    private let createPostButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(named: "ic_publish") ?? UIImage(systemName: "square.and.pencil"), for: .normal)
        btn.tintColor = Theme.Colors.primaryYellow
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        title = gameName
        view.backgroundColor = Theme.Colors.darkBackground

        // 右上角发帖按钮
        let rawIcon = UIImage(named: "ic_publish") ?? UIImage(systemName: "square.and.pencil")
        let iconSize = CGSize(width: 20, height: 20)
        let resizedIcon = UIGraphicsImageRenderer(size: iconSize).image { _ in
            rawIcon?.draw(in: CGRect(origin: .zero, size: iconSize))
        }.withRenderingMode(.alwaysTemplate)
        let publishButton = UIButton(type: .system)
        publishButton.setImage(resizedIcon, for: .normal)
        publishButton.tintColor = Theme.Colors.primaryYellow
        publishButton.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        publishButton.addTarget(self, action: #selector(createPostTapped), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: publishButton)

        setupUI()
        loadPosts()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(moderationDidChange),
            name: ModerationManager.moderationDidChange,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupUI() {
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func assetPrefix(for gameName: String) -> String {
        switch gameName {
        case "Mobile Legends": return "pubg"
        case "Roblox": return "minecraft"
        case "Brawl Stars": return "fortnite"
        case "Among Us": return "thesims"
        default: return gameName.lowercased().replacingOccurrences(of: " ", with: "")
        }
    }

    /// 加载该游戏的帖子（Mock数据）
    private func loadPosts() {
        let users = MockDataManager.shared.users
        let titles = [
            "Best \(gameName) strategies for beginners",
            "Top 5 \(gameName) tips you didn't know",
            "\(gameName) update discussion",
            "Looking for \(gameName) teammates",
            "My best \(gameName) moment",
            "\(gameName) tier list - what do you think?",
            "Is \(gameName) worth playing in 2024?",
            "Pro player settings for \(gameName)"
        ]

        let imagePrefix = assetPrefix(for: gameName)
        let mockPosts = (0..<8).map { i in
            let user = users[(i + 1) % users.count]
            return Post(
                id: 100 + i,
                authorId: "\(user.id)",
                authorName: user.name,
                authorAvatar: user.avatarImage,
                authorAvatarUri: nil,
                time: "\(Int.random(in: 1...24))h ago",
                title: titles[i],
                content: "This is a detailed post about \(gameName)...",
                images: ["\(imagePrefix)_\((i % 6) + 1)"],
                imageUris: [],
                viewCount: Int.random(in: 100...50000),
                commentCount: Int.random(in: 5...100),
                likeCount: Int.random(in: 10...500),
                isLiked: false,
                isFollowing: MockDataManager.shared.isFollowing(userId: user.id),
                gameTag: gameName
            )
        }.filter {
            ModerationManager.shared.shouldShow(post: $0)
        }
        // 用户发布的帖子排前面
        let savedUserPosts = MockDataManager.shared.getUserPosts(gameTag: gameName)
        posts = (savedUserPosts + mockPosts).filter { ModerationManager.shared.shouldShow(post: $0) }
        tableView.reloadData()
    }

    @objc private func moderationDidChange() {
        loadPosts()
    }

    /// 发帖按钮
    @objc private func createPostTapped() {
        let vc = CreatePostViewController()
        vc.gameTag = gameName
        vc.onPostCreated = { [weak self] newPost in
            guard let self else { return }
            guard ModerationManager.shared.shouldShow(post: newPost) else { return }
            self.posts.insert(newPost, at: 0)
            self.tableView.reloadData()
        }
        pushAppViewController(vc, animated: true)
    }
}

// MARK: - TableView 数据源
extension GameForumViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PostCell.reuseId, for: indexPath) as! PostCell
        cell.configure(with: posts[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 112
    }

    /// 点击帖子进入详情
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = PostDetailViewController()
        vc.post = posts[indexPath.row]
        vc.onPostUpdated = { [weak self] updatedPost in
            guard let self else { return }
            guard let postIndex = self.posts.firstIndex(where: { $0.id == updatedPost.id }) else { return }
            guard ModerationManager.shared.shouldShow(post: updatedPost) else {
                self.posts.remove(at: postIndex)
                self.tableView.reloadData()
                return
            }
            self.posts[postIndex] = updatedPost
            self.tableView.reloadRows(at: [IndexPath(row: postIndex, section: 0)], with: .none)
        }
        vc.onPostDeleted = { [weak self] postId in
            guard let self else { return }
            self.posts.removeAll { $0.id == postId }
            self.tableView.reloadData()
        }
        pushAppViewController(vc, animated: true)
    }
}

// MARK: - 帖子列表 Cell

/// 帖子行 Cell - 标题 + 作者 + 浏览/评论/点赞统计
class PostCell: UITableViewCell {
    static let reuseId = "PostCell"

    /// 帖子标题
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.bold(15)
        label.textColor = Theme.Colors.textPrimary
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 作者信息
    private let authorLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.regular(12)
        label.textColor = Theme.Colors.textSecondary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 统计信息容器
    private let statsContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    /// 创建图标+文字的统计项
    private func makeStatItem(icon: String, text: String) -> UIStackView {
        let iconView = UIImageView(image: UIImage(named: icon))
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = Theme.Colors.textSecondary
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 18).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 18).isActive = true

        let label = UILabel()
        label.text = text
        label.font = Theme.Fonts.regular(11)
        label.textColor = Theme.Colors.textSecondary

        let stack = UIStackView(arrangedSubviews: [iconView, label])
        stack.axis = .horizontal
        stack.spacing = 3
        stack.alignment = .center
        return stack
    }

    /// 帖子缩略图
    private let postImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 10
        iv.layer.masksToBounds = true
        iv.backgroundColor = Theme.Colors.separator
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(titleLabel)
        contentView.addSubview(authorLabel)
        contentView.addSubview(statsContainer)
        contentView.addSubview(postImageView)

        NSLayoutConstraint.activate([
            postImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            postImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            postImageView.widthAnchor.constraint(equalToConstant: 88),
            postImageView.heightAnchor.constraint(equalToConstant: 88),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: postImageView.leadingAnchor, constant: -12),

            authorLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            authorLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            authorLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            statsContainer.topAnchor.constraint(equalTo: authorLabel.bottomAnchor, constant: 6),
            statsContainer.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            statsContainer.trailingAnchor.constraint(lessThanOrEqualTo: titleLabel.trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with post: Post) {
        titleLabel.text = post.title
        authorLabel.text = "\(post.authorName)  ·  \(post.time)"

        // 清除旧统计项并重建
        statsContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }
        statsContainer.addArrangedSubview(makeStatItem(icon: "ic_see", text: post.viewCountText))
        statsContainer.addArrangedSubview(makeStatItem(icon: "ic_forum_chat", text: "\(post.commentCount)"))
        statsContainer.addArrangedSubview(makeStatItem(icon: "ic_unlike", text: "\(post.likeCount)"))
        if let imageName = post.images.first, let image = UIImage(named: imageName) {
            postImageView.image = image
            postImageView.isHidden = false
        } else if let uri = post.imageUris.first, let image = UIImage(contentsOfFile: uri) {
            postImageView.image = image
            postImageView.isHidden = false
        } else {
            postImageView.image = nil
            postImageView.isHidden = true
        }
    }
}
