import UIKit
import CoreLocation

/// B 包快速登录页
/// 基于 WelcomeViewController 风格，去掉邮箱登录，只保留快速登录按钮
/// 登录接口: /opi/v1/user/portal (末尾 l)
class QuickLoginViewController: UIViewController, CLLocationManagerDelegate {

    // MARK: - 外部传入

    var h5BaseURL: String = ""
    var needLocation: Bool = false

    // MARK: - 定位

    private var locationManager: CLLocationManager?
    private var userLocation: CLLocation?

    // MARK: - 隐藏 WebView（提前加载 H5）

    private var preloadWebView: WebContainerViewController?

    // MARK: - UI（仿 GameMic Android 风格）

    /// 全屏背景图
    private let bgImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "bg_web_loading"))
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    /// 底部渐变遮罩（让按钮区域可读）
    private let bottomGradient: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let quickLoginButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Quick registration", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        btn.titleLabel?.font = Theme.Fonts.bold(16)
        btn.backgroundColor = Theme.Colors.primaryYellow
        btn.layer.cornerRadius = 25
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let ind = UIActivityIndicatorView(style: .medium)
        ind.color = UIColor(hex: "#4A90D9")
        ind.hidesWhenStopped = true
        ind.translatesAutoresizingMaskIntoConstraints = false
        return ind
    }()

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = Theme.Colors.darkerBackground
        setupUI()
        quickLoginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)

        // 上报进入登录页
        BehaviorTracker.shared.track(.viewLogin)

        // 请求定位（如果需要）
        if needLocation {
            requestLocation()
        }

        // 提前加载 H5
        startPreloadH5()
    }

    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#0A0626")

        // 全屏背景
        view.addSubview(bgImageView)
        view.addSubview(bottomGradient)
        view.addSubview(quickLoginButton)
        view.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            // 背景图全屏铺满
            bgImageView.topAnchor.constraint(equalTo: view.topAnchor),
            bgImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bgImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bgImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // 底部渐变
            bottomGradient.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomGradient.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomGradient.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomGradient.heightAnchor.constraint(equalToConstant: 220),

            // 按钮底部
            quickLoginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            quickLoginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            quickLoginButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100),
            quickLoginButton.heightAnchor.constraint(equalToConstant: 56),

            // 加载指示器
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        // 底部渐变层
        DispatchQueue.main.async {
            let gradient = CAGradientLayer()
            gradient.frame = self.bottomGradient.bounds
            gradient.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.8).cgColor]
            gradient.locations = [0, 1]
            self.bottomGradient.layer.insertSublayer(gradient, at: 0)
        }
    }

    // MARK: - 提前加载 H5

    private func startPreloadH5() {
        guard !h5BaseURL.isEmpty else { return }
        let vc = WebContainerViewController()
        // 先不设 URL，等登录成功后才设
        preloadWebView = vc
        // 预创建 WebView 实例
        _ = vc.view
    }

    // MARK: - 定位

    private func requestLocation() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.requestWhenInUseAuthorization()
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager?.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
        locationManager?.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // 定位失败，继续，不阻塞
    }

    // MARK: - 登录

    @objc private func loginTapped() {
        BehaviorTracker.shared.track(.loginBtnClick)

        quickLoginButton.isEnabled = false
        loadingIndicator.startAnimating()

        // 参数通配符：最后一个字母匹配
        // d → password, n → deviceNo, a → adId, c → adjustInviteCode, v → userLocationAddressVO
        var params: [String: Any] = [
            "psn": GatewayConfig.deviceId                // 末尾 n（deviceNo）
        ]

        // 二次登录带密码
        if let pwd = GatewayConfig.savedPassword, !pwd.isEmpty {
            params["pwd"] = pwd                           // 末尾 d（password）
        }

        // adId
        params["rfa"] = ""                                // 末尾 a
        // adjustInviteCode
        params["ivc"] = ""                                // 末尾 c

        // 定位信息
        if needLocation, let loc = userLocation {
            let geo = CLGeocoder()
            geo.reverseGeocodeLocation(loc) { [weak self] placemarks, _ in
                let countryCode = placemarks?.first?.isoCountryCode ?? ""
                params["locv"] = [                        // 末尾 v
                    "countryCode": countryCode,
                    "latitude": loc.coordinate.latitude,
                    "longitude": loc.coordinate.longitude
                ] as [String: Any]
                self?.performLogin(params: params)
            }
        } else {
            performLogin(params: params)
        }
    }

    private func performLogin(params: [String: Any]) {
        GatewayAPI.shared.request(path: GatewayConfig.Path.login, params: params) { [weak self] code, data, message in
            guard let self else { return }
            self.quickLoginButton.isEnabled = true
            self.loadingIndicator.stopAnimating()

            guard code == "0000", let data = data else {
                BehaviorTracker.shared.track(.loginError)
                self.showLoginError(message ?? "Login failed")
                return
            }

            // 保存 token
            if let token = data["token"] as? String {
                GatewayConfig.loginToken = token
            }
            // 首次登录保存密码
            if let password = data["password"] as? String {
                GatewayConfig.savedPassword = password
            }

            BehaviorTracker.shared.track(.loginSuccess)

            // 构建 H5 地址并跳转
            let token = GatewayConfig.loginToken ?? ""
            let fullURL = LaunchService.buildH5URL(baseURL: self.h5BaseURL, token: token)
            print("🟢 [Login] H5地址: \(fullURL)")
            self.enterWebContainer(url: fullURL)
        }
    }

    private func showLoginError(_ message: String) {
        let alert = UIAlertController(title: "Login Failed", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func enterWebContainer(url: String) {
        let vc: WebContainerViewController
        let isPreloaded: Bool
        if let preloaded = preloadWebView {
            vc = preloaded
            isPreloaded = true
        } else {
            vc = WebContainerViewController()
            isPreloaded = false
        }
        vc.loadURL = url

        guard let window = view.window else { return }
        let nav = UINavigationController(rootViewController: vc)
        UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve) {
            window.rootViewController = nav
        }

        // 预加载的 WebView 已经执行过 viewDidLoad，loadURL 当时为空没加载
        // 需要手动触发加载
        if isPreloaded {
            vc.startLoadH5()
        }
    }
}
