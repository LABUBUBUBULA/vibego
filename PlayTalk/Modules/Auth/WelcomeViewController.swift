import UIKit

/// 欢迎页 - 对应 Android GameMic 的 WelcomeActivity
/// 布局：Logo + Quick Register按钮 + Email Sign In链接 + 协议勾选
/// 入口页面，用户选择快速注册或邮箱登录
class WelcomeViewController: UIViewController {

    // MARK: - 状态

    /// 是否同意协议（对应 Android isAgreed）
    private var isAgreed = false

    // MARK: - UI 组件

    /// Logo图片
    private let logoImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "logo")
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    /// App名称标题
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "PlayTalk"
        label.font = Theme.Fonts.bold(32)
        label.textColor = Theme.Colors.primaryYellow
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 副标题
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Voice Game Forum, Group Voice Chat"
        label.font = Theme.Fonts.regular(14)
        label.textColor = Theme.Colors.textSecondary
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 快速注册按钮（对应 Android btn_quick_register）
    private let quickRegisterButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Quick Register", for: .normal)
        btn.setTitleColor(Theme.Colors.darkerBackground, for: .normal)
        btn.titleLabel?.font = Theme.Fonts.bold(16)
        btn.backgroundColor = Theme.Colors.primaryYellow
        btn.layer.cornerRadius = 25
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    /// 邮箱登录链接（对应 Android tv_email_sign_in）
    private let emailSignInButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Sign in with Email", for: .normal)
        btn.setTitleColor(Theme.Colors.primaryYellow, for: .normal)
        btn.titleLabel?.font = Theme.Fonts.medium(14)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    /// 协议勾选框（对应 Android iv_checkbox）
    private let checkboxButton: UIButton = {
        let btn = UIButton(type: .custom)
        // 使用系统图标确保显示（资源图片在虚拟机上可能加载失败）
        let uncheckedImage = UIImage(named: "ic_checkbox_unchecked") ?? UIImage(systemName: "square")
        let checkedImage = UIImage(named: "ic_checkbox_checked") ?? UIImage(systemName: "checkmark.square.fill")
        btn.setImage(uncheckedImage, for: .normal)
        btn.setImage(checkedImage, for: .selected)
        btn.tintColor = Theme.Colors.primaryYellow
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    /// 协议文字（对应 Android tv_terms + tv_privacy）
    private let termsLabel: UILabel = {
        let label = UILabel()
        label.text = "I agree to Terms of Service and Privacy Policy"
        label.font = Theme.Fonts.regular(12)
        label.textColor = Theme.Colors.textSecondary
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Colors.darkBackground
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupUI()
        setupActions()
    }

    // MARK: - 界面搭建

    private func setupUI() {
        view.addSubview(logoImageView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(quickRegisterButton)
        view.addSubview(emailSignInButton)
        view.addSubview(checkboxButton)
        view.addSubview(termsLabel)

        NSLayoutConstraint.activate([
            // Logo（居中偏上）
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            logoImageView.widthAnchor.constraint(equalToConstant: 120),
            logoImageView.heightAnchor.constraint(equalToConstant: 120),

            // 标题
            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 24),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // 副标题
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // 快速注册按钮（50dp高度，底部区域）
            quickRegisterButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            quickRegisterButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            quickRegisterButton.bottomAnchor.constraint(equalTo: emailSignInButton.topAnchor, constant: -16),
            quickRegisterButton.heightAnchor.constraint(equalToConstant: 50),

            // 邮箱登录链接
            emailSignInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emailSignInButton.bottomAnchor.constraint(equalTo: checkboxButton.topAnchor, constant: -24),

            // 协议勾选区域（底部安全区域上方）
            checkboxButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            checkboxButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            checkboxButton.widthAnchor.constraint(equalToConstant: 24),
            checkboxButton.heightAnchor.constraint(equalToConstant: 24),

            termsLabel.centerYAnchor.constraint(equalTo: checkboxButton.centerYAnchor),
            termsLabel.leadingAnchor.constraint(equalTo: checkboxButton.trailingAnchor, constant: 8),
            termsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }

    // MARK: - 事件绑定

    private func setupActions() {
        quickRegisterButton.addTarget(self, action: #selector(quickRegisterTapped), for: .touchUpInside)
        emailSignInButton.addTarget(self, action: #selector(emailSignInTapped), for: .touchUpInside)
        checkboxButton.addTarget(self, action: #selector(checkboxTapped), for: .touchUpInside)
    }

    /// 勾选框点击 - 切换同意状态（对应 Android checkbox toggle）
    @objc private func checkboxTapped() {
        isAgreed.toggle()
        checkboxButton.isSelected = isAgreed
    }

    /// 快速注册点击（对应 Android Quick Register → quickRegister → MainActivity）
    @objc private func quickRegisterTapped() {
        // 必须勾选协议
        guard isAgreed else {
            showToast("Please agree to Terms of Service and Privacy Policy")
            return
        }
        // 快速注册
        let user = UserManager.shared.quickRegister()
        showToast("Welcome! Your ID: \(user.id)")

        // 跳转主页（清空导航栈）
        navigateToMain()
    }

    /// 邮箱登录点击（对应 Android → EmailSignInActivity）
    @objc private func emailSignInTapped() {
        guard isAgreed else {
            showToast("Please agree to Terms of Service and Privacy Policy")
            return
        }
        let signInVC = EmailSignInViewController()
        navigationController?.pushViewController(signInVC, animated: true)
    }

    // MARK: - 导航

    /// 跳转到主页（替换根视图控制器，对应 Android FLAG_ACTIVITY_CLEAR_TASK）
    private func navigateToMain() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        window.rootViewController = MainTabBarController()
        window.makeKeyAndVisible()
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
    }

    // MARK: - Toast 提示

    /// 显示 Toast 消息（对应 Android Toast.makeText）
    private func showToast(_ message: String) {
        let toast = UILabel()
        toast.text = message
        toast.font = Theme.Fonts.regular(14)
        toast.textColor = .white
        toast.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toast.textAlignment = .center
        toast.layer.cornerRadius = 8
        toast.layer.masksToBounds = true
        toast.numberOfLines = 0
        toast.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toast)

        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),
            toast.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            toast.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40),
            toast.heightAnchor.constraint(greaterThanOrEqualToConstant: 36)
        ])

        // 2秒后自动消失
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            UIView.animate(withDuration: 0.3, animations: { toast.alpha = 0 }) { _ in
                toast.removeFromSuperview()
            }
        }
    }
}
