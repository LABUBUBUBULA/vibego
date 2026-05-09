import UIKit

/// 粉丝列表页 - 对应 Android GameMic 的 FansActivity
/// 也复用于关注列表（FollowingActivity）和好友列表（FriendsActivity）
/// 列表展示：头像 + 昵称 + 签名 + 关注/取关按钮
class FansViewController: UIViewController {

    // MARK: - 页面类型

    enum ListType {
        case fans       // 粉丝
        case following  // 关注
        case friends    // 好友
        case visitors   // 访客
    }

    /// 页面类型
    var listType: ListType = .fans

    // MARK: - 数据

    /// 用户列表（Mock数据）
    private var users: [User] = []

    // MARK: - UI 组件

    /// 用户列表（对应 Android RecyclerView）
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

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Colors.darkBackground
        setupTitle()
        setupUI()
        loadData()
    }

    // MARK: - 配置

    /// 根据类型设置标题
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
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    /// 加载Mock用户数据
    private func loadData() {
        let allUsers = MockDataManager.shared.users
        switch listType {
        case .fans: users = Array(allUsers[0..<10])
        case .following: users = Array(allUsers[5..<15])
        case .friends: users = Array(allUsers[3..<12])
        case .visitors: users = Array(allUsers[10..<20])
        }
        tableView.reloadData()
    }
}

// MARK: - TableView 数据源
extension FansViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UserListCell.reuseId, for: indexPath) as! UserListCell
        cell.configure(with: users[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }

    /// 点击进入他人主页（对应 Android → UserProfileActivity）
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = UserProfileViewController()
        vc.user = users[indexPath.row]
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - 用户列表 Cell（粉丝/关注/好友共用）

/// 用户列表行 - 头像(48dp) + 昵称 + 签名 + 关注按钮
class UserListCell: UITableViewCell {
    static let reuseId = "UserListCell"

    /// 头像
    private let avatarView: UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = Theme.Colors.primaryYellow.withAlphaComponent(0.3)
        iv.layer.cornerRadius = 24
        iv.layer.masksToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    /// 昵称
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.bold(15)
        label.textColor = Theme.Colors.textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 签名
    private let bioLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.regular(12)
        label.textColor = Theme.Colors.textSecondary
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 关注按钮
    private let followButton: UIButton = {
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
        contentView.addSubview(followButton)

        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 48),
            avatarView.heightAnchor.constraint(equalToConstant: 48),

            nameLabel.topAnchor.constraint(equalTo: avatarView.topAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: followButton.leadingAnchor, constant: -8),

            bioLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            bioLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            bioLabel.trailingAnchor.constraint(lessThanOrEqualTo: followButton.leadingAnchor, constant: -8),

            followButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            followButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            followButton.widthAnchor.constraint(equalToConstant: 72),
            followButton.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 配置用户数据
    func configure(with user: User) {
        avatarView.image = UIImage(named: user.avatarImage)
        nameLabel.text = user.name
        bioLabel.text = user.bio

        if user.isFollowing {
            followButton.setTitle("Following", for: .normal)
            followButton.setTitleColor(Theme.Colors.textSecondary, for: .normal)
            followButton.backgroundColor = Theme.Colors.cardBackground
        } else {
            followButton.setTitle("Follow", for: .normal)
            followButton.setTitleColor(Theme.Colors.darkerBackground, for: .normal)
            followButton.backgroundColor = Theme.Colors.primaryYellow
        }
    }
}
