import UIKit
import WebKit
import AVFoundation

/// B 包 H5 容器页
/// - 加载 H5 URL
/// - Loading 遮罩层（H5 调 pageLoaded 后隐藏）
/// - 禁止截屏
/// - 根页面返回不退出 App
/// - JS Bridge: rechargePay / openBrowser / pageLoaded / Close / requestPermission
/// - 全屏权限（target="_blank" 链接用系统浏览器打开）
/// - 非标准协议拦截
class WebContainerViewController: UIViewController {

    // MARK: - 外部传入

    var loadURL: String = ""

    // MARK: - UI

    private(set) var webView: WKWebView!

    /// 截屏保护：持有 secure text field 防止释放
    private var secureField: UITextField?

    /// Loading 遮罩（仿 GameMic Android 风格）
    private let loadingOverlay: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// 背景图
    private let loadingBgImage: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "bg_web_loading"))
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    /// 底部渐变遮罩
    private let loadingGradient: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// 三个脉冲加载点
    private let dot1 = WebContainerViewController.makeDot()
    private let dot2 = WebContainerViewController.makeDot()
    private let dot3 = WebContainerViewController.makeDot()

    private static func makeDot() -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#4A90D9")
        v.layer.cornerRadius = 6
        v.translatesAutoresizingMaskIntoConstraints = false
        v.alpha = 0.3
        return v
    }

    /// 加载文案
    private let loadingLabel: UILabel = {
        let label = UILabel()
        label.text = "Connecting to server..."
        label.font = Theme.Fonts.medium(14)
        label.textColor = UIColor.white.withAlphaComponent(0.8)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 百分比
    private let percentLabel: UILabel = {
        let label = UILabel()
        label.text = "0%"
        label.font = Theme.Fonts.bold(15)
        label.textColor = UIColor(hex: "#4A90D9")
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 细进度条
    private let progressBarBg: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        v.layer.cornerRadius = 1.5
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let progressBarFill: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 1.5
        v.translatesAutoresizingMaskIntoConstraints = false
        // 蓝色渐变
        v.backgroundColor = UIColor(hex: "#4A90D9")
        return v
    }()

    private var progressWidthConstraint: NSLayoutConstraint?

    // MARK: - H5 加载计时

    private var pageLoadStartTime: Date?

    // MARK: - 生命周期

    override var prefersStatusBarHidden: Bool { false }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = UIColor(hex: "#0A0626")

        // WebView 内容延伸到底部安全区域
        edgesForExtendedLayout = .all
        extendedLayoutIncludesOpaqueBars = true

        setupWebView()
        setupLoadingOverlay()
        setupScreenshotPrevention()

        if !loadURL.isEmpty {
            startLoadH5()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    deinit {
        let controller = webView?.configuration.userContentController
        controller?.removeScriptMessageHandler(forName: "rechargePay")
        controller?.removeScriptMessageHandler(forName: "openBrowser")
        controller?.removeScriptMessageHandler(forName: "pageLoaded")
        controller?.removeScriptMessageHandler(forName: "Close")
        controller?.removeScriptMessageHandler(forName: "requestPermission")
        controller?.removeScriptMessageHandler(forName: "Pay")
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - WebView 配置

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        let controller = WKUserContentController()

        // 注册 JS Bridge
        let handler = WebScriptHandler(delegate: self)
        controller.add(handler, name: "rechargePay")
        controller.add(handler, name: "openBrowser")
        controller.add(handler, name: "pageLoaded")
        controller.add(handler, name: "Close")
        controller.add(handler, name: "requestPermission")
        controller.add(handler, name: "Pay")

        config.userContentController = controller
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        // 支持 window.open()
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.translatesAutoresizingMaskIntoConstraints = false

        // 截屏保护：用 secure text field 的内部容器包裹 webView
        // isSecureTextEntry 会让系统在截屏时自动将该容器内容渲染为空白
        let field = UITextField()
        field.isSecureTextEntry = true
        field.backgroundColor = .clear
        field.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(field)
        self.secureField = field

        NSLayoutConstraint.activate([
            field.topAnchor.constraint(equalTo: view.topAnchor),
            field.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            field.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            field.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // 触发布局，让 secure field 生成内部安全容器 subview
        field.layoutIfNeeded()

        if let secureContainer = field.subviews.first {
            // 安全容器存在 → webView 放入，截屏时自动变空白
            secureContainer.isUserInteractionEnabled = true
            secureContainer.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                secureContainer.topAnchor.constraint(equalTo: field.topAnchor),
                secureContainer.leadingAnchor.constraint(equalTo: field.leadingAnchor),
                secureContainer.trailingAnchor.constraint(equalTo: field.trailingAnchor),
                secureContainer.bottomAnchor.constraint(equalTo: field.bottomAnchor),
            ])
            secureContainer.addSubview(webView)
            NSLayoutConstraint.activate([
                webView.topAnchor.constraint(equalTo: secureContainer.topAnchor),
                webView.leadingAnchor.constraint(equalTo: secureContainer.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: secureContainer.trailingAnchor),
                webView.bottomAnchor.constraint(equalTo: secureContainer.bottomAnchor),
            ])
        } else {
            // fallback：直接添加到 view（截屏保护不生效，但不影响功能）
            view.addSubview(webView)
            NSLayoutConstraint.activate([
                webView.topAnchor.constraint(equalTo: view.topAnchor),
                webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        }
    }

    private func setupLoadingOverlay() {
        view.addSubview(loadingOverlay)

        // 背景色（没有背景图资源时用纯色）
        loadingOverlay.backgroundColor = UIColor(hex: "#0A0626")
        loadingOverlay.addSubview(loadingBgImage)

        // 底部渐变
        loadingOverlay.addSubview(loadingGradient)

        // 三个点容器
        let dotsStack = UIStackView(arrangedSubviews: [dot1, dot2, dot3])
        dotsStack.axis = .horizontal
        dotsStack.spacing = 10
        dotsStack.alignment = .center
        dotsStack.translatesAutoresizingMaskIntoConstraints = false
        loadingOverlay.addSubview(dotsStack)

        loadingOverlay.addSubview(loadingLabel)
        loadingOverlay.addSubview(percentLabel)
        loadingOverlay.addSubview(progressBarBg)
        progressBarBg.addSubview(progressBarFill)

        let pw = progressBarFill.widthAnchor.constraint(equalToConstant: 0)
        progressWidthConstraint = pw

        NSLayoutConstraint.activate([
            loadingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            loadingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // 背景图（全屏铺满）
            loadingBgImage.topAnchor.constraint(equalTo: loadingOverlay.topAnchor),
            loadingBgImage.leadingAnchor.constraint(equalTo: loadingOverlay.leadingAnchor),
            loadingBgImage.trailingAnchor.constraint(equalTo: loadingOverlay.trailingAnchor),
            loadingBgImage.bottomAnchor.constraint(equalTo: loadingOverlay.bottomAnchor),

            // 底部渐变
            loadingGradient.leadingAnchor.constraint(equalTo: loadingOverlay.leadingAnchor),
            loadingGradient.trailingAnchor.constraint(equalTo: loadingOverlay.trailingAnchor),
            loadingGradient.bottomAnchor.constraint(equalTo: loadingOverlay.bottomAnchor),
            loadingGradient.heightAnchor.constraint(equalToConstant: 220),

            // 三个点
            dotsStack.centerXAnchor.constraint(equalTo: loadingOverlay.centerXAnchor),
            dotsStack.bottomAnchor.constraint(equalTo: loadingLabel.topAnchor, constant: -20),

            dot1.widthAnchor.constraint(equalToConstant: 12),
            dot1.heightAnchor.constraint(equalToConstant: 12),
            dot2.widthAnchor.constraint(equalToConstant: 12),
            dot2.heightAnchor.constraint(equalToConstant: 12),
            dot3.widthAnchor.constraint(equalToConstant: 12),
            dot3.heightAnchor.constraint(equalToConstant: 12),

            // 加载文案
            loadingLabel.centerXAnchor.constraint(equalTo: loadingOverlay.centerXAnchor),
            loadingLabel.bottomAnchor.constraint(equalTo: percentLabel.topAnchor, constant: -8),

            // 百分比
            percentLabel.centerXAnchor.constraint(equalTo: loadingOverlay.centerXAnchor),
            percentLabel.bottomAnchor.constraint(equalTo: progressBarBg.topAnchor, constant: -12),

            // 进度条
            progressBarBg.centerXAnchor.constraint(equalTo: loadingOverlay.centerXAnchor),
            progressBarBg.bottomAnchor.constraint(equalTo: loadingOverlay.safeAreaLayoutGuide.bottomAnchor, constant: -60),
            progressBarBg.widthAnchor.constraint(equalToConstant: 160),
            progressBarBg.heightAnchor.constraint(equalToConstant: 3),

            progressBarFill.leadingAnchor.constraint(equalTo: progressBarBg.leadingAnchor),
            progressBarFill.topAnchor.constraint(equalTo: progressBarBg.topAnchor),
            progressBarFill.bottomAnchor.constraint(equalTo: progressBarBg.bottomAnchor),
            pw,
        ])

        // 添加底部渐变层
        DispatchQueue.main.async {
            let gradient = CAGradientLayer()
            gradient.frame = self.loadingGradient.bounds
            gradient.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.8).cgColor]
            gradient.locations = [0, 1]
            self.loadingGradient.layer.insertSublayer(gradient, at: 0)
        }

        // 启动点动画
        startDotAnimations()

        // 模拟进度
        simulateProgress()
    }

    /// 三点脉冲动画（交错启动）
    private func startDotAnimations() {
        let dots = [dot1, dot2, dot3]
        for (i, dot) in dots.enumerated() {
            UIView.animate(withDuration: 0.6, delay: Double(i) * 0.15, options: [.repeat, .autoreverse, .curveEaseInOut]) {
                dot.alpha = 1.0
                dot.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            }
        }
    }

    /// 模拟加载进度
    private func simulateProgress() {
        var progress: CGFloat = 0
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self, self.loadingOverlay.superview != nil else {
                timer.invalidate()
                return
            }
            progress += CGFloat.random(in: 1...4)
            if progress > 95 { progress = 95 } // 留给 hideLoading 跳到100

            let pct = Int(progress)
            self.percentLabel.text = "\(pct)%"
            self.progressWidthConstraint?.constant = 160 * (progress / 100)

            // 更新文案
            switch pct {
            case 0..<30: self.loadingLabel.text = "Connecting to server..."
            case 30..<60: self.loadingLabel.text = "Loading resources..."
            case 60..<90: self.loadingLabel.text = "Almost there..."
            default: self.loadingLabel.text = "Loading complete"
            }

            UIView.animate(withDuration: 0.1) {
                self.progressBarBg.layoutIfNeeded()
            }
        }
    }

    /// 隐藏 Loading（H5 调 pageLoaded 或超时后调用）
    func hideLoading() {
        // 跳到100%
        percentLabel.text = "100%"
        loadingLabel.text = "Loading complete"
        progressWidthConstraint?.constant = 160

        UIView.animate(withDuration: 0.3, delay: 0.2) {
            self.loadingOverlay.alpha = 0
        } completion: { _ in
            self.loadingOverlay.removeFromSuperview()
            // 停止点动画
            self.dot1.layer.removeAllAnimations()
            self.dot2.layer.removeAllAnimations()
            self.dot3.layer.removeAllAnimations()
        }
    }

    // MARK: - 录屏保护（截屏保护已在 setupWebView 中通过 secure container 实现）

    private func setupScreenshotPrevention() {
        // 监听录屏状态 → 录屏时遮住内容
        NotificationCenter.default.addObserver(
            self, selector: #selector(screenCaptureChanged),
            name: UIScreen.capturedDidChangeNotification, object: nil
        )
        // 启动时检查一次
        updateScreenCaptureOverlay()
    }

    /// 录屏遮罩
    private lazy var captureOverlay: UIView = {
        let v = UIView()
        v.backgroundColor = .black
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        let label = UILabel()
        label.text = "Screen recording is not allowed"
        label.textColor = .white
        label.font = Theme.Fonts.medium(16)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: v.centerYAnchor),
        ])
        return v
    }()

    @objc private func screenCaptureChanged() {
        updateScreenCaptureOverlay()
    }

    private func updateScreenCaptureOverlay() {
        if UIScreen.main.isCaptured {
            if captureOverlay.superview == nil {
                view.addSubview(captureOverlay)
                NSLayoutConstraint.activate([
                    captureOverlay.topAnchor.constraint(equalTo: view.topAnchor),
                    captureOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    captureOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                    captureOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                ])
            }
            captureOverlay.isHidden = false
        } else {
            captureOverlay.isHidden = true
        }
    }

    // MARK: - 加载 H5

    func startLoadH5() {
        print("🌐 [WebView] startLoadH5: \(loadURL)")
        guard let url = URL(string: loadURL) else {
            print("🌐 [WebView] ❌ URL无效!")
            BehaviorTracker.shared.track(.viewError)
            return
        }
        pageLoadStartTime = Date()
        BehaviorTracker.shared.track(.pageLoadBegin)
        webView.load(URLRequest(url: url))

        // 超时保护：15秒后自动隐藏 loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
            if self?.loadingOverlay.superview != nil {
                self?.hideLoading()
            }
        }
    }

    // MARK: - 返回键处理

    /// 根页面（无法再返回时）按返回键不退出 App
    func handleBackNavigation() -> Bool {
        if webView.canGoBack {
            webView.goBack()
            return true
        }
        // 根页面：不退出
        return true
    }
}

