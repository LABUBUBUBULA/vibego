import UIKit

final class LegalTextViewController: UIViewController {

    enum PageType {
        case terms
        case privacy
        case about
    }

    private let type: PageType

    private lazy var textView: UITextView = {
        let tv = UITextView()
        tv.backgroundColor = Theme.Colors.darkBackground
        tv.textColor = Theme.Colors.textPrimary
        tv.font = Theme.Fonts.regular(15)
        tv.isEditable = false
        tv.alwaysBounceVertical = true
        tv.textContainerInset = UIEdgeInsets(top: 20, left: 16, bottom: 32, right: 16)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
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
        configureContent()
        setupUI()
    }

    private func setupUI() {
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureContent() {
        switch type {
        case .terms:
            title = "Terms of Service"
            textView.text = """
            Terms of Service

            Welcome to PlayTalk. By using this app, you agree to use voice rooms, chat, forum posts, gifts, and profile features responsibly.

            1. Account
            You are responsible for your account activity. Do not impersonate others, harass users, or share illegal content.

            2. Voice Rooms and Chat
            Keep conversations respectful. PlayTalk may remove content or restrict accounts that violate community rules.

            3. Virtual Items
            Coins, gifts, and other virtual items are mock app features in this build. They have no cash value unless connected to official payment services.

            4. Service Changes
            Features may change as PlayTalk evolves. Continued use means you accept updated terms.
            """
        case .privacy:
            title = "Privacy Policy"
            textView.text = """
            Privacy Policy

            PlayTalk is a social voice chat app. This iOS build uses local mock data and does not connect to a production backend.

            1. Profile Data
            Display name, avatar, bio, interests, level, and room activity are used to render social features.

            2. Messages and Rooms
            Mock messages, room history, and collections are stored in app memory for demo behavior.

            3. Payments
            Recharge screens are placeholders unless official in-app purchase integration is enabled.

            4. Account Deletion
            Delete Account clears current local session and returns to sign-in.
            """
        case .about:
            title = "About"
            textView.text = """
            PlayTalk

            Version 1.0.0

            PlayTalk is a game voice social app with voice rooms, private chat, game forums, user profiles, levels, gifts, collections, and browsing history.

            This iOS version is adapted from Android behavior and currently uses mock data for product preview.
            """
        }
    }
}
