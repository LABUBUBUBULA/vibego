import UIKit

/// 邮箱注册页 - 对应 Android GameMic 的 EmailRegisterActivity
/// 表单：邮箱 + 密码（≥6位） + 协议勾选
/// 注册成功后跳转 CompleteProfileViewController 完善资料
class EmailRegisterViewController: UIViewController {

    // MARK: - UI 组件

    /// 大标题区域，对齐 Android 注册页
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Register"
        label.font = Theme.Fonts.bold(32)
        label.textColor = Theme.Colors.primaryYellow
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "To a mailbox"
        label.font = Theme.Fonts.regular(16)
        label.textColor = Theme.Colors.textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 邮箱输入框
    private let emailField: UITextField = {
        let tf = UITextField()
        tf.attributedPlaceholder = NSAttributedString(string: "Email", attributes: [.foregroundColor: UIColor.lightGray])
        tf.keyboardType = .emailAddress
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.textColor = Theme.Colors.textPrimary
        tf.font = Theme.Fonts.regular(14)
        tf.backgroundColor = Theme.Colors.cardBackground
        tf.layer.cornerRadius = 16
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor(hex: "#343545").cgColor
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 0))
        tf.leftViewMode = .always
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    /// 邮箱错误提示
    private let emailErrorLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.regular(12)
        label.textColor = Theme.Colors.primaryYellow
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 密码输入框
    private let passwordField: UITextField = {
        let tf = UITextField()
        tf.attributedPlaceholder = NSAttributedString(string: "Password (min 6 characters)", attributes: [.foregroundColor: UIColor.lightGray])
        tf.isSecureTextEntry = true
        tf.textColor = Theme.Colors.textPrimary
        tf.font = Theme.Fonts.regular(14)
        tf.backgroundColor = Theme.Colors.cardBackground
        tf.layer.cornerRadius = 16
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor(hex: "#343545").cgColor
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 0))
        tf.leftViewMode = .always
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    /// 密码显隐按钮
    private let passwordToggleButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "ic_password_hide"), for: .normal)
        btn.setImage(UIImage(named: "ic_password_show"), for: .selected)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    /// 密码错误提示
    private let passwordErrorLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.regular(12)
        label.textColor = Theme.Colors.primaryYellow
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 注册按钮
    private let registerButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Register", for: .normal)
        btn.setTitleColor(Theme.Colors.darkerBackground, for: .normal)
        btn.titleLabel?.font = Theme.Fonts.bold(16)
        btn.backgroundColor = Theme.Colors.primaryYellow
        btn.layer.cornerRadius = 16
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let agreementStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let agreementPrefixLabel: UILabel = {
        let label = UILabel()
        label.text = "By registering, you agree to"
        label.font = Theme.Fonts.regular(12)
        label.textColor = Theme.Colors.textSecondary
        return label
    }()

    private let termsButton: UIButton = {
        let btn = UIButton(type: .system)
        let title = NSAttributedString(
            string: "Terms",
            attributes: [
                .font: Theme.Fonts.medium(12),
                .foregroundColor: Theme.Colors.primaryYellow,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
        )
        btn.setAttributedTitle(title, for: .normal)
        return btn
    }()

    private let agreementAndLabel: UILabel = {
        let label = UILabel()
        label.text = "and"
        label.font = Theme.Fonts.regular(12)
        label.textColor = Theme.Colors.textSecondary
        return label
    }()

    private let privacyButton: UIButton = {
        let btn = UIButton(type: .system)
        let title = NSAttributedString(
            string: "Privacy Policy",
            attributes: [
                .font: Theme.Fonts.medium(12),
                .foregroundColor: Theme.Colors.primaryYellow,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
        )
        btn.setAttributedTitle(title, for: .normal)
        return btn
    }()

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Register"
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

        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(emailField)
        view.addSubview(emailErrorLabel)
        view.addSubview(passwordField)
        view.addSubview(passwordToggleButton)
        view.addSubview(passwordErrorLabel)
        view.addSubview(registerButton)
        view.addSubview(agreementStack)
        agreementStack.addArrangedSubview(agreementPrefixLabel)
        agreementStack.addArrangedSubview(termsButton)
        agreementStack.addArrangedSubview(agreementAndLabel)
        agreementStack.addArrangedSubview(privacyButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 64),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),

            emailField.topAnchor.constraint(equalTo: view.centerYAnchor, constant: -88),
            emailField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emailField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            emailField.heightAnchor.constraint(equalToConstant: 56),

            emailErrorLabel.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 4),
            emailErrorLabel.leadingAnchor.constraint(equalTo: emailField.leadingAnchor, constant: 4),

            passwordField.topAnchor.constraint(equalTo: emailErrorLabel.bottomAnchor, constant: 12),
            passwordField.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            passwordField.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            passwordField.heightAnchor.constraint(equalToConstant: 56),

            passwordToggleButton.centerYAnchor.constraint(equalTo: passwordField.centerYAnchor),
            passwordToggleButton.trailingAnchor.constraint(equalTo: passwordField.trailingAnchor, constant: -12),
            passwordToggleButton.widthAnchor.constraint(equalToConstant: 24),
            passwordToggleButton.heightAnchor.constraint(equalToConstant: 24),

            passwordErrorLabel.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 4),
            passwordErrorLabel.leadingAnchor.constraint(equalTo: passwordField.leadingAnchor, constant: 4),

            registerButton.topAnchor.constraint(equalTo: passwordErrorLabel.bottomAnchor, constant: 32),
            registerButton.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            registerButton.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            registerButton.heightAnchor.constraint(equalToConstant: 56),

            agreementStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            agreementStack.leadingAnchor.constraint(greaterThanOrEqualTo: emailField.leadingAnchor),
            agreementStack.trailingAnchor.constraint(lessThanOrEqualTo: emailField.trailingAnchor),
            agreementStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
    }

    // MARK: - 事件绑定

    private func setupActions() {
        registerButton.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)
        passwordToggleButton.addTarget(self, action: #selector(togglePassword), for: .touchUpInside)
        termsButton.addTarget(self, action: #selector(termsTapped), for: .touchUpInside)
        privacyButton.addTarget(self, action: #selector(privacyTapped), for: .touchUpInside)
        emailField.addTarget(self, action: #selector(hideErrors), for: .editingChanged)
        passwordField.addTarget(self, action: #selector(hideErrors), for: .editingChanged)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func togglePassword() {
        passwordToggleButton.isSelected.toggle()
        passwordField.isSecureTextEntry = !passwordToggleButton.isSelected
    }

    @objc private func termsTapped() {
        navigationController?.pushViewController(LegalTextViewController(type: .terms), animated: true)
    }

    @objc private func privacyTapped() {
        navigationController?.pushViewController(LegalTextViewController(type: .privacy), animated: true)
    }

    @objc private func hideErrors() {
        emailErrorLabel.isHidden = true
        passwordErrorLabel.isHidden = true
    }

    // MARK: - 注册验证（对应 Android 验证逻辑）

    /// 注册按钮点击
    @objc private func registerTapped() {
        let email = emailField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let password = passwordField.text ?? ""

        // 邮箱不能为空
        guard !email.isEmpty else {
            showError(emailErrorLabel, "Please enter your email")
            return
        }

        // 邮箱格式验证
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        guard NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email) else {
            showError(emailErrorLabel, "Please enter the correct email format")
            return
        }

        // 检查邮箱是否已注册（对应 Android "This email is already registered"）
        guard !UserManager.shared.isEmailRegistered(email) else {
            showError(emailErrorLabel, "This email is already registered")
            return
        }

        // 密码不能为空
        guard !password.isEmpty else {
            showError(passwordErrorLabel, "Please enter your password")
            return
        }

        // 密码至少6位（对应 Android 验证规则）
        guard password.count >= 6 else {
            showError(passwordErrorLabel, "Password must be at least 6 characters")
            return
        }

        // 注册
        if let userId = UserManager.shared.registerWithEmail(email, password) {
            // 注册成功 → 跳转完善资料页
            let vc = CompleteProfileViewController()
            vc.userId = "\(userId)"
            vc.email = email
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    /// 显示错误
    private func showError(_ label: UILabel, _ message: String) {
        label.text = message
        label.isHidden = false
    }
}
