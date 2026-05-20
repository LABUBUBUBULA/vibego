import UIKit

/// 消息页 - 对应 Android GameMic 的 MessageFragment
/// 顶部：4个功能入口（我的房间/系统通知/关注/访客）
/// 下方：私聊消息列表
class MessageViewController: UIViewController {

    // MARK: - 数据

    private var messages = MockDataManager.shared.messages

    // MARK: - UI 组件

    /// 顶部4个功能按钮区域（对应 Android 的 4 个 80x80 图标按钮）
    private let buttonsContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// 私聊消息列表（对应 Android RecyclerView）
    private lazy var messageTableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.delegate = self
        tv.dataSource = self
        tv.register(MessageCell.self, forCellReuseIdentifier: MessageCell.reuseId)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Messages"
        view.backgroundColor = Theme.Colors.darkBackground
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        messages = MockDataManager.shared.messages
        messageTableView.reloadData()
    }

    // MARK: - 界面搭建

    private func setupUI() {
        view.addSubview(buttonsContainer)
        view.addSubview(messageTableView)

        setupButtons()

        NSLayoutConstraint.activate([
            // 顶部按钮区域
            buttonsContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            buttonsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            buttonsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            buttonsContainer.heightAnchor.constraint(equalToConstant: 104),

            // 消息列表
            messageTableView.topAnchor.constraint(equalTo: buttonsContainer.bottomAnchor, constant: 16),
            messageTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messageTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            messageTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    /// 创建顶部4个功能按钮（对应 Android 的 My room / System Notion / Follow / Visitor）
    private func setupButtons() {
        let buttonData: [(icon: String, title: String)] = [
            ("ic_mes_room", "My Room"),
            ("ic_mes_notion", "System"),
            ("ic_mes_follow", "Follow"),
            ("ic_mes_visitor", "Visitor")
        ]

        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        buttonsContainer.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: buttonsContainer.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: buttonsContainer.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: buttonsContainer.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: buttonsContainer.bottomAnchor)
        ])

        for (index, data) in buttonData.enumerated() {
            let button = createFunctionButton(icon: data.icon, title: data.title, tag: index)
            stackView.addArrangedSubview(button)
        }
    }

    /// 创建单个功能按钮（80x80dp 图标 + 标题）
    private func createFunctionButton(icon: String, title: String, tag: Int) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        container.translatesAutoresizingMaskIntoConstraints = false

        // 图标
        let iconView = UIImageView()
        iconView.image = UIImage(named: icon)
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        // 标题
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = Theme.Fonts.regular(11)
        titleLabel.textColor = Theme.Colors.textSecondary
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(iconView)
        container.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconView.topAnchor.constraint(equalTo: container.topAnchor, constant: 2),
            iconView.widthAnchor.constraint(equalToConstant: 60),
            iconView.heightAnchor.constraint(equalToConstant: 60),

            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 8),
            titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor)
        ])

        // 添加点击手势
        container.tag = tag
        let tap = UITapGestureRecognizer(target: self, action: #selector(functionButtonTapped(_:)))
        container.addGestureRecognizer(tap)

        return container
    }

    /// 功能按钮点击事件（对应 Android 的 4 种跳转）
    @objc private func functionButtonTapped(_ gesture: UITapGestureRecognizer) {
        guard let tag = gesture.view?.tag else { return }
        switch tag {
        case 0:
            openMyRoom()
        case 1:
            let vc = SystemNotificationViewController()
            pushAppViewController(vc, animated: true)
        case 2:
            let vc = FansViewController()
            vc.listType = .following
            pushAppViewController(vc, animated: true)
        case 3:
            let vc = FansViewController()
            vc.listType = .visitors
            pushAppViewController(vc, animated: true)
        default: break
        }
    }

    /// My Room 点击：对应 Android MessageFragment.findUserRoom，有房进房，无房 toast
    private func openMyRoom() {
        guard UserManager.shared.currentUser != nil else {
            showToast("Please sign in first")
            return
        }
        guard let room = MockDataManager.shared.getMyRoom() else {
            showToast("You haven't created a voice room")
            return
        }
        MockDataManager.shared.addBrowseHistory(room)
        let vc = VoiceRoomViewController()
        vc.room = room
        vc.isOwner = true
        pushAppViewController(vc, animated: true)
    }

}

// MARK: - 消息列表 TableView 数据源和代理
extension MessageViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MessageCell.reuseId, for: indexPath) as! MessageCell
        cell.configure(with: messages[indexPath.row])
        return cell
    }

    /// 消息项高度（对应 Android item_message 约 76dp）
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    /// 点击消息进入聊天页面（对应 Android ChatActivity）
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let message = messages[indexPath.row]
        MockDataManager.shared.markMessageRead(userId: message.userId)
        messages[indexPath.row].unreadCount = 0
        tableView.reloadRows(at: [indexPath], with: .none)
        let vc = ChatViewController()
        vc.chatUser = messages[indexPath.row]
        pushAppViewController(vc, animated: true)
    }

    /// 左滑可进用户主页，保证消息列表里的每个人都有主页入口
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let profile = UIContextualAction(style: .normal, title: "Profile") { [weak self] _, _, completion in
            guard let self else { return }
            let message = self.messages[indexPath.row]
            let vc = UserProfileViewController()
            let fallbackUser = User(
                id: message.userId,
                name: message.name,
                avatarImage: message.avatarImage,
                avatarUri: nil,
                bio: message.bio,
                gender: message.gender,
                countryFlag: "",
                level: message.level,
                backgroundImage: "bg_\(abs(message.userId) % 20 + 1)",
                isFollowing: MockDataManager.shared.isFollowing(userId: message.userId),
                interests: "PUBG"
            )
            vc.user = MockDataManager.shared.user(withId: message.userId) ?? fallbackUser
            self.pushAppViewController(vc, animated: true)
            completion(true)
        }
        profile.backgroundColor = Theme.Colors.primaryYellow
        return UISwipeActionsConfiguration(actions: [profile])
    }
}
