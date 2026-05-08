import UIKit

/// 系统通知页 - 对应 Android GameMic 的 SystemNotificationActivity
/// 展示系统推送的通知列表
class SystemNotificationViewController: UIViewController {

    // MARK: - Mock 数据

    private let notifications: [(title: String, content: String, time: String)] = [
        ("Welcome to PlayTalk!", "Thank you for joining our community. Start exploring voice rooms now!", "2h ago"),
        ("New Feature", "Gift system is now live! Send gifts to your favorite hosts.", "5h ago"),
        ("Security Alert", "Your account was logged in from a new device.", "1d ago"),
        ("Community Guidelines", "Please review our updated community guidelines.", "2d ago"),
        ("Maintenance Notice", "Server maintenance scheduled for tomorrow 3-5 AM.", "3d ago"),
    ]

    // MARK: - UI 组件

    private lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.delegate = self
        tv.dataSource = self
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
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        let notif = notifications[indexPath.row]
        cell.textLabel?.text = notif.title
        cell.textLabel?.font = Theme.Fonts.bold(15)
        cell.textLabel?.textColor = Theme.Colors.textPrimary
        cell.detailTextLabel?.text = notif.content
        cell.detailTextLabel?.font = Theme.Fonts.regular(13)
        cell.detailTextLabel?.textColor = Theme.Colors.textSecondary
        cell.detailTextLabel?.numberOfLines = 2
        cell.backgroundColor = .clear

        // 右侧时间
        let timeLabel = UILabel()
        timeLabel.text = notif.time
        timeLabel.font = Theme.Fonts.regular(11)
        timeLabel.textColor = Theme.Colors.textSecondary
        cell.accessoryView = timeLabel
        timeLabel.sizeToFit()

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 76
    }
}
