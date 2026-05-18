import UIKit

/// 忘记密码页 - 对应 Android GameMic 的 ForgetPasswordActivity
/// 表单：邮箱 + 新密码 + 确认密码
/// 重置成功后返回登录页
class ForgotPasswordViewController: UIViewController {

    // MARK: - UI 组件

    /// 邮箱输入框
    private let emailField: UITextField = createTextField(placeholder: "Email", isSecure: false)
    private let emailErrorLabel: UILabel = createErrorLabel()

    /// 新密码输入框
    private let newPasswordField: UITextField = createTextField(placeholder: "New Password", isSecure: true)
    private let newPasswordErrorLabel: UILabel = createErrorLabel()

    /// 确认密码输入框
    private let confirmPasswordField: UITextField = createTextField(placeholder: "Confirm Password", isSecure: true)
    private let confirmPasswordErrorLabel: UILabel = createErrorLabel()

    /// 重置按钮
    private let resetButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Reset Password", for: .normal)
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
        title = "Reset Password"
        view.backgroundColor = Theme.Colors.darkBackground
        setupUI()
        setupActions()
    }

    // MARK: - 界面搭建

    private func setupUI() {
        navigationItem.leftBarButtonItem = makeAppBackButton(action: #selector(backTapped))

        let fields: [(UITextField, UILabel)] = [
            (emailField, emailErrorLabel),
            (newPasswordField, newPasswordErrorLabel),
            (confirmPasswordField, confirmPasswordErrorLabel)
        ]

        var previousAnchor = view.safeAreaLayoutGuide.topAnchor
        var offset: CGFloat = 40

        for (field, errorLabel) in fields {
            view.addSubview(field)
            view.addSubview(errorLabel)

            NSLayoutConstraint.activate([
                field.topAnchor.constraint(equalTo: previousAnchor, constant: offset),
                field.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
                field.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
                field.heightAnchor.constraint(equalToConstant: 50),

                errorLabel.topAnchor.constraint(equalTo: field.bottomAnchor, constant: 4),
                errorLabel.leadingAnchor.constraint(equalTo: field.leadingAnchor, constant: 4)
            ])

            previousAnchor = errorLabel.bottomAnchor
            offset = 12
        }

        view.addSubview(resetButton)
        NSLayoutConstraint.activate([
            resetButton.topAnchor.constraint(equalTo: confirmPasswordErrorLabel.bottomAnchor, constant: 32),
            resetButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            resetButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            resetButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    // MARK: - 事件

    private func setupActions() {
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
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

    // MARK: - 工厂方法

    /// 创建统一样式的输入框
    private static func createTextField(placeholder: String, isSecure: Bool) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.isSecureTextEntry = isSecure
        tf.textColor = Theme.Colors.textPrimary
        tf.font = Theme.Fonts.regular(16)
        tf.backgroundColor = Theme.Colors.cardBackground
        tf.layer.cornerRadius = 12
        tf.layer.borderWidth = 1
        tf.layer.borderColor = Theme.Colors.separator.cgColor
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.leftViewMode = .always
        tf.autocapitalizationType = .none
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }

    /// 创建统一样式的错误标签
    private static func createErrorLabel() -> UILabel {
        let label = UILabel()
        label.font = Theme.Fonts.regular(12)
        label.textColor = .systemRed
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
}
