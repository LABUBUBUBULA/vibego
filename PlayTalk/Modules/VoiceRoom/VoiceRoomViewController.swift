import UIKit

/// 语音房详情页 - 对应 Android GameMic 的 VoiceRoomActivity
/// 布局（从上到下）：
/// 1. 房间头部信息（封面+房名+房间ID+收藏/设置/关闭）
/// 2. 8麦位网格（4列x2行，第1个为房主固定位）
/// 3. 聊天消息列表（欢迎/礼物/评论/公告 4种消息）
/// 4. 底部控制栏（麦克风/音量/礼物/菜单/聊天）
class VoiceRoomViewController: UIViewController {

    // MARK: - 传入数据

    var room: VoiceRoom?
    var isOwner: Bool = false

    // MARK: - 状态（对应 Android 的成员变量）

    /// 麦位用户数组 - mics 2-8（index 0-6 对应 mic2-mic8）
    private var micUsers: [User?] = Array(repeating: nil, count: 7)
    /// 麦位锁定状态
    private var micLockedStatus: [Bool] = Array(repeating: false, count: 7)
    /// 当前用户麦位索引（-1=未上麦）
    private var currentUserMicIndex: Int = -1
    /// 麦克风开关状态
    private var isMicOn: Bool = true
    /// 音量开关状态
    private var isVolumeOn: Bool = true
    /// 是否已收藏
    private var isFavorited: Bool = false
    /// 聊天消息列表
    private var messages: [RoomMessage] = []

    // MARK: - UI 组件

