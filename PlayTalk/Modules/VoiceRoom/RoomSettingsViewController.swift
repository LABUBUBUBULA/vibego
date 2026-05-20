import UIKit

final class RoomSettingsViewController: UIViewController {

    var room: VoiceRoom?
    var onRoomUpdated: ((VoiceRoom) -> Void)?

    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let contentView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 30
        imageView.layer.masksToBounds = true
        imageView.backgroundColor = Theme.Colors.cardBackground
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let roomNameField = makeField(placeholder: "Boase's room", isSecure: false)
    private let introField = makeField(placeholder: "Chat together...", isSecure: false)
    private let passwordField = makeField(placeholder: "javbsdihfges", isSecure: true)

    private let charmSwitch: UISwitch = {
        let control = UISwitch()
        control.isOn = true
        control.onTintColor = Theme.Colors.primaryYellow
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Room settings"
        view.backgroundColor = Theme.Colors.darkBackground
        setupNavigation()
        setupUI()
        loadRoomData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func setupNavigation() {
        navigationItem.leftBarButtonItem = makeAppBackButton(action: #selector(backTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveTapped))
        navigationItem.rightBarButtonItem?.tintColor = Theme.Colors.primaryYellow
    }

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24)
        ])

        contentView.addArrangedSubview(makeCoverRow())
        contentView.addArrangedSubview(makeDivider())
        contentView.addArrangedSubview(makeFieldRow(title: "Name:", field: roomNameField))
        contentView.addArrangedSubview(makeDivider())
        contentView.addArrangedSubview(makeFieldRow(title: "Introduction:", field: introField))
        contentView.addArrangedSubview(makeDivider())
        contentView.addArrangedSubview(makeFieldRow(title: "Password:", field: passwordField))
        contentView.addArrangedSubview(makeDivider())
        contentView.addArrangedSubview(makeSwitchRow(title: "Enable charm value", control: charmSwitch))
        contentView.addArrangedSubview(makeDivider())
        contentView.addArrangedSubview(makeActionRow(title: "Release notification", action: #selector(releaseNotificationTapped)))
        contentView.addArrangedSubview(makeDivider())
        contentView.addArrangedSubview(makeActionRow(title: "Admins", action: #selector(adminsTapped)))
        contentView.addArrangedSubview(makeDivider())
        contentView.addArrangedSubview(makeActionRow(title: "Blacklist", action: #selector(blacklistTapped)))
        contentView.addArrangedSubview(makeDivider())
        contentView.addArrangedSubview(makeActionRow(title: "Forbidden List", action: #selector(forbiddenListTapped)))
    }

    private func loadRoomData() {
        guard let room else { return }
        roomNameField.text = room.roomName
        introField.text = room.description
        if let coverUri = room.coverUri {
            coverImageView.image = UIImage(contentsOfFile: coverUri) ?? UIImage(named: room.coverImage)
        } else {
            coverImageView.image = UIImage(named: room.coverImage)
        }
    }

    private func makeCoverRow() -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        let label = makeTitleLabel("Room cover settings")
        row.addSubview(coverImageView)
        row.addSubview(label)
        row.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(roomCoverTapped)))

        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 84),
            coverImageView.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            coverImageView.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            coverImageView.widthAnchor.constraint(equalToConstant: 60),
            coverImageView.heightAnchor.constraint(equalToConstant: 60),

            label.leadingAnchor.constraint(equalTo: coverImageView.trailingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: row.trailingAnchor)
        ])
        return row
    }

    private func makeFieldRow(title: String, field: UITextField) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        let label = makeTitleLabel(title)
        row.addSubview(label)
        row.addSubview(field)

        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 56),
            label.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            label.widthAnchor.constraint(equalToConstant: 140),

            field.leadingAnchor.constraint(equalTo: label.trailingAnchor),
            field.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            field.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            field.heightAnchor.constraint(equalToConstant: 44)
        ])
        return row
    }

    private func makeSwitchRow(title: String, control: UISwitch) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        let label = makeTitleLabel(title)
        row.addSubview(label)
        row.addSubview(control)

        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 56),
            label.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: control.leadingAnchor, constant: -12),

            control.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            control.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])
        return row
    }

    private func makeActionRow(title: String, action: Selector) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        let label = makeTitleLabel(title)
        let arrow = UIImageView(image: UIImage(named: "ic_arrow_right")?.withRenderingMode(.alwaysTemplate))
        arrow.tintColor = Theme.Colors.textSecondary
        arrow.contentMode = .scaleAspectFit
        arrow.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(label)
        row.addSubview(arrow)
        row.addGestureRecognizer(UITapGestureRecognizer(target: self, action: action))

        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 56),
            label.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: arrow.leadingAnchor, constant: -12),

            arrow.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            arrow.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            arrow.widthAnchor.constraint(equalToConstant: 24),
            arrow.heightAnchor.constraint(equalToConstant: 24)
        ])
        return row
    }

    private func makeTitleLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = Theme.Fonts.regular(16)
        label.textColor = Theme.Colors.textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private func makeDivider() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return view
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func saveTapped() {
        let name = roomNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else {
            showToast("Please enter room name")
            return
        }
        guard var updatedRoom = room else { return }
        updatedRoom.roomName = name
        updatedRoom.title = name
        updatedRoom.description = introField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? updatedRoom.description
        room = updatedRoom
        MockDataManager.shared.updateUserCreatedRoom(updatedRoom)
        onRoomUpdated?(updatedRoom)
        showToast("Settings saved")
        navigationController?.popViewController(animated: true)
    }

    @objc private func roomCoverTapped() {
        showToast("Room cover settings")
    }

    @objc private func releaseNotificationTapped() {
        showToast("Release notification")
    }

    @objc private func adminsTapped() {
        showToast("Admins")
    }

    @objc private func blacklistTapped() {
        showToast("Blacklist")
    }

    @objc private func forbiddenListTapped() {
        showToast("Forbidden List")
    }

    private static func makeField(placeholder: String, isSecure: Bool) -> UITextField {
        let field = UITextField()
        field.placeholder = placeholder
        field.isSecureTextEntry = isSecure
        field.font = Theme.Fonts.regular(16)
        field.textColor = Theme.Colors.textSecondary
        field.tintColor = Theme.Colors.primaryYellow
        field.textAlignment = .right
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.backgroundColor = .clear
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }
}
