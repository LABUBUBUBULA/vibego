import UIKit

/// 私聊页面 - 对应 Android GameMic 的 ChatActivity
/// 布局：顶部用户信息 → 消息列表 → 底部输入框
class ChatViewController: UIViewController {

    // MARK: - 传入数据

    /// 聊天对方的用户信息
    var chatUser: Message?

    // MARK: - 数据

    /// Mock 聊天消息列表
    private var chatMessages: [(content: String, isMe: Bool, time: String)] = []

    // MARK: - UI 组件

    /// 消息列表
    private lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.delegate = self
        tv.dataSource = self
        tv.register(ChatBubbleCell.self, forCellReuseIdentifier: ChatBubbleCell.reuseId)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.keyboardDismissMode = .interactive
        return tv
    }()

    /// 底部输入区域容器
    private let inputContainer: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.Colors.darkerBackground
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// 消息输入框
    private let inputField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Type a message..."
        tf.textColor = Theme.Colors.textPrimary
        tf.font = Theme.Fonts.regular(14)
        tf.backgroundColor = Theme.Colors.cardBackground
        tf.layer.cornerRadius = 20
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.leftViewMode = .always
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    /// 发送按钮（对应 Android ic_chat_send）
    private let sendButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "ic_chat_send"), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        title = chatUser?.name ?? "Chat"
        view.backgroundColor = Theme.Colors.darkBackground
        setupUI()
        setupActions()
        loadMockMessages()
    }

    // MARK: - 界面搭建

    private func setupUI() {
        view.addSubview(tableView)
        view.addSubview(inputContainer)
        inputContainer.addSubview(inputField)
        inputContainer.addSubview(sendButton)

        NSLayoutConstraint.activate([
            // 消息列表
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainer.topAnchor),

            // 输入区域
            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            inputContainer.heightAnchor.constraint(equalToConstant: 56),

            // 输入框
            inputField.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 16),
            inputField.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            inputField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            inputField.heightAnchor.constraint(equalToConstant: 40),

            // 发送按钮
            sendButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 36),
            sendButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    // MARK: - 事件

    private func setupActions() {
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
    }

    /// 发送消息
    @objc private func sendTapped() {
        guard let text = inputField.text?.trimmingCharacters(in: .whitespaces), !text.isEmpty else { return }

        // 添加我发的消息
        chatMessages.append((content: text, isMe: true, time: "Just now"))
        inputField.text = ""
        tableView.reloadData()
        scrollToBottom()

        // Mock: 1秒后对方自动回复
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            let replies = [
                "That sounds great! 😊",
                "Sure, let's do it!",
                "I'll join your room later",
                "Haha nice one!",
                "See you there!"
            ]
            let reply = replies.randomElement() ?? "OK"
            self?.chatMessages.append((content: reply, isMe: false, time: "Just now"))
            self?.tableView.reloadData()
            self?.scrollToBottom()
        }
    }

    // MARK: - 数据

    /// 加载 Mock 历史消息
    private func loadMockMessages() {
        let userName = chatUser?.name ?? "Friend"
        chatMessages = [
            (content: "Hey, how are you?", isMe: false, time: "10 min ago"),
            (content: "I'm good! Want to join my room?", isMe: false, time: "9 min ago"),
            (content: "Sure! Which game?", isMe: true, time: "8 min ago"),
            (content: "Let's play PUBG together!", isMe: false, time: "7 min ago"),
            (content: "Sounds fun! I'll be there in 5", isMe: true, time: "5 min ago"),
        ]
        tableView.reloadData()
        scrollToBottom()
    }

    /// 滚动到底部
    private func scrollToBottom() {
        guard !chatMessages.isEmpty else { return }
        let lastRow = chatMessages.count - 1
        tableView.scrollToRow(at: IndexPath(row: lastRow, section: 0), at: .bottom, animated: true)
    }
}

// MARK: - TableView 数据源
extension ChatViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatMessages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatBubbleCell.reuseId, for: indexPath) as! ChatBubbleCell
        let msg = chatMessages[indexPath.row]
        cell.configure(content: msg.content, isMe: msg.isMe)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}

// MARK: - 聊天气泡 Cell

/// 聊天气泡（左=对方消息，右=我的消息）
class ChatBubbleCell: UITableViewCell {
    static let reuseId = "ChatBubbleCell"

    /// 气泡容器
    private let bubbleView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 16
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// 消息文字
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.regular(14)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 气泡左/右约束
    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.7),

            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8)
        ])

        leadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        trailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 配置气泡
    func configure(content: String, isMe: Bool) {
        messageLabel.text = content

        if isMe {
            // 我的消息 — 右侧，黄色背景
            bubbleView.backgroundColor = Theme.Colors.primaryYellow
            messageLabel.textColor = Theme.Colors.darkerBackground
            leadingConstraint?.isActive = false
            trailingConstraint?.isActive = true
        } else {
            // 对方消息 — 左侧，深色背景
            bubbleView.backgroundColor = Theme.Colors.cardBackground
            messageLabel.textColor = Theme.Colors.textPrimary
            trailingConstraint?.isActive = false
            leadingConstraint?.isActive = true
        }
    }
}
