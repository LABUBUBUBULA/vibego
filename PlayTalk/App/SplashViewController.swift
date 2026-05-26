import UIKit

final class SplashViewController: UIViewController {
    private let minimumDisplayTime: TimeInterval = 0.8
    private var launchResult: LaunchService.LaunchResult?
    private var minTimeElapsed = false
    private var retryCount = 0
    private let maxRetries = 2
    private let launchPermissionWaitTime: TimeInterval = 8.0
    private var launchWaitDeadline: Date?
    private var hasStartedLaunch = false
    private var hasRouted = false

    private let logoView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "SplashLogo"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Voice Game Forum\nGroup Voice Chat"
        label.font = Theme.Fonts.bold(20)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 2
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 底部加载点动画容器
    private let dotsContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        for _ in 0..<3 {
            let dot = UIView()
            dot.backgroundColor = Theme.Colors.primaryYellow
            dot.layer.cornerRadius = 5
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.widthAnchor.constraint(equalToConstant: 10).isActive = true
            dot.heightAnchor.constraint(equalToConstant: 10).isActive = true
            dot.alpha = 0.3
            stack.addArrangedSubview(dot)
        }
        return stack
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#0A0626")
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard !hasStartedLaunch else { return }
        hasStartedLaunch = true

        // 启动动画
        startAnimations()

        // 同时进行：最短显示时间 + 启动接口请求
        DispatchQueue.main.asyncAfter(deadline: .now() + minimumDisplayTime) { [weak self] in
            self?.minTimeElapsed = true
            self?.routeIfReady()
        }

        // 首次网络权限弹窗可能阻塞启动接口；最多等待 8 秒，超时未回调则进入 A 包
        launchWaitDeadline = Date().addingTimeInterval(launchPermissionWaitTime)
        DispatchQueue.main.asyncAfter(deadline: .now() + launchPermissionWaitTime) { [weak self] in
            guard let self, self.launchResult == nil else { return }
            print("🟢 [Splash] 等待网络权限超时 → 使用默认启动路径")
            self.launchResult = .enterOriginal
            self.routeIfReady()
        }

        // 调启动接口判断启动路径
        fetchLaunch()
    }

    private func setupUI() {
        let stack = UIStackView(arrangedSubviews: [logoView, titleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 40
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        view.addSubview(dotsContainer)

        // Logo 初始缩小
        logoView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        logoView.alpha = 0

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),

            logoView.widthAnchor.constraint(equalToConstant: 120),
            logoView.heightAnchor.constraint(equalToConstant: 120),

            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            dotsContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dotsContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60),
        ])
    }

    // MARK: - 动画

    private func startAnimations() {
        // Logo 弹出 + 渐显
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            self.logoView.transform = .identity
            self.logoView.alpha = 1
        }

        // 标题渐显
        UIView.animate(withDuration: 0.5, delay: 0.3) {
            self.titleLabel.alpha = 1
        }

        // Logo 呼吸脉冲
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.startBreathingAnimation()
        }

        // 底部加载点波浪动画
        startDotsAnimation()
    }

    /// Logo 呼吸脉冲动画
    private func startBreathingAnimation() {
        UIView.animate(withDuration: 1.2, delay: 0, options: [.repeat, .autoreverse, .curveEaseInOut]) {
            self.logoView.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
        }
    }

    /// 底部三个点的波浪加载动画
    private func startDotsAnimation() {
        let dots = dotsContainer.arrangedSubviews
        for (index, dot) in dots.enumerated() {
            UIView.animate(withDuration: 0.5, delay: Double(index) * 0.2, options: [.repeat, .autoreverse, .curveEaseInOut]) {
                dot.alpha = 1.0
                dot.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            }
        }
    }

    /// 请求启动接口，网络失败自动重试（处理中国区首次安装网络权限弹窗）
    private func fetchLaunch() {
        LaunchService.shared.checkLaunch { [weak self] result in
            guard let self else { return }
            print("🟢 [Splash] 启动检查完成，retry=\(self.retryCount)")

            // A 包结果先等满启动缓冲期，避免首次网络权限还没选择就提前进入 A 包
            if case .enterOriginal = result,
               let deadline = self.launchWaitDeadline,
               Date() < deadline {
                self.retryCount += 1
                let delay = min(1.0, deadline.timeIntervalSinceNow)
                print("🟢 [Splash] 等待权限缓冲，\(delay)秒后重试(\(self.retryCount))")
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    self?.fetchLaunch()
                }
                return
            }

            self.launchResult = result
            self.routeIfReady()
        }
    }

    /// 两个条件都满足后路由
    private func routeIfReady() {
        guard !hasRouted, minTimeElapsed, let result = launchResult else { return }
        hasRouted = true

        guard let window = view.window else { return }

        let root: UIViewController
        switch result {
        case .enterOriginal:
            // 进入 A 包
            if UserManager.shared.isLoggedIn {
                root = AppNavigationController(rootViewController: MainTabBarController())
            } else {
                root = UINavigationController(rootViewController: WelcomeViewController())
            }

        case .enterWebLoggedIn(let url):
            let vc = WebContainerViewController()
            vc.loadURL = url
            root = UINavigationController(rootViewController: vc)

        case .enterWebNeedLogin(let url, let needLocation):
            let vc = QuickLoginViewController()
            vc.h5BaseURL = url
            vc.needLocation = needLocation
            root = UINavigationController(rootViewController: vc)
        }

        UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve) {
            window.rootViewController = root
        }
    }
}
