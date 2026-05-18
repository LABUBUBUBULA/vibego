import UIKit

final class SplashViewController: UIViewController {
    private let minimumDisplayTime: TimeInterval = 1.0

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
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#0A0626")
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + minimumDisplayTime) { [weak self] in
            self?.routeToNextScreen()
        }
    }

    private func setupUI() {
        let stack = UIStackView(arrangedSubviews: [logoView, titleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 40
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            logoView.widthAnchor.constraint(equalToConstant: 120),
            logoView.heightAnchor.constraint(equalToConstant: 120),

            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    private func routeToNextScreen() {
        let root: UIViewController
        if UserManager.shared.isLoggedIn {
            root = AppNavigationController(rootViewController: MainTabBarController())
        } else {
            root = UINavigationController(rootViewController: WelcomeViewController())
        }

        guard let window = view.window else { return }
        UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve) {
            window.rootViewController = root
        }
    }
}
