import UIKit

class SettingsViewController: UIViewController {

    private let sections: [(title: String, items: [String])] = [
        ("Support", [
            "Terms of Service",
            "Privacy Policy",
            "About PlayMeet"
        ]),
        ("Account", [
            "Delete Account"
        ])
    ]

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.backgroundColor = Theme.Colors.darkBackground
        tv.delegate = self
        tv.dataSource = self
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

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

    private var appVersionText: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.textColor = .white
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let title = sections[indexPath.section].items[indexPath.row]
        let cell = UITableViewCell(style: title == "About PlayMeet" ? .value1 : .default, reuseIdentifier: nil)
        cell.textLabel?.text = title
        cell.textLabel?.textColor = title == "Delete Account" ? .systemRed : Theme.Colors.textPrimary
        cell.textLabel?.font = Theme.Fonts.regular(15)
        cell.detailTextLabel?.text = title == "About PlayMeet" ? appVersionText : nil
        cell.detailTextLabel?.textColor = Theme.Colors.textSecondary
        cell.detailTextLabel?.font = Theme.Fonts.regular(15)
        cell.backgroundColor = Theme.Colors.cardBackground
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let title = sections[indexPath.section].items[indexPath.row]

        switch title {
        case "Terms of Service":
            pushAppViewController(LegalTextViewController(type: .terms), animated: true)
        case "Privacy Policy":
            pushAppViewController(LegalTextViewController(type: .privacy), animated: true)
        case "About PlayMeet":
            pushAppViewController(LegalTextViewController(type: .about), animated: true)
        case "Delete Account":
            let alert = UIAlertController(
                title: "Delete Account",
                message: "This will permanently delete your account and all data. This action cannot be undone.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                UserManager.shared.deleteCurrentAccount()
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