// MARK: - WKNavigationDelegate

extension WebContainerViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("🌐 [WebView] ✅ didFinish: \(webView.url?.absoluteString ?? "")")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("🌐 [WebView] ❌ didFail: \(error.localizedDescription)")
        BehaviorTracker.shared.track(.pageLoadError)
        hideLoading()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("🌐 [WebView] ❌ didFailProvisional: \(error.localizedDescription)")
        BehaviorTracker.shared.track(.pageLoadError)
        hideLoading()
    }

    /// 拦截非标准协议导航（UPI 等支付 scheme）
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url
        let scheme = url?.scheme?.lowercased() ?? ""
        print("�� [Navigation] scheme=\(scheme), url=\(url?.absoluteString ?? "nil"), type=\(navigationAction.navigationType.rawValue)")

        if let url = url,
           scheme != "http" && scheme != "https" && scheme != "file" && scheme != "about" && !scheme.isEmpty {

            print("🧭 [Navigation] 非标准协议拦截 → 跳转外部: \(url)")
            UIApplication.shared.open(url, options: [:]) { [weak webView] success in
                print("🧭 [Navigation] 外部打开结果: \(success)")
                let state = success ? "success" : "failed"
                let js = """
                window.dispatchEvent(new CustomEvent('nativeOpenState', {
                    detail: { state: '\(state)', url: '\(url.absoluteString.replacingOccurrences(of: "'", with: "\\'"))' }
                }));
                """
                DispatchQueue.main.async {
                    webView?.evaluateJavaScript(js, completionHandler: nil)
                }
            }
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
}

