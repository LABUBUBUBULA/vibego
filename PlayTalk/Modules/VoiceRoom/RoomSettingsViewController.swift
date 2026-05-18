import UIKit

final class RoomSettingsViewController: UIViewController {

    private let infoLabel: UILabel = {
        let label = UILabel()
        label.text = "Room settings"
        label.font = Theme.Fonts.bold(22)
        label.textColor = Theme.Colors.textPrimary
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Room-level options come here later"
        label.font = Theme.Fonts.regular(14)
        label.textColor = Theme.Colors.textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Room Settings"
        view.backgroundColor = Theme.Colors.darkBackground
        setupUI()
    }

    private func setupUI() {
        view.addSubview(infoLabel)
        view.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            infoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            infoLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -12),
            subtitleLabel.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }
}
