import UIKit

/// 忘记密码页 - 对应 Android GameMic 的 ForgetPasswordActivity
/// 表单：邮箱 + 新密码 + 确认密码
/// 重置成功后返回登录页
class ForgotPasswordViewController: UIViewController {

    // MARK: - UI 组件

    /// 大标题区域，对齐 Android 忘记密码页
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Forget"
        label.font = Theme.Fonts.bold(32)
        label.textColor = Theme.Colors.primaryYellow
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "The password"
        label.font = Theme.Fonts.regular(16)
        label.textColor = Theme.Colors.textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 邮箱输入框
    private let emailField: UITextField = createTextField(placeholder: "Email", isSecure: false)
    private let emailErrorLabel: UILabel = createErrorLabel()

    /// 新密码输入框
    private let newPasswordField: UITextField = createTextField(placeholder: "New Password", isSecure: true)
    private let newPasswordToggleButton: UIButton = createPasswordToggleButton()
    private let newPasswordErrorLabel: UILabel = createErrorLabel()

    /// 确认密码输入框
    private let confirmPasswordField: UITextField = createTextField(placeholder: "Confirm Password", isSecure: true)
    private let confirmPasswordToggleButton: UIButton = createPasswordToggleButton()
    private let confirmPasswordErrorLabel: UILabel = createErrorLabel()

    /// 重置按钮
    private let resetButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Continue", for: .normal)
        btn.setTitleColor(Theme.Colors.darkerBackground, for: .normal)
        btn.titleLabel?.font = Theme.Fonts.bold(16)
        btn.backgroundColor = Theme.Colors.primaryYellow
        btn.layer.cornerRadius = 16
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Forget"
        view.backgroundColor = Theme.Colors.darkBackground
        setupUI()
        setupActions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - 界面搭建

