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
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "ic_publish") ?? UIImage(systemName: "square.and.pencil"),
            style: .plain,
            target: self,
            action: #selector(createPostTapped)
        )

        setupUI()
        loadPosts()
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

        posts = (0..<8).map { i in
            let user = users[i % users.count]
            return Post(
                id: 100 + i,
                authorId: "\(user.id)",
                authorName: user.name,
                authorAvatar: user.avatarImage,
                authorAvatarUri: nil,
                time: "\(Int.random(in: 1...24))h ago",
                title: titles[i],
                content: "This is a detailed post about \(gameName)...",
                images: [],
                imageUris: [],
                viewCount: Int.random(in: 100...50000),
                commentCount: Int.random(in: 5...100),
                likeCount: Int.random(in: 10...500),
                isLiked: false,
                isFollowing: false,
                gameTag: gameName
            )
        }
        tableView.reloadData()
    }

    /// 发帖按钮
    @objc private func createPostTapped() {
        let vc = CreatePostViewController()
        navigationController?.pushViewController(vc, animated: true)
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
        return 88
    }

    /// 点击帖子进入详情
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = PostDetailViewController()
        vc.post = posts[indexPath.row]
        navigationController?.pushViewController(vc, animated: true)
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

    /// 统计信息
    private let statsLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.regular(11)
        label.textColor = Theme.Colors.textSecondary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(titleLabel)
        contentView.addSubview(authorLabel)
        contentView.addSubview(statsLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            authorLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            authorLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            statsLabel.topAnchor.constraint(equalTo: authorLabel.bottomAnchor, constant: 4),
            statsLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with post: Post) {
        titleLabel.text = post.title
        authorLabel.text = "\(post.authorName)  ·  \(post.time)"
        statsLabel.text = "👁 \(post.viewCountText)  💬 \(post.commentCount)  ❤️ \(post.likeCount)"
    }
}
