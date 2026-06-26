import UIKit

final class BlockedUsersViewController: UIViewController {

    private var users: [User] = []

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = Theme.Colors.darkBackground
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(BlockedUserCell.self, forCellReuseIdentifier: BlockedUserCell.reuseId)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "No blocked users"
        label.font = Theme.Fonts.medium(15)
        label.textColor = Theme.Colors.textSecondary
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Blocked Users"
        view.backgroundColor = Theme.Colors.darkBackground
        setupUI()
        loadData()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(moderationDidChange),
            name: ModerationManager.moderationDidChange,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    private func loadData() {
        users = ModerationManager.shared.blockedUsers()
        emptyLabel.isHidden = !users.isEmpty
        tableView.reloadData()
    }

    @objc private func moderationDidChange() {
        loadData()
    }

    private func confirmUnblock(_ user: User) {
        let alert = UIAlertController(
            title: "Unblock \(user.name)?",
            message: "Their profile, messages, posts, and rooms can appear again.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Unblock", style: .default) { [weak self] _ in
            ModerationManager.shared.unblockUser(userId: user.id)
            self?.showToast("User unblocked")
        })
        present(alert, animated: true)
    }
}

extension BlockedUsersViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        users.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        76
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BlockedUserCell.reuseId, for: indexPath) as! BlockedUserCell
        let user = users[indexPath.row]
        cell.configure(with: user)
        cell.onUnblockTap = { [weak self] in
            self?.confirmUnblock(user)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        confirmUnblock(users[indexPath.row])
    }
}

private final class BlockedUserCell: UITableViewCell {
    static let reuseId = "BlockedUserCell"

    var onUnblockTap: (() -> Void)?

    private let avatarView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = Theme.Colors.primaryYellow.withAlphaComponent(0.3)
        imageView.layer.cornerRadius = 24
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.bold(15)
        label.textColor = Theme.Colors.textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let idLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.regular(12)
        label.textColor = Theme.Colors.textSecondary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let unblockButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Unblock", for: .normal)
        button.setTitleColor(Theme.Colors.darkerBackground, for: .normal)
        button.titleLabel?.font = Theme.Fonts.medium(12)
        button.backgroundColor = Theme.Colors.primaryYellow
        button.layer.cornerRadius = 14
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = Theme.Colors.cardBackground
        selectionStyle = .none

        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(idLabel)
        contentView.addSubview(unblockButton)

        unblockButton.addTarget(self, action: #selector(unblockTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 48),
            avatarView.heightAnchor.constraint(equalToConstant: 48),

            nameLabel.topAnchor.constraint(equalTo: avatarView.topAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: unblockButton.leadingAnchor, constant: -12),

            idLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            idLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            idLabel.trailingAnchor.constraint(lessThanOrEqualTo: unblockButton.leadingAnchor, constant: -12),

            unblockButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            unblockButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            unblockButton.widthAnchor.constraint(equalToConstant: 82),
            unblockButton.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with user: User) {
        avatarView.image = user.displayAvatarImage ?? UIImage(named: user.avatarImage)
        nameLabel.text = user.name
        idLabel.text = "ID: \(user.id)"
    }

    @objc private func unblockTapped() {
        onUnblockTap?()
    }
}
