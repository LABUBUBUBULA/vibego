import UIKit

/// 创建帖子页 - 对应 Android GameMic 的 CreatePostActivity
/// 表单：标题 + 内容 + 游戏标签选择 + 发布按钮
class CreatePostViewController: UIViewController {

    // MARK: - 状态

    /// 选中的游戏标签
    private var selectedTag: String = "PUBG"
    private let gameTags = ["PUBG", "Minecraft", "Fortnite", "TheSims"]
    private var tagButtons: [UIButton] = []

    // MARK: - UI 组件

    /// 标题输入框
    private let titleField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Post title"
        tf.textColor = Theme.Colors.textPrimary
        tf.font = Theme.Fonts.bold(18)
        tf.backgroundColor = Theme.Colors.cardBackground
        tf.layer.cornerRadius = 12
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.leftViewMode = .always
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    /// 内容输入框
    private let contentTextView: UITextView = {
        let tv = UITextView()
        tv.textColor = Theme.Colors.textPrimary
        tv.font = Theme.Fonts.regular(15)
        tv.backgroundColor = Theme.Colors.cardBackground
        tv.layer.cornerRadius = 12
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    /// 标签选择容器
    private let tagStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 8
        sv.distribution = .fillEqually
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    /// 发布按钮
    private let publishButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Publish", for: .normal)
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
        title = "Create Post"
        view.backgroundColor = Theme.Colors.darkBackground
        setupUI()
        setupGameTags()
        publishButton.addTarget(self, action: #selector(publishTapped), for: .touchUpInside)
    }

    // MARK: - 界面搭建

    private func setupUI() {
        view.addSubview(titleField)
        view.addSubview(contentTextView)
        view.addSubview(tagStack)
        view.addSubview(publishButton)

        NSLayoutConstraint.activate([
            titleField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            titleField.heightAnchor.constraint(equalToConstant: 50),

            contentTextView.topAnchor.constraint(equalTo: titleField.bottomAnchor, constant: 12),
            contentTextView.leadingAnchor.constraint(equalTo: titleField.leadingAnchor),
            contentTextView.trailingAnchor.constraint(equalTo: titleField.trailingAnchor),
            contentTextView.heightAnchor.constraint(equalToConstant: 200),

            tagStack.topAnchor.constraint(equalTo: contentTextView.bottomAnchor, constant: 16),
            tagStack.leadingAnchor.constraint(equalTo: titleField.leadingAnchor),
            tagStack.trailingAnchor.constraint(equalTo: titleField.trailingAnchor),
            tagStack.heightAnchor.constraint(equalToConstant: 36),

            publishButton.topAnchor.constraint(equalTo: tagStack.bottomAnchor, constant: 32),
            publishButton.leadingAnchor.constraint(equalTo: titleField.leadingAnchor),
            publishButton.trailingAnchor.constraint(equalTo: titleField.trailingAnchor),
            publishButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    /// 创建游戏标签按钮
    private func setupGameTags() {
        for (index, tag) in gameTags.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(tag, for: .normal)
            btn.titleLabel?.font = Theme.Fonts.medium(12)
            btn.layer.cornerRadius = 18
            btn.tag = index
            btn.addTarget(self, action: #selector(tagTapped(_:)), for: .touchUpInside)
            tagStack.addArrangedSubview(btn)
            tagButtons.append(btn)
        }
        updateTagUI()
    }

    @objc private func tagTapped(_ sender: UIButton) {
        selectedTag = gameTags[sender.tag]
        updateTagUI()
    }

    private func updateTagUI() {
        for (index, btn) in tagButtons.enumerated() {
            if gameTags[index] == selectedTag {
                btn.backgroundColor = Theme.Colors.primaryYellow
                btn.setTitleColor(Theme.Colors.darkerBackground, for: .normal)
            } else {
                btn.backgroundColor = Theme.Colors.cardBackground
                btn.setTitleColor(Theme.Colors.textSecondary, for: .normal)
            }
        }
    }

    /// 发布帖子
    @objc private func publishTapped() {
        guard let postTitle = titleField.text, !postTitle.isEmpty else { return }
        // Mock: 直接返回
        navigationController?.popViewController(animated: true)
    }
}