// MARK: - WKUIDelegate

extension WebContainerViewController: WKUIDelegate {

    /// 处理 target="_blank" 链接 → 系统浏览器打开
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil || !(navigationAction.targetFrame?.isMainFrame ?? false) {
            if let url = navigationAction.request.url {
                print("�� [Blank] target=_blank 链接跳转外部: \(url)")
                UIApplication.shared.open(url, options: [:]) { success in
                    print("🔗 [Blank] 打开结果: \(success)")
                }
            }
        }
        return nil
    }
}

// MARK: - JS Bridge 消息处理

extension WebContainerViewController: WebScriptHandlerDelegate {

    func handleRechargePay(batchNo: String, callbackJson: String) {
        // 发起 iOS 内购
        PurchaseManager.shared.purchase(batchNo: batchNo, callbackJson: callbackJson, from: self)
    }

    func handleOpenBrowser(type: String, url: String) {
        print("🌐 [OpenBrowser] type=\(type), url=\(url)")
        guard let targetURL = URL(string: url) else {
            print("🌐 [OpenBrowser] ❌ URL无效: \(url)")
            return
        }
        print("�� [OpenBrowser] 跳转外部浏览器: \(targetURL)")
        UIApplication.shared.open(targetURL, options: [:]) { [weak self] success in
            print("🌐 [OpenBrowser] 打开结果: \(success)")
            let state = success ? "success" : "failed"
            let js = """
            window.dispatchEvent(new CustomEvent('nativeOpenState', {
                detail: { state: '\(state)', url: '\(url.replacingOccurrences(of: "'", with: "\\'"))' }
            }));
            """
            DispatchQueue.main.async {
                self?.webView.evaluateJavaScript(js, completionHandler: nil)
            }
        }
    }

    func handlePageLoaded() {
        // H5 加载完成
        if let start = pageLoadStartTime {
            let elapsed = Int(Date().timeIntervalSince(start) * 1000)
            // 可选：上报加载时长
            _ = elapsed
        }
        BehaviorTracker.shared.track(.pageLoadEnd)
        hideLoading()
    }

    func handleClose() {
        // 退出登录：清除 token，返回登录页
        GatewayConfig.clearTokens()

        guard let window = view.window else { return }
        let vc = QuickLoginViewController()
        vc.h5BaseURL = GatewayConfig.h5OpenValue ?? ""
        vc.needLocation = GatewayConfig.locationFlag == 1
        let nav = UINavigationController(rootViewController: vc)
        UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve) {
            window.rootViewController = nav
        }
    }

    func handleRequestPermission() {
        // 返回权限状态
        let camera = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        let photo = true // 照片权限在 iOS 不需要预先检查
        let js = """
        window.dispatchEvent(new CustomEvent('permissionResult', {
            detail: { camera: \(camera), picture: \(photo) }
        }));
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }
}
