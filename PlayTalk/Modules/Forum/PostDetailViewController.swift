import UIKit

/// 帖子详情页 - 对应 Android GameMic 的 PostDetailActivity
/// 布局：帖子内容（作者+标题+正文+图片） → 评论列表 → 底部评论输入
class PostDetailViewController: UIViewController {

    // MARK: - 传入数据

    var post: Post?
    /// 回调：详情页修改后同步给列表
    var onPostUpdated: ((Post) -> Void)?

    // MARK: - 数据

    /// Mock 评论列表
    private var comments: [(user: User, content: String, time: String)] = []

    /// 删除帖子回调
    var onPostDeleted: ((Int) -> Void)?

    private let reportReasons = [
        "Harassment or bullying",
        "Sexual content",
        "Hate speech",
        "Scam or fraud",
        "Spam",
        "Fake profile",
        "Underage user",
        "Other"
    ]

    // MARK: - UI 组件

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .grouped)
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.delegate = self
        tv.dataSource = self
        tv.register(CommentCell.self, forCellReuseIdentifier: CommentCell.reuseId)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    /// 底部互动栏（点赞+评论+分享）
    private let bottomBar: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.Colors.darkerBackground
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// 点赞按钮
    private let likeButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "ic_unlike"), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    /// 点赞数
    private let likeCountLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.regular(12)
        label.textColor = Theme.Colors.textSecondary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 评论输入按钮
    private let commentButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Write a comment...", for: .normal)
        btn.setTitleColor(Theme.Colors.textSecondary, for: .normal)
        btn.titleLabel?.font = Theme.Fonts.regular(14)
        btn.backgroundColor = Theme.Colors.cardBackground
        btn.layer.cornerRadius = 20
        btn.contentHorizontalAlignment = .left
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        btn.configuration = config
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Post Detail"
        view.backgroundColor = Theme.Colors.darkBackground
        setupMoreButton()
        setupUI()
        setupActions()
        loadMockComments()
    }

    private func setupMoreButton() {
        let moreButton = UIButton(type: .system)
        moreButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        moreButton.tintColor = .white
        moreButton.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        moreButton.addTarget(self, action: #selector(moreTapped), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: moreButton)
    }

    @objc private func moreTapped() {
        let currentUserId = UserManager.shared.currentUser?.id ?? 0
        let isOwnPost = post?.authorId == "\(currentUserId)"

        if isOwnPost {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                guard let self, let postId = self.post?.id else { return }
                MockDataManager.shared.removeUserPost(id: postId)
                self.onPostDeleted?(postId)
                self.showToast("Post deleted")
                self.navigationController?.popViewController(animated: true)
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            if let popover = alert.popoverPresentationController {
                popover.barButtonItem = navigationItem.rightBarButtonItem
            }
            present(alert, animated: true)
        } else {
            showReportSheet()
        }
    }

    private func showReportSheet() {
        let alert = UIAlertController(
            title: "Report Post",
            message: "Choose a reason. PlayMeet reviews reports about inappropriate content.",
            preferredStyle: .actionSheet
        )
        reportReasons.forEach { reason in
            alert.addAction(UIAlertAction(title: reason, style: .default) { [weak self] _ in
                self?.showReportDetail(reason: reason)
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        present(alert, animated: true)
    }

    private func showReportDetail(reason: String) {
        let authorName = post?.authorName ?? "this user"
        let alert = UIAlertController(
            title: "Report \(authorName)",
            message: "Reason: \(reason)\nAdd details to help us review faster.",
            preferredStyle: .alert
        )
        alert.addTextField { tf in
            tf.placeholder = "Describe what happened"
            tf.clearButtonMode = .whileEditing
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Submit", style: .destructive) { [weak self, weak alert] _ in
            let detail = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let message = detail.isEmpty
                ? "Thanks. We will review this post."
                : "Thanks. We will review this post and your details."
            let done = UIAlertController(title: "Report submitted", message: message, preferredStyle: .alert)
            done.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(done, animated: true)
        })
        present(alert, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent, let post = post {
            onPostUpdated?(post)
            MockDataManager.shared.updateUserPost(post)
        }
    }

    // MARK: - 界面搭建

    private func setupUI() {
        view.addSubview(tableView)
        view.addSubview(bottomBar)
        bottomBar.addSubview(likeButton)
        bottomBar.addSubview(likeCountLabel)
        bottomBar.addSubview(commentButton)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 56),

            likeButton.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 16),
            likeButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            likeButton.widthAnchor.constraint(equalToConstant: 28),
            likeButton.heightAnchor.constraint(equalToConstant: 28),

            likeCountLabel.leadingAnchor.constraint(equalTo: likeButton.trailingAnchor, constant: 4),
            likeCountLabel.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),

            commentButton.leadingAnchor.constraint(equalTo: likeCountLabel.trailingAnchor, constant: 16),
            commentButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -16),
            commentButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            commentButton.heightAnchor.constraint(equalToConstant: 40)
        ])

        likeCountLabel.text = "\(post?.likeCount ?? 0)"
    }

    // MARK: - 事件

    private func setupActions() {
        likeButton.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)
        commentButton.addTarget(self, action: #selector(commentTapped), for: .touchUpInside)
    }

    /// 点赞切换
    @objc private func likeTapped() {
        guard var p = post else { return }
        p.isLiked.toggle()
        p.likeCount += p.isLiked ? 1 : -1
        post = p
        likeButton.setImage(UIImage(named: p.isLiked ? "ic_like" : "ic_unlike"), for: .normal)
        likeCountLabel.text = "\(p.likeCount)"
        // 同步顶部统计区
        tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
    }

    /// 评论输入
    @objc private func commentTapped() {
        let alert = UIAlertController(title: "Add Comment", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Write your comment..."
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Post", style: .default) { [weak self] _ in
            guard let self, let text = alert.textFields?.first?.text, !text.isEmpty else { return }
            let user = UserManager.shared.currentUser ?? MockDataManager.shared.users[0]
            self.comments.insert((user: user, content: text, time: "Just now"), at: 0)
            self.post?.commentCount = self.comments.count
            self.tableView.reloadData()
            // 持久化评论
            if let postId = self.post?.id {
                let comment = MockDataManager.UserComment(
                    postId: postId,
                    userName: user.name,
                    userAvatar: user.displayAvatar,
                    content: text,
                    time: "Just now"
                )
                MockDataManager.shared.addUserComment(comment)
            }
        })
        present(alert, animated: true)
    }

    // MARK: - Mock 数据

    private func loadMockComments() {
        let currentUserId = UserManager.shared.currentUser?.id ?? 0
        let isOwnPost = post?.authorId == "\(currentUserId)"
        let allUsers = MockDataManager.shared.users

        // 加载已保存的用户评论
        var savedComments: [(user: User, content: String, time: String)] = []
        if let postId = post?.id {
            savedComments = MockDataManager.shared.getUserComments(postId: postId).map { c in
                let user = allUsers.first { $0.name == c.userName }
                    ?? UserManager.shared.currentUser
                    ?? allUsers[0]
                return (user: user, content: c.content, time: c.time)
            }
        }

        // 自己发布的帖子不预设评论，只显示已保存的
        if isOwnPost {
            comments = savedComments
            post?.commentCount = comments.count
            return
        }

        let commentTexts = [
            "Great post! Very helpful ��",
            "I totally agree with this",
            "Can you share more details?",
            "This is exactly what I was looking for",
            "Nice tips, thanks for sharing!",
            "I tried this and it works great",
            "Looking forward to more content like this"
        ]
        let mockComments: [(user: User, content: String, time: String)] = (0..<7).map { i in
            (user: allUsers[(i + 3) % allUsers.count],
             content: commentTexts[i],
             time: "\(Int.random(in: 1...24))h ago")
        }
        comments = savedComments + mockComments
        post?.commentCount = comments.count
    }
}

