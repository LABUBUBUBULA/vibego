import UIKit

/// 系统通知页 - 对应 Android GameMic 的 SystemNotificationActivity
/// 展示系统推送的通知列表
class SystemNotificationViewController: UIViewController {

    // MARK: - Mock 数据

    private let notifications: [(icon: String, title: String, content: String, time: String)] = [
        ("bell.badge.fill", "Welcome to PlayMeet!", "Thank you for joining our community. Start exploring voice rooms and make new friends!", "2h ago"),
        ("gift.fill", "New Feature", "Gift system is now live! Send gifts to your favorite hosts and show your support.", "5h ago"),
        ("lock.shield.fill", "Security Alert", "Your account was logged in from a new device. If this wasn't you, please change your password.", "1d ago"),
        ("doc.text.fill", "Community Guidelines", "Please review our updated community guidelines to keep PlayMeet safe and fun.", "2d ago"),
        ("wrench.and.screwdriver.fill", "Maintenance Notice", "Server maintenance scheduled for tomorrow 3:00–5:00 AM UTC. Some features may be temporarily unavailable.", "3d ago"),
        ("star.fill", "Level Up!", "Congratulations! You've reached Level 2. Keep chatting and gaming to unlock more rewards.", "4d ago"),
        ("megaphone.fill", "Weekend Event", "Join our weekend voice room contest! Top hosts win exclusive badges and coins.", "5d ago"),
    ]

    // MARK: - UI 组件

    private lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.delegate = self
        tv.dataSource = self
        tv.register(NotificationCell.self, forCellReuseIdentifier: NotificationCell.reuseId)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "System Notifications"
        view.backgroundColor = Theme.Colors.darkBackground

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - TableView 数据源
extension SystemNotificationViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NotificationCell.reuseId, for: indexPath) as! NotificationCell
        let notif = notifications[indexPath.row]
        cell.configure(icon: notif.icon, title: notif.title, content: notif.content, time: notif.time)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}

// MARK: - 通知 Cell
private class NotificationCell: UITableViewCell {
    static let reuseId = "NotificationCell"

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.Colors.cardBackground
        v.layer.cornerRadius = 14
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let iconContainer: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.Colors.primaryYellow.withAlphaComponent(0.15)
        v.layer.cornerRadius = 20
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.tintColor = Theme.Colors.primaryYellow
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.bold(15)
        label.textColor = Theme.Colors.textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.regular(13)
        label.textColor = Theme.Colors.textSecondary
        label.numberOfLines = 3
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

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

        contentView.addSubview(cardView)
        cardView.addSubview(iconContainer)
        iconContainer.addSubview(iconView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(contentLabel)
        cardView.addSubview(timeLabel)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            iconContainer.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            iconContainer.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            iconContainer.widthAnchor.constraint(equalToConstant: 40),
            iconContainer.heightAnchor.constraint(equalToConstant: 40),

            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: -8),

            timeLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            timeLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),

            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            contentLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            contentLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            contentLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(icon: String, title: String, content: String, time: String) {
        iconView.image = UIImage(systemName: icon)
        titleLabel.text = title
        contentLabel.text = content
        timeLabel.text = time
    }
}
