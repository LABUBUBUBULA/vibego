import UIKit

/// 设置页 - 对应 Android GameMic 的 SettingsActivity
/// 包含：账号注销、隐私政策、服务条款、清除缓存、关于
class SettingsViewController: UIViewController {

    // MARK: - 数据

    /// 设置项列表
    private let sections: [(title: String, items: [(icon: String, title: String)])] = [
        ("Support", [
            ("ic_report", "Terms of Service"),
            ("ic_see", "Privacy Policy"),
            ("logo", "About PlayTalk"),
        ]),
        ("Account", [
            ("ic_room_delete", "Delete Account"),
        ])
    ]

    // MARK: - UI 组件

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.backgroundColor = Theme.Colors.darkBackground
        tv.delegate = self
        tv.dataSource = self
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        view.backgroundColor = Theme.Colors.darkBackground
        setupUI()
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
}

// MARK: - TableView 数据源
extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        let item = sections[indexPath.section].items[indexPath.row]
        cell.imageView?.image = UIImage(named: item.icon)
        cell.imageView?.contentMode = .scaleAspectFit
        cell.textLabel?.text = item.title
        cell.textLabel?.textColor = item.title == "Delete Account" ? .systemRed : Theme.Colors.textPrimary
        cell.textLabel?.font = Theme.Fonts.regular(15)
        cell.backgroundColor = Theme.Colors.cardBackground
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sections[indexPath.section].items[indexPath.row]

        switch item.title {
        case "Terms of Service":
            pushAppViewController(LegalTextViewController(type: .terms), animated: true)
        case "Privacy Policy":
            pushAppViewController(LegalTextViewController(type: .privacy), animated: true)
        case "About PlayTalk":
            pushAppViewController(LegalTextViewController(type: .about), animated: true)
        case "Delete Account":
            let alert = UIAlertController(
                title: "Delete Account",
                message: "This will permanently delete your account and all data. This action cannot be undone.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                UserManager.shared.logout()
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let window = windowScene.windows.first else { return }
                let nav = UINavigationController(rootViewController: WelcomeViewController())
                window.rootViewController = nav
                window.makeKeyAndVisible()
            })
            present(alert, animated: true)
        default:
            break
        }
    }

}
