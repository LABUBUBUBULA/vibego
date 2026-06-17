import UIKit

/// 客服页 - 对应 Android CustomerServiceActivity
/// 展示常见问题、WhatsApp 联系卡片、用户输入和自动回复 mock 聊天。
class CustomerServiceViewController: UIViewController {

    fileprivate struct SupportMessage {
        let text: String
        let isUser: Bool
        let showsProblems: Bool
        let showsContact: Bool
        let time: String
    }

    private let problems = [
        "I didn't receive coins after purchase",
        "I can't buy coins",
        "I was charged too much",
        "Black screen / app issue",
        "Account issue",
        "Join our team"
    ]

    private var messages: [SupportMessage] = []

    private lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.delegate = self
        tv.dataSource = self
        tv.register(SupportMessageCell.self, forCellReuseIdentifier: SupportMessageCell.reuseId)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let inputContainer: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.Colors.darkerBackground
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let inputField: UITextField = {
        let field = UITextField()
        field.placeholder = "Enter message"
        field.attributedPlaceholder = NSAttributedString(
            string: "Enter message",
            attributes: [.foregroundColor: Theme.Colors.textSecondary]
        )
        field.textColor = Theme.Colors.textPrimary
        field.font = Theme.Fonts.regular(14)
        field.backgroundColor = Theme.Colors.cardBackground
        field.layer.cornerRadius = 18
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        field.leftViewMode = .always
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    private let sendButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        btn.tintColor = Theme.Colors.darkerBackground
        btn.backgroundColor = Theme.Colors.primaryYellow
        btn.layer.cornerRadius = 18
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Customer Service"
        view.backgroundColor = Theme.Colors.darkBackground
        setupUI()
        setupActions()
        loadInitialMessages()
    }

    private func setupUI() {
        view.addSubview(tableView)
        view.addSubview(inputContainer)
        inputContainer.addSubview(inputField)
        inputContainer.addSubview(sendButton)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainer.topAnchor),

            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            inputContainer.heightAnchor.constraint(equalToConstant: 56),

            inputField.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 16),
            inputField.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            inputField.heightAnchor.constraint(equalToConstant: 36),

            sendButton.leadingAnchor.constraint(equalTo: inputField.trailingAnchor, constant: 10),
            sendButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 36),
            sendButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    private func setupActions() {
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
    }

    private func loadInitialMessages() {
        messages = [
            SupportMessage(
                text: "Hi, welcome to VibeGo customer service. You can choose a common problem or send us a message.",
                isUser: false,
                showsProblems: true,
                showsContact: true,
                time: currentTimestamp()
            )
        ]
        tableView.reloadData()
    }

    @objc private func sendTapped() {
        let text = (inputField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        appendMessage(text, isUser: true)
        inputField.text = ""
        appendMessage("Thank you for your message. Our support team will get back to you soon.", isUser: false)
    }

    private func handleProblemTap(_ index: Int) {
        appendMessage(problems[index], isUser: true)
        appendMessage(reply(for: index), isUser: false)
    }

    private func appendMessage(_ text: String, isUser: Bool) {
        messages.append(SupportMessage(text: text, isUser: isUser, showsProblems: false, showsContact: false, time: currentTimestamp()))
        tableView.insertRows(at: [IndexPath(row: messages.count - 1, section: 0)], with: .automatic)
        tableView.scrollToRow(at: IndexPath(row: messages.count - 1, section: 0), at: .bottom, animated: true)
    }

    private func reply(for index: Int) -> String {
        switch index {
        case 0:
            return "If you didn't receive your coins after purchase:\n\n1. Check your account balance\n2. Wait for 5-10 minutes\n3. Restart the app\n4. Contact us with your order ID if issue persists"
        case 1:
            return "If you can't buy coins:\n\n1. Check your internet connection\n2. Make sure your payment method is valid\n3. Try a different payment method\n4. Clear app cache and try again"
        case 2:
            return "If you were overcharged:\n\n1. Check your purchase history\n2. Verify the amount on your receipt\n3. Send order ID, receipt, and expected amount"
        case 3:
            return "For black screen issues:\n\n1. Force close and restart the app\n2. Clear app cache\n3. Update to latest version\n4. Restart your device"
        case 4:
            return "For account issues:\n\n1. Try resetting your password\n2. Check if account is suspended\n3. Contact support with account ID and screenshots"
        case 5:
            return "Join our team!\n\nAvailable positions:\n• Game Developers\n• UI/UX Designers\n• Community Managers\n• QA Testers\n\nSend your resume to: TorresNicole198@gmail.com"
        default:
            return "Thank you for your question. Our support team will get back to you soon."
        }
    }

    private func currentTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-M-d HH:mm"
        return formatter.string(from: Date())
    }
}