    private func setupUI() {
        navigationItem.leftBarButtonItem = makeAppBackButton(action: #selector(backTapped))

        emailField.keyboardType = .emailAddress

        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 64),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])

        let fields: [(UITextField, UILabel)] = [
            (emailField, emailErrorLabel),
            (newPasswordField, newPasswordErrorLabel),
            (confirmPasswordField, confirmPasswordErrorLabel)
        ]

        var previousAnchor = view.centerYAnchor
        var offset: CGFloat = -132

        for (field, errorLabel) in fields {
            view.addSubview(field)
            view.addSubview(errorLabel)

            NSLayoutConstraint.activate([
                field.topAnchor.constraint(equalTo: previousAnchor, constant: offset),
                field.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
                field.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
                field.heightAnchor.constraint(equalToConstant: 56),

                errorLabel.topAnchor.constraint(equalTo: field.bottomAnchor, constant: 4),
                errorLabel.leadingAnchor.constraint(equalTo: field.leadingAnchor, constant: 4)
            ])

            if field === newPasswordField {
                addPasswordToggle(newPasswordToggleButton, to: field)
            } else if field === confirmPasswordField {
                addPasswordToggle(confirmPasswordToggleButton, to: field)
            }

            previousAnchor = errorLabel.bottomAnchor
            offset = 12
        }

        view.addSubview(resetButton)
        NSLayoutConstraint.activate([
            resetButton.topAnchor.constraint(equalTo: confirmPasswordErrorLabel.bottomAnchor, constant: 32),
            resetButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            resetButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            resetButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    // MARK: - 事件

    private func setupActions() {
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
        newPasswordToggleButton.addTarget(self, action: #selector(toggleNewPassword), for: .touchUpInside)
        confirmPasswordToggleButton.addTarget(self, action: #selector(toggleConfirmPassword), for: .touchUpInside)
        emailField.addTarget(self, action: #selector(hideErrors), for: .editingChanged)
        newPasswordField.addTarget(self, action: #selector(hideErrors), for: .editingChanged)
        confirmPasswordField.addTarget(self, action: #selector(hideErrors), for: .editingChanged)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func toggleNewPassword() {
        newPasswordToggleButton.isSelected.toggle()
        newPasswordField.isSecureTextEntry = !newPasswordToggleButton.isSelected
    }

    @objc private func toggleConfirmPassword() {
        confirmPasswordToggleButton.isSelected.toggle()
        confirmPasswordField.isSecureTextEntry = !confirmPasswordToggleButton.isSelected
    }

    @objc private func hideErrors() {
        emailErrorLabel.isHidden = true
        newPasswordErrorLabel.isHidden = true
        confirmPasswordErrorLabel.isHidden = true
    }

    // MARK: - 重置密码验证（对应 Android ForgetPasswordActivity 验证逻辑）

    @objc private func resetTapped() {
        let email = emailField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let newPassword = newPasswordField.text ?? ""
        let confirmPassword = confirmPasswordField.text ?? ""

        // 隐藏所有错误
        [emailErrorLabel, newPasswordErrorLabel, confirmPasswordErrorLabel].forEach { $0.isHidden = true }

        // 邮箱不能为空
        guard !email.isEmpty else {
            showError(emailErrorLabel, "Please enter your email")
            return
        }

        // 邮箱格式
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        guard NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email) else {
            showError(emailErrorLabel, "Please enter the correct email format")
            return
        }

        // 邮箱必须已注册（对应 Android "Email not registered"）
        guard UserManager.shared.isEmailRegistered(email) else {
            showError(emailErrorLabel, "Email not registered")
            return
        }

        // 新密码不能为空
        guard !newPassword.isEmpty else {
            showError(newPasswordErrorLabel, "Please enter your password")
            return
        }

        // 新密码至少6位
        guard newPassword.count >= 6 else {
            showError(newPasswordErrorLabel, "Password must be at least 6 characters")
            return
        }

        // 确认密码不能为空
        guard !confirmPassword.isEmpty else {
            showError(confirmPasswordErrorLabel, "Please confirm your password")
            return
        }

        // 两次密码必须一致（对应 Android "The two passwords are inconsistent"）
        guard newPassword == confirmPassword else {
            showError(confirmPasswordErrorLabel, "The two passwords are inconsistent")
            return
        }

        // 重置密码
        if UserManager.shared.resetPassword(email, newPassword) {
            // 成功 → 返回登录页
            let alert = UIAlertController(title: nil, message: "Password reset successful", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            })
            present(alert, animated: true)
        }
    }

    /// 显示错误
    private func showError(_ label: UILabel, _ message: String) {
        label.text = message
        label.isHidden = false
    }

    private func addPasswordToggle(_ button: UIButton, to field: UITextField) {
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.centerYAnchor.constraint(equalTo: field.centerYAnchor),
            button.trailingAnchor.constraint(equalTo: field.trailingAnchor, constant: -12),
            button.widthAnchor.constraint(equalToConstant: 24),
            button.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    // MARK: - 工厂方法

    /// 创建统一样式的输入框
    private static func createTextField(placeholder: String, isSecure: Bool) -> UITextField {
        let tf = UITextField()
        tf.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [.foregroundColor: UIColor.lightGray])
        tf.isSecureTextEntry = isSecure
        tf.textColor = Theme.Colors.textPrimary
        tf.font = Theme.Fonts.regular(14)
        tf.backgroundColor = Theme.Colors.cardBackground
        tf.layer.cornerRadius = 16
        tf.layer.borderWidth = 1
        tf.layer.borderColor = Theme.Colors.textFieldBorder.cgColor
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 0))
        tf.leftViewMode = .always
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }

    private static func createPasswordToggleButton() -> UIButton {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "ic_password_hide"), for: .normal)
        btn.setImage(UIImage(named: "ic_password_show"), for: .selected)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }

    /// 创建统一样式的错误标签
    private static func createErrorLabel() -> UILabel {
        let label = UILabel()
        label.font = Theme.Fonts.regular(12)
        label.textColor = Theme.Colors.primaryYellow
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
}
