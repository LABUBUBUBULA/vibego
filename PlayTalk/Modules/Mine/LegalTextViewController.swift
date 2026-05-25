import UIKit
import WebKit

final class LegalTextViewController: UIViewController {

    enum PageType {
        case terms
        case privacy
        case about

        var pageTitle: String {
            switch self {
            case .terms:
                return "Terms of Service"
            case .privacy:
                return "Privacy Policy"
            case .about:
                return "About"
            }
        }

        /// 本地 HTML 路由名：以后要换线上路由或 Web 链接，只改这里映射。
        var htmlRoute: String {
            switch self {
            case .terms:
                return "terms-of-service"
            case .privacy:
                return "privacy-policy"
            case .about:
                return "about-playmeet"
            }
        }
    }

    private let type: PageType

    /// 使用 WKWebView 读取本地 HTML 文件，不把协议正文写在 Swift 里。
    private lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        let view = WKWebView(frame: .zero, configuration: config)
        view.backgroundColor = Theme.Colors.darkBackground
        view.scrollView.backgroundColor = Theme.Colors.darkBackground
        view.isOpaque = false
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    init(type: PageType) {
        self.type = type
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Colors.darkBackground
        setupUI()
        loadHTMLRoute()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func setupUI() {
        title = type.pageTitle
        navigationItem.leftBarButtonItem = makeAppBackButton(action: #selector(backTapped))

        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadHTMLRoute() {
        if let fileURL = Bundle.main.url(forResource: type.htmlRoute, withExtension: "html") {
            webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL.deletingLastPathComponent())
            return
        }

        // 防止资源没加入 target 时白屏，方便定位路由/资源配置问题。
        let fallbackHTML = """
        <!doctype html>
        <html><body style="margin:0;padding:24px;background:#12121C;color:#F5F5FA;font-family:-apple-system;">
        <h1 style="color:#FFE800;">Page not found</h1>
        <p>Missing local HTML route: \(type.htmlRoute).html</p>
        </body></html>
        """
        webView.loadHTMLString(fallbackHTML, baseURL: nil)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}
