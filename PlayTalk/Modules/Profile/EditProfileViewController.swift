import UIKit

/// 编辑资料页 - 对应 Android GameMic 的 EditProfileActivity
/// 表单：头像、昵称、签名、性别
class EditProfileViewController: UIViewController {

    // MARK: - UI 组件

    /// 头像区域
    private let avatarView: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.Colors.primaryYellow.withAlphaComponent(0.3)
        v.layer.cornerRadius = 45
        v.layer.borderWidth = 2
        v.layer.borderColor = Theme.Colors.primaryYellow.cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let avatarLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.bold(28)
        label.textColor = Theme.Colors.primaryYellow
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 昵称输入框
    private let nicknameField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Nickname"
        tf.textColor = Theme.Colors.textPrimary
        tf.font = Theme.Fonts.regular(16)
        tf.backgroundColor = Theme.Colors.cardBackground
        tf.layer.cornerRadius = 12
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.leftViewMode = .always
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    /// 签名输入框
    private let bioField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Bio"
        tf.textColor = Theme.Colors.textPrimary
        tf.font = Theme.Fonts.regular(16)
        tf.backgroundColor = Theme.Colors.cardBackground
        tf.layer.cornerRadius = 12
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.leftViewMode = .always
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    /// 保存按钮
    private let saveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Save", for: .normal)
        btn.setTitleColor(Theme.Colors.darkerBackground, for: .normal)
        btn.titleLabel?.font = Theme.Fonts.bold(16)
        btn.backgroundColor = Theme.Colors.primaryYellow
        btn.layer.cornerRadius = 25
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Edit Profile"
        view.backgroundColor = Theme.Colors.darkBackground
        setupUI()
        loadCurrentProfile()
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
    }

    // MARK: - 界面搭建

    private func setupUI() {
        view.addSubview(avatarView)
        avatarView.addSubview(avatarLabel)
        view.addSubview(nicknameField)
        view.addSubview(bioField)
        view.addSubview(saveButton)

        NSLayoutConstraint.activate([
            avatarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            avatarView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 90),
            avatarView.heightAnchor.constraint(equalToConstant: 90),

            avatarLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),

            nicknameField.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 32),
            nicknameField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            nicknameField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            nicknameField.heightAnchor.constraint(equalToConstant: 50),

            bioField.topAnchor.constraint(equalTo: nicknameField.bottomAnchor, constant: 16),
            bioField.leadingAnchor.constraint(equalTo: nicknameField.leadingAnchor),
            bioField.trailingAnchor.constraint(equalTo: nicknameField.trailingAnchor),
            bioField.heightAnchor.constraint(equalToConstant: 50),

            saveButton.topAnchor.constraint(equalTo: bioField.bottomAnchor, constant: 40),
            saveButton.leadingAnchor.constraint(equalTo: nicknameField.leadingAnchor),
            saveButton.trailingAnchor.constraint(equalTo: nicknameField.trailingAnchor),
            saveButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    /// 加载当前用户资料
    private func loadCurrentProfile() {
        let user = UserManager.shared.currentUser ?? MockDataManager.shared.users[0]
        avatarLabel.text = String(user.name.prefix(1))
        nicknameField.text = user.name
        bioField.text = user.bio
    }

    /// 保存资料
    @objc private func saveTapped() {
        let nickname = nicknameField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !nickname.isEmpty else { return }

        // 通过UserManager的方法更新资料
        UserManager.shared.updateUserProfile(
            nickname: nickname,
            gender: UserManager.shared.currentUser?.gender ?? "male",
            avatarUri: nil,
            country: "",
            countryFlag: "",
            interests: UserManager.shared.currentUser?.interests ?? "",
            bio: bioField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        )

        navigationController?.popViewController(animated: true)
    }
}