    /// 房间封面头像（56x56dp 圆形，对应 Android ivOwnerAvatar）
    private let roomCoverView: UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = Theme.Colors.primaryYellow.withAlphaComponent(0.3)
        iv.layer.cornerRadius = 28
        iv.layer.masksToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    /// 房间名称
    private let roomNameLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.bold(16)
        label.textColor = Theme.Colors.textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 房间 ID（格式 "ID: 277834"）
    private let roomIdLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.regular(12)
        label.textColor = Theme.Colors.textSecondary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 收藏按钮（对应 Android ivFavorite）
    private let favoriteButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "ic_room_unfavorite"), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    /// 关闭按钮（对应 Android ivClose）
    private let closeButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "ic_room_close"), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    /// 8麦位容器视图（4列x2行网格）
    private let micGridView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// 麦位视图数组（8个）
    private var micSeatViews: [MicSeatView] = []

    /// 聊天消息列表（对应 Android rv_room_messages）
    private lazy var messageTableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.delegate = self
        tv.dataSource = self
        tv.register(RoomMessageCell.self, forCellReuseIdentifier: RoomMessageCell.reuseId)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    /// 底部控制栏容器
    private let bottomBar: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.Colors.darkerBackground
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// 麦克风按钮（对应 Android ivMic）
    private let micButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "ic_room_say"), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    /// 音量按钮（对应 Android ivVolume）
    private let volumeButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "ic_room_sound"), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    /// 礼物按钮（对应 Android ivGift）
    private let giftButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "ic_room_gift"), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    /// 聊天输入按钮（对应 Android ivChatInput）
    private let chatInputButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "ic_room_chat"), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Colors.darkBackground
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupUI()
        setupActions()
        loadRoomData()
        loadInitialMessages()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - 界面搭建

    private func setupUI() {
        // 头部区域
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        headerView.addSubview(roomCoverView)
        headerView.addSubview(roomNameLabel)
        headerView.addSubview(roomIdLabel)
        headerView.addSubview(favoriteButton)
        headerView.addSubview(closeButton)

        // 麦位网格
        view.addSubview(micGridView)
        setupMicSeats()

        // 消息列表
        view.addSubview(messageTableView)

        // 底部控制栏
        view.addSubview(bottomBar)
        bottomBar.addSubview(micButton)
        bottomBar.addSubview(volumeButton)
        bottomBar.addSubview(giftButton)
        bottomBar.addSubview(chatInputButton)

        NSLayoutConstraint.activate([
            // 头部
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 72),

            // 房间封面
            roomCoverView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            roomCoverView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            roomCoverView.widthAnchor.constraint(equalToConstant: 56),
            roomCoverView.heightAnchor.constraint(equalToConstant: 56),

            // 房间名+ID
            roomNameLabel.topAnchor.constraint(equalTo: roomCoverView.topAnchor, constant: 4),
            roomNameLabel.leadingAnchor.constraint(equalTo: roomCoverView.trailingAnchor, constant: 12),
            roomNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: favoriteButton.leadingAnchor, constant: -8),

            roomIdLabel.topAnchor.constraint(equalTo: roomNameLabel.bottomAnchor, constant: 4),
            roomIdLabel.leadingAnchor.constraint(equalTo: roomNameLabel.leadingAnchor),

            // 右侧按钮
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40),

            favoriteButton.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),
            favoriteButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            favoriteButton.widthAnchor.constraint(equalToConstant: 40),
            favoriteButton.heightAnchor.constraint(equalToConstant: 40),

            // 麦位网格
            micGridView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
            micGridView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            micGridView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            micGridView.heightAnchor.constraint(equalToConstant: 200),

            // 消息列表（填充中间区域）
            messageTableView.topAnchor.constraint(equalTo: micGridView.bottomAnchor, constant: 8),
            messageTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messageTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            messageTableView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            // 底部控制栏（60dp 高度）
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 60),

            // 底部按钮布局（左：麦克风+音量 | 右：礼物+聊天）
            micButton.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 16),
            micButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            micButton.widthAnchor.constraint(equalToConstant: 44),
            micButton.heightAnchor.constraint(equalToConstant: 44),

            volumeButton.leadingAnchor.constraint(equalTo: micButton.trailingAnchor, constant: 16),
            volumeButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            volumeButton.widthAnchor.constraint(equalToConstant: 44),
            volumeButton.heightAnchor.constraint(equalToConstant: 44),

            chatInputButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -16),
            chatInputButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            chatInputButton.widthAnchor.constraint(equalToConstant: 44),
            chatInputButton.heightAnchor.constraint(equalToConstant: 44),

            giftButton.trailingAnchor.constraint(equalTo: chatInputButton.leadingAnchor, constant: -16),
            giftButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            giftButton.widthAnchor.constraint(equalToConstant: 44),
            giftButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    // MARK: - 麦位网格搭建（4列x2行，对应 Android grid_mics）

    /// 创建8个麦位视图
    private func setupMicSeats() {
        let columns = 4
        let rows = 2
        let spacing: CGFloat = 8

        for i in 0..<8 {
            let row = i / columns
            let col = i % columns

            let seatView = MicSeatView()
            seatView.tag = i
            seatView.translatesAutoresizingMaskIntoConstraints = false
            micGridView.addSubview(seatView)
            micSeatViews.append(seatView)

            // 点击手势
            let tap = UITapGestureRecognizer(target: self, action: #selector(micSeatTapped(_:)))
            seatView.addGestureRecognizer(tap)

            let seatWidth = (UIScreen.main.bounds.width - 32 - spacing * CGFloat(columns - 1)) / CGFloat(columns)
            let seatHeight: CGFloat = 92

            NSLayoutConstraint.activate([
                seatView.leadingAnchor.constraint(equalTo: micGridView.leadingAnchor, constant: CGFloat(col) * (seatWidth + spacing)),
                seatView.topAnchor.constraint(equalTo: micGridView.topAnchor, constant: CGFloat(row) * (seatHeight + spacing)),
                seatView.widthAnchor.constraint(equalToConstant: seatWidth),
                seatView.heightAnchor.constraint(equalToConstant: seatHeight)
            ])
        }
    }

    // MARK: - 事件绑定

    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        favoriteButton.addTarget(self, action: #selector(favoriteTapped), for: .touchUpInside)
        micButton.addTarget(self, action: #selector(micToggleTapped), for: .touchUpInside)
        volumeButton.addTarget(self, action: #selector(volumeToggleTapped), for: .touchUpInside)
        giftButton.addTarget(self, action: #selector(giftTapped), for: .touchUpInside)
        chatInputButton.addTarget(self, action: #selector(chatInputTapped), for: .touchUpInside)
    }

    /// 关闭房间
    @objc private func closeTapped() {
        navigationController?.popViewController(animated: true)
        if navigationController == nil {
            dismiss(animated: true)
        }
    }

    /// 收藏/取消收藏切换（对应 Android ivFavorite toggle）
    @objc private func favoriteTapped() {
        isFavorited.toggle()
        let imageName = isFavorited ? "ic_room_favorite" : "ic_room_unfavorite"
        favoriteButton.setImage(UIImage(named: imageName), for: .normal)
    }

    /// 麦克风开关切换（对应 Android ivMic toggle）
    @objc private func micToggleTapped() {
        isMicOn.toggle()
        let imageName = isMicOn ? "ic_room_say" : "ic_room_unsay"
        micButton.setImage(UIImage(named: imageName), for: .normal)
    }

    /// 音量开关切换（对应 Android ivVolume toggle）
    @objc private func volumeToggleTapped() {
        isVolumeOn.toggle()
        let imageName = isVolumeOn ? "ic_room_sound" : "ic_room_unsound"
        volumeButton.setImage(UIImage(named: imageName), for: .normal)
    }

    /// 礼物按钮点击 - 弹出礼物选择器（对应 Android GiftSelectorDialog）
    @objc private func giftTapped() {
        let giftVC = GiftSelectorViewController()
        giftVC.onGiftSend = { [weak self] gift, count in
            guard let self = self else { return }
            let senderName = UserManager.shared.currentUser?.name ?? "You"
            let receiverName = self.room?.hostName ?? "Host"
            let message = RoomMessage.createGift(
                senderName: senderName,
                receiverName: receiverName,
                giftImage: gift.imageName,
                giftCount: count
            )
            self.addMessage(message)
        }
        giftVC.modalPresentationStyle = .pageSheet
        if let sheet = giftVC.sheetPresentationController {
            sheet.detents = [.medium()]
        }
        present(giftVC, animated: true)
    }

    /// 聊天输入按钮 - 弹出输入框（对应 Android ChatInputDialog）
    @objc private func chatInputTapped() {
        let alert = UIAlertController(title: "Send Message", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Type your message..."
            tf.textColor = .black
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Send", style: .default) { [weak self] _ in
            guard let text = alert.textFields?.first?.text, !text.isEmpty else { return }
            let user = UserManager.shared.currentUser ?? MockDataManager.shared.users[0]
            let message = RoomMessage.createComment(sender: user, content: text)
            self?.addMessage(message)
        })
        present(alert, animated: true)
    }

    /// 麦位点击（对应 Android mic seat click handler）
    @objc private func micSeatTapped(_ gesture: UITapGestureRecognizer) {
        guard let seatIndex = gesture.view?.tag else { return }

        if seatIndex == 0 {
            // 麦位1是房主位，不能操作
            return
        }

        let micIndex = seatIndex - 1 // micUsers 数组 index（0-6 对应 mic2-mic8）

        if micUsers[micIndex] != nil {
            // 已有人 → 弹出用户信息（对应 Android UserProfileDialog）
            let alert = UIAlertController(title: micUsers[micIndex]?.name, message: "On Mic \(seatIndex + 1)", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Drop Mic", style: .destructive) { [weak self] _ in
                self?.micUsers[micIndex] = nil
                self?.updateMicSeatUI(at: seatIndex)
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
        } else if micLockedStatus[micIndex] {
            // 已锁定
            if isOwner {
                // 房主可以解锁
                micLockedStatus[micIndex] = false
                updateMicSeatUI(at: seatIndex)
            }
        } else {
            // 空位 → 上麦（对应 Android MicActionDialog）
            let alert = UIAlertController(title: "Mic \(seatIndex + 1)", message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Join Mic", style: .default) { [weak self] _ in
                let user = UserManager.shared.currentUser ?? MockDataManager.shared.users[0]
                self?.micUsers[micIndex] = user
                self?.currentUserMicIndex = seatIndex
                self?.updateMicSeatUI(at: seatIndex)
            })
            if isOwner {
                alert.addAction(UIAlertAction(title: "Lock Mic", style: .default) { [weak self] _ in
                    self?.micLockedStatus[micIndex] = true
                    self?.updateMicSeatUI(at: seatIndex)
                })
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
        }
    }

    // MARK: - 数据加载

    /// 加载房间数据到 UI
    private func loadRoomData() {
        guard let room = room else { return }
        roomNameLabel.text = room.roomName
        roomIdLabel.text = "ID: \(room.roomId)"
        roomCoverView.image = UIImage(named: room.coverImage)
        isFavorited = room.isCollected

        // 设置房主麦位（mic1）
        let hostSeat = micSeatViews[0]
        hostSeat.configure(
            avatarImage: room.hostAvatarImage,
            username: room.hostName,
            isHost: true,
            isEmpty: false,
            isLocked: false
        )

        // Mock: 随机给几个麦位放人
        let mockUsers = MockDataManager.shared.users
        for i in 0..<3 {
            let userIndex = Int.random(in: 1..<mockUsers.count)
            micUsers[i] = mockUsers[userIndex]
            updateMicSeatUI(at: i + 1)
        }
    }

    /// 加载初始消息（对应 Android loadRoomMessages）
    private func loadInitialMessages() {
        // 公告消息（对应 Android default announcement）
        let announcement = RoomMessage.createAnnouncement(
            content: "[Warm tips] Please follow the room rules. Be respectful and have fun!"
        )
        messages.append(announcement)

        // 欢迎消息
        let welcomeMsg = RoomMessage.createWelcome(username: UserManager.shared.currentUser?.name ?? "You")
        messages.append(welcomeMsg)

        messageTableView.reloadData()
    }

    /// 添加新消息并滚动到底部
    private func addMessage(_ message: RoomMessage) {
        messages.append(message)
        messageTableView.reloadData()
        // 滚动到底部
        let lastRow = messages.count - 1
        if lastRow >= 0 {
            messageTableView.scrollToRow(at: IndexPath(row: lastRow, section: 0), at: .bottom, animated: true)
        }
    }

    /// 更新指定麦位的 UI
    private func updateMicSeatUI(at seatIndex: Int) {
        guard seatIndex > 0, seatIndex < micSeatViews.count else { return }
        let micIndex = seatIndex - 1
        let seatView = micSeatViews[seatIndex]

        if let user = micUsers[micIndex] {
            seatView.configure(avatarImage: user.avatarImage, username: user.name, isHost: false, isEmpty: false, isLocked: false)
        } else if micLockedStatus[micIndex] {
            seatView.configure(avatarImage: "", username: "Locked", isHost: false, isEmpty: true, isLocked: true)
        } else {
            seatView.configure(avatarImage: "", username: "Mic \(seatIndex + 1)", isHost: false, isEmpty: true, isLocked: false)
        }
    }
}

// MARK: - 消息列表 TableView 数据源
extension VoiceRoomViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RoomMessageCell.reuseId, for: indexPath) as! RoomMessageCell
        cell.configure(with: messages[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}
