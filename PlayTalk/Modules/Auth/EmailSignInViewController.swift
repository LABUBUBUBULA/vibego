import UIKit

/// 邮箱登录页 - 对应 Android GameMic 的 EmailSignInActivity
/// 表单：邮箱 + 密码 + 密码显隐切换
/// 底部：忘记密码链接 + 注册链接
class EmailSignInViewController: UIViewController {

    // MARK: - UI 组件

    /// 大标题区域，对齐 Android：黄色 32sp 标题 + 白色副标题
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Sign In"
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

    /// 邮箱输入框（对应 Android et_account）
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
        tf.layer.borderColor = Theme.Colors.textFieldBorder.cgColor
        // 左侧内边距
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 0))
        tf.leftViewMode = .always
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    /// 邮箱错误提示（对应 Android tv_email_error）
    private let emailErrorLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.regular(12)
        label.textColor = Theme.Colors.primaryYellow
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 密码输入框（对应 Android et_password）
    private let passwordField: UITextField = {
        let tf = UITextField()
        tf.attributedPlaceholder = NSAttributedString(string: "Password", attributes: [.foregroundColor: UIColor.lightGray])
        tf.isSecureTextEntry = true
        tf.textColor = Theme.Colors.textPrimary
        tf.font = Theme.Fonts.regular(14)
        tf.backgroundColor = Theme.Colors.cardBackground
        tf.layer.cornerRadius = 16
        tf.layer.borderWidth = 1
        tf.layer.borderColor = Theme.Colors.textFieldBorder.cgColor
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 0))
        tf.leftViewMode = .always
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    /// 密码显隐切换按钮（对应 Android iv_password_toggle）
    private let passwordToggleButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "ic_password_hide"), for: .normal)
        btn.setImage(UIImage(named: "ic_password_show"), for: .selected)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    /// 密码错误提示（对应 Android tv_password_error）
    private let passwordErrorLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.regular(12)
        label.textColor = Theme.Colors.primaryYellow
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 登录按钮（对应 Android btn_sign_in）
    private let signInButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Sign In", for: .normal)
        btn.setTitleColor(Theme.Colors.darkerBackground, for: .normal)
        btn.titleLabel?.font = Theme.Fonts.bold(16)
        btn.backgroundColor = Theme.Colors.primaryYellow
        btn.layer.cornerRadius = 16
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    /// 忘记密码链接（对应 Android tv_forget_password）
    private let forgotPasswordButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Forget the password", for: .normal)
        btn.setTitleColor(Theme.Colors.primaryYellow, for: .normal)
        btn.titleLabel?.font = Theme.Fonts.regular(14)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    /// 注册链接（对应 Android tv_register）
    private let registerButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Register", for: .normal)
        btn.setTitleColor(Theme.Colors.primaryYellow, for: .normal)
        btn.titleLabel?.font = Theme.Fonts.medium(14)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Sign In"
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
        // 返回按钮样式
        navigationItem.leftBarButtonItem = makeAppBackButton(action: #selector(backTapped))

        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(emailField)
        view.addSubview(emailErrorLabel)
        view.addSubview(passwordField)
        view.addSubview(passwordToggleButton)
        view.addSubview(passwordErrorLabel)
        view.addSubview(signInButton)
        view.addSubview(forgotPasswordButton)
        view.addSubview(registerButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 64),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),

            // 表单居中偏上，复刻 Android centerVertical 表单区域
            emailField.topAnchor.constraint(equalTo: view.centerYAnchor, constant: -88),
            emailField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emailField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            emailField.heightAnchor.constraint(equalToConstant: 56),

            // 邮箱错误提示
            emailErrorLabel.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 4),
            emailErrorLabel.leadingAnchor.constraint(equalTo: emailField.leadingAnchor, constant: 4),

            // 密码输入框
            passwordField.topAnchor.constraint(equalTo: emailErrorLabel.bottomAnchor, constant: 12),
            passwordField.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            passwordField.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            passwordField.heightAnchor.constraint(equalToConstant: 56),

            // 密码显隐按钮（密码框内右侧）
            passwordToggleButton.centerYAnchor.constraint(equalTo: passwordField.centerYAnchor),
            passwordToggleButton.trailingAnchor.constraint(equalTo: passwordField.trailingAnchor, constant: -12),
            passwordToggleButton.widthAnchor.constraint(equalToConstant: 24),
            passwordToggleButton.heightAnchor.constraint(equalToConstant: 24),

            // 密码错误提示
            passwordErrorLabel.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 4),
            passwordErrorLabel.leadingAnchor.constraint(equalTo: passwordField.leadingAnchor, constant: 4),

            // 登录按钮
            signInButton.topAnchor.constraint(equalTo: passwordErrorLabel.bottomAnchor, constant: 32),
            signInButton.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            signInButton.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            signInButton.heightAnchor.constraint(equalToConstant: 56),

            // 忘记密码和注册沿用 Android：同一行左右分布
            forgotPasswordButton.topAnchor.constraint(equalTo: signInButton.bottomAnchor, constant: 20),
            forgotPasswordButton.leadingAnchor.constraint(equalTo: signInButton.leadingAnchor),

            registerButton.centerYAnchor.constraint(equalTo: forgotPasswordButton.centerYAnchor),
            registerButton.trailingAnchor.constraint(equalTo: signInButton.trailingAnchor)
        ])
    }

    // MARK: - 事件绑定

    private func setupActions() {
        signInButton.addTarget(self, action: #selector(signInTapped), for: .touchUpInside)
        forgotPasswordButton.addTarget(self, action: #selector(forgotPasswordTapped), for: .touchUpInside)
        registerButton.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)
        passwordToggleButton.addTarget(self, action: #selector(togglePassword), for: .touchUpInside)

        // 输入时隐藏错误提示（对应 Android TextWatcher）
        emailField.addTarget(self, action: #selector(hideEmailError), for: .editingChanged)
        passwordField.addTarget(self, action: #selector(hidePasswordError), for: .editingChanged)
    }

    /// 返回按钮
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    /// 密码显隐切换（对应 Android PasswordToggleHelper）
    @objc private func togglePassword() {
        passwordToggleButton.isSelected.toggle()
        passwordField.isSecureTextEntry = !passwordToggleButton.isSelected
    }

    /// 输入时隐藏邮箱错误
    @objc private func hideEmailError() {
        emailErrorLabel.isHidden = true
    }

    /// 输入时隐藏密码错误
    @objc private func hidePasswordError() {
        passwordErrorLabel.isHidden = true
    }

    // MARK: - 登录验证（对应 Android 验证逻辑）

    /// 登录按钮点击
    @objc private func signInTapped() {
        let email = emailField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let password = passwordField.text ?? ""

        // 邮箱验证：不能为空
        guard !email.isEmpty else {
            showError(emailErrorLabel, "Please enter your email")
            return
        }

        // 邮箱验证：格式正确（对应 Android Patterns.EMAIL_ADDRESS）
        guard isValidEmail(email) else {
            showError(emailErrorLabel, "Please enter the correct email format")
            return
        }

        // 密码验证：不能为空
        guard !password.isEmpty else {
            showError(passwordErrorLabel, "Please enter your password")
            return
        }

        // 调用 UserManager 登录
        if UserManager.shared.loginWithEmail(email, password) {
            // 登录成功 → 跳转主页
            navigateToMain()
        } else {
            // 登录失败
            showError(passwordErrorLabel, "Invalid email or password")
        }
    }

    /// 忘记密码点击 → ForgetPasswordActivity
    @objc private func forgotPasswordTapped() {
        let vc = ForgotPasswordViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    /// 注册链接点击 → EmailRegisterActivity
    @objc private func registerTapped() {
        let vc = EmailRegisterViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - 工具方法

    /// 邮箱格式验证（对应 Android Patterns.EMAIL_ADDRESS）
    private func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }

    /// 显示错误信息
    private func showError(_ label: UILabel, _ message: String) {
        label.text = message
        label.isHidden = false
    }

    /// 跳转主页（替换根控制器）
    private func navigateToMain() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        window.rootViewController = AppNavigationController(rootViewController: MainTabBarController())
        window.makeKeyAndVisible()
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
    }
}
