import UIKit

/// 粉丝/关注/朋友列表页
class FansViewController: UIViewController {

    enum ListType {
        case fans
        case following
        case friends
        case visitors
    }

    var listType: ListType = .fans
    private var users: [User] = []

    private lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.delegate = self
        tv.dataSource = self
        tv.register(UserListCell.self, forCellReuseIdentifier: UserListCell.reuseId)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.medium(15)
        label.textColor = Theme.Colors.textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Colors.darkBackground
        setupTitle()
        setupUI()
        loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }

    private func setupTitle() {
        switch listType {
        case .fans: title = "Fans"
        case .following: title = "Following"
        case .friends: title = "Friends"
        case .visitors: title = "Visitors"
        }
    }

    private func setupUI() {
        view.addSubview(tableView)
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }

    private func loadData() {
        switch listType {
        case .fans:
            users = MockDataManager.shared.getFansUsers()
            emptyLabel.text = "No fans yet"
        case .following:
            users = MockDataManager.shared.getFollowingUsers()
            emptyLabel.text = "No following users yet"
        case .friends:
            users = MockDataManager.shared.getFriendUsers()
            emptyLabel.text = "No friends yet"
        case .visitors:
            users = Array(MockDataManager.shared.users.suffix(10)).filter { ModerationManager.shared.shouldShow(user: $0) }
            emptyLabel.text = "No visitors yet"
        }
        emptyLabel.isHidden = !users.isEmpty
        tableView.reloadData()
    }

    private func updateFollowState(for userId: Int, isFollowing: Bool) {
        MockDataManager.shared.setFollowing(userId: userId, isFollowing: isFollowing)
        loadData()
    }
}

extension FansViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UserListCell.reuseId, for: indexPath) as! UserListCell
        let user = MockDataManager.shared.userWithSyncedFollowState(users[indexPath.row])
        cell.configure(with: user, listType: listType)
        cell.onFollowTap = { [weak self] in
            self?.updateFollowState(for: user.id, isFollowing: !MockDataManager.shared.isFollowing(userId: user.id))
        }
        cell.onChatTap = { [weak self] in
            self?.openChat(with: user)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        76
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = UserProfileViewController()
        vc.user = users[indexPath.row]
        pushAppViewController(vc, animated: true)
    }

    private func openChat(with user: User) {
        let vc = ChatViewController()
        vc.chatUser = Message(
            userId: user.id,
            avatarImage: user.avatarImage,
            name: user.name,
            lastMessage: "",
            time: "",
            unreadCount: 0,
            timestamp: Date().timeIntervalSince1970,
            gender: user.gender,
            countryFlag: user.countryFlag,
            level: user.level,
            bio: user.bio
        )
        pushAppViewController(vc, animated: true)
    }
}

class UserListCell: UITableViewCell {
    static let reuseId = "UserListCell"

    var onFollowTap: (() -> Void)?
    var onChatTap: (() -> Void)?

    private let avatarView: UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = Theme.Colors.primaryYellow.withAlphaComponent(0.3)
        iv.layer.cornerRadius = 24
        iv.layer.masksToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.bold(15)
        label.textColor = Theme.Colors.textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let bioLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.regular(12)
        label.textColor = Theme.Colors.textSecondary
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let actionButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.titleLabel?.font = Theme.Fonts.medium(12)
        btn.layer.cornerRadius = 14
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(bioLabel)
        contentView.addSubview(actionButton)
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 48),
            avatarView.heightAnchor.constraint(equalToConstant: 48),

            nameLabel.topAnchor.constraint(equalTo: avatarView.topAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: actionButton.leadingAnchor, constant: -8),

            bioLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            bioLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            bioLabel.trailingAnchor.constraint(lessThanOrEqualTo: actionButton.leadingAnchor, constant: -8),

            actionButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            actionButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            actionButton.widthAnchor.constraint(equalToConstant: 82),
            actionButton.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with user: User, listType: FansViewController.ListType) {
        avatarView.image = user.displayAvatarImage ?? UIImage(named: user.avatarImage)
        nameLabel.text = user.name
        bioLabel.text = user.bio

        switch listType {
        case .friends:
            actionButton.setTitle("Chat", for: .normal)
            actionButton.setTitleColor(Theme.Colors.darkerBackground, for: .normal)
            actionButton.backgroundColor = Theme.Colors.primaryYellow
        default:
            actionButton.setTitle(user.isFollowing ? "Following" : "Follow", for: .normal)
            actionButton.setTitleColor(user.isFollowing ? Theme.Colors.textSecondary : Theme.Colors.darkerBackground, for: .normal)
            actionButton.backgroundColor = user.isFollowing ? Theme.Colors.cardBackground : Theme.Colors.primaryYellow
        }
    }

    @objc private func actionTapped() {
        if actionButton.title(for: .normal) == "Chat" {
            onChatTap?()
        } else {
            onFollowTap?()
        }
    }
}