extension CustomerServiceViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SupportMessageCell.reuseId, for: indexPath) as! SupportMessageCell
        cell.configure(message: messages[indexPath.row], problems: problems) { [weak self] index in
            self?.handleProblemTap(index)
        }
        return cell
    }
}

private class SupportMessageCell: UITableViewCell {
    static let reuseId = "SupportMessageCell"

    private let timeLabel = UILabel()
    private let bubbleView = UIView()
    private let messageLabel = UILabel()
    private let stackView = UIStackView()
    private var bubbleLeadingConstraint: NSLayoutConstraint?
    private var bubbleTrailingConstraint: NSLayoutConstraint?
    private var problemButtons: [UIButton] = []
    private var onProblemTap: ((Int) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none

        timeLabel.font = Theme.Fonts.regular(11)
        timeLabel.textColor = Theme.Colors.textSecondary
        timeLabel.textAlignment = .center
        timeLabel.translatesAutoresizingMaskIntoConstraints = false

        bubbleView.layer.cornerRadius = 14
        bubbleView.translatesAutoresizingMaskIntoConstraints = false

        messageLabel.font = Theme.Fonts.regular(14)
        messageLabel.textColor = Theme.Colors.textPrimary
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(timeLabel)
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)
        bubbleView.addSubview(stackView)

        NSLayoutConstraint.activate([
            timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            timeLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            bubbleView.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 6),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.78),

            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),

            stackView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 10),
            stackView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -12)
        ])
    }

    func configure(message: CustomerServiceViewController.SupportMessage, problems: [String], onProblemTap: @escaping (Int) -> Void) {
        self.onProblemTap = onProblemTap
        timeLabel.text = message.time
        messageLabel.text = message.text
        bubbleView.backgroundColor = message.isUser ? Theme.Colors.primaryYellow.withAlphaComponent(0.25) : Theme.Colors.cardBackground

        bubbleLeadingConstraint?.isActive = false
        bubbleTrailingConstraint?.isActive = false
        bubbleLeadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: message.isUser ? 80 : 16)
        bubbleTrailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: message.isUser ? -16 : -80)
        bubbleLeadingConstraint?.isActive = true
        bubbleTrailingConstraint?.isActive = true

        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        problemButtons.removeAll()

        if message.showsProblems {
            for (index, problem) in problems.enumerated() {
                let button = makeProblemButton(title: "\(index + 1). \(problem)", index: index)
                stackView.addArrangedSubview(button)
                problemButtons.append(button)
            }
        }

        if message.showsContact {
            stackView.addArrangedSubview(makeContactCard())
        }
    }

    private func makeProblemButton(title: String, index: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(Theme.Colors.primaryYellow, for: .normal)
        button.titleLabel?.font = Theme.Fonts.regular(13)
        button.contentHorizontalAlignment = .left
        button.tag = index
        button.addTarget(self, action: #selector(problemTapped(_:)), for: .touchUpInside)
        return button
    }

    private func makeContactCard() -> UIView {
        let label = UILabel()
        label.text = "WhatsApp: 2019238291\nTap Copy in Android version; iOS mock keeps number visible."
        label.font = Theme.Fonts.regular(13)
        label.textColor = Theme.Colors.textSecondary
        label.numberOfLines = 0
        label.backgroundColor = Theme.Colors.darkerBackground
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        return label
    }

    @objc private func problemTapped(_ sender: UIButton) {
        onProblemTap?(sender.tag)
    }
}