// MARK: - TableView 数据源
extension PostDetailViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { return 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : comments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            // 帖子内容（header section）
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            configurePostCell(cell)
            return cell
        } else {
            // 评论
            let cell = tableView.dequeueReusableCell(withIdentifier: CommentCell.reuseId, for: indexPath) as! CommentCell
            let comment = comments[indexPath.row]
            cell.configure(user: comment.user, content: comment.content, time: comment.time)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section == 0 ? 200 : 80
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 {
            let header = UILabel()
            header.text = "  Comments (\(comments.count))"
            header.font = Theme.Fonts.bold(16)
            header.textColor = Theme.Colors.textPrimary
            header.backgroundColor = Theme.Colors.darkBackground
            return header
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 1 ? 40 : 0
    }

    /// 配置帖子内容 Cell
    private func configurePostCell(_ cell: UITableViewCell) {
        guard let post = post else { return }

        // 清除旧内容
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        // 作者信息
        let authorLabel = UILabel()
        authorLabel.text = "\(post.authorName)  ·  \(post.time)"
        authorLabel.font = Theme.Fonts.medium(14)
        authorLabel.textColor = Theme.Colors.textSecondary
        authorLabel.translatesAutoresizingMaskIntoConstraints = false

        // 标题
        let titleLabel = UILabel()
        titleLabel.text = post.title
        titleLabel.font = Theme.Fonts.bold(20)
        titleLabel.textColor = Theme.Colors.textPrimary
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // 内容
        let contentLabel = UILabel()
        contentLabel.text = post.content
        contentLabel.font = Theme.Fonts.regular(15)
        contentLabel.textColor = Theme.Colors.textPrimary
        contentLabel.numberOfLines = 0
        contentLabel.translatesAutoresizingMaskIntoConstraints = false

        let postImageView = UIImageView()
        postImageView.contentMode = .scaleAspectFit
        postImageView.layer.cornerRadius = 14
        postImageView.layer.masksToBounds = true
        postImageView.backgroundColor = .clear
        postImageView.image = post.images.first.flatMap { UIImage(named: $0) }
            ?? post.imageUris.first.flatMap { UIImage(contentsOfFile: $0) }
        postImageView.isHidden = postImageView.image == nil
        postImageView.translatesAutoresizingMaskIntoConstraints = false

        // 统计信息（图标+文字）
        let statsContainer = UIStackView()
        statsContainer.axis = .horizontal
        statsContainer.spacing = 16
        statsContainer.alignment = .center
        statsContainer.translatesAutoresizingMaskIntoConstraints = false

        func makeStatItem(icon: String, text: String) -> UIStackView {
            let iconView = UIImageView(image: UIImage(named: icon))
            iconView.contentMode = .scaleAspectFit
            iconView.tintColor = Theme.Colors.textSecondary
            iconView.translatesAutoresizingMaskIntoConstraints = false
            iconView.widthAnchor.constraint(equalToConstant: 20).isActive = true
            iconView.heightAnchor.constraint(equalToConstant: 20).isActive = true

            let label = UILabel()
            label.text = text
            label.font = Theme.Fonts.regular(13)
            label.textColor = Theme.Colors.textSecondary

            let stack = UIStackView(arrangedSubviews: [iconView, label])
            stack.axis = .horizontal
            stack.spacing = 4
            stack.alignment = .center
            return stack
        }

        statsContainer.addArrangedSubview(makeStatItem(icon: "ic_see", text: post.viewCountText))
        statsContainer.addArrangedSubview(makeStatItem(icon: "ic_forum_chat", text: "\(comments.count)"))
        statsContainer.addArrangedSubview(makeStatItem(icon: "ic_unlike", text: "\(post.likeCount)"))

        cell.contentView.addSubview(authorLabel)
        cell.contentView.addSubview(titleLabel)
        cell.contentView.addSubview(contentLabel)
        cell.contentView.addSubview(postImageView)
        cell.contentView.addSubview(statsContainer)

        // 根据图片宽高比动态计算高度，横图180，竖图按比例最大360
        let calcHeight: CGFloat
        if postImageView.isHidden {
            calcHeight = 0
        } else if let img = postImageView.image {
            let screenWidth = UIScreen.main.bounds.width - 32
            let ratio = img.size.height / max(img.size.width, 1)
            calcHeight = min(screenWidth * ratio, 360)
        } else {
            calcHeight = 180
        }
        let imageHeight = postImageView.heightAnchor.constraint(equalToConstant: calcHeight)

        NSLayoutConstraint.activate([
            authorLabel.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 16),
            authorLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),

            titleLabel.topAnchor.constraint(equalTo: authorLabel.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),

            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            contentLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            contentLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            postImageView.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: postImageView.isHidden ? 0 : 14),
            postImageView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            postImageView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            imageHeight,

            statsContainer.topAnchor.constraint(equalTo: postImageView.bottomAnchor, constant: 16),
            statsContainer.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            statsContainer.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -16)
        ])
    }
}

// MARK: - 评论 Cell

/// 评论行 Cell
class CommentCell: UITableViewCell {
    static let reuseId = "CommentCell"

    /// 头像
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 18
        iv.layer.masksToBounds = true
        iv.backgroundColor = Theme.Colors.primaryYellow.withAlphaComponent(0.3)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    /// 昵称
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.bold(14)
        label.textColor = Theme.Colors.primaryYellow
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 评论内容
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.regular(14)
        label.textColor = Theme.Colors.textPrimary
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 时间
    private let timeLabel: UILabel = {
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

        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(contentLabel)
        contentView.addSubview(timeLabel)

        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarImageView.widthAnchor.constraint(equalToConstant: 36),
            avatarImageView.heightAnchor.constraint(equalToConstant: 36),

            nameLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 10),

            timeLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            contentLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            contentLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            contentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            contentLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 配置评论 Cell
    func configure(user: User, content: String, time: String) {
        avatarImageView.image = user.displayAvatarImage ?? UIImage(named: user.avatarImage)
        nameLabel.text = user.name
        contentLabel.text = content
        timeLabel.text = time
    }
}
