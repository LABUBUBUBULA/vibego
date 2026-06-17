import UIKit
import PhotosUI

/// 创建房间页 - 对应 Android GameMic 的 CreateRoomActivity
/// 表单：房间封面 + 房间名称 + 密码(可选) + 游戏标签(4选1) + 房间简介
/// 创建成功后自动进入语音房
class CreateRoomViewController: UIViewController {

    // MARK: - 状态

    /// 选中的游戏标签（默认 Mobile Legends）
    private var selectedTag: String = "Mobile Legends"
    /// 游戏标签列表
    private let gameTags = ["Mobile Legends", "Roblox", "Brawl Stars", "Among Us"]
    /// 标签按钮数组
    private var tagButtons: [UIButton] = []
    private var selectedCoverImageName: String?
    private var selectedCoverImage: UIImage?
    private var selectedCoverUri: String?

    // MARK: - UI 组件

    private let coverContainer: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.Colors.cardBackground
        v.layer.cornerRadius = 36
        v.layer.borderWidth = 1
        v.layer.borderColor = Theme.Colors.primaryYellow.withAlphaComponent(0.4).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let coverImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 32
        iv.layer.masksToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let addCoverLabel: UILabel = {
        let label = UILabel()
        label.text = "+"
        label.font = Theme.Fonts.bold(28)
        label.textColor = Theme.Colors.primaryYellow
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()


    /// 房间名称输入框
    private let roomNameField: UITextField = {
        let tf = UITextField()
        tf.attributedPlaceholder = NSAttributedString(
            string: "Enter room name",
            attributes: [.foregroundColor: Theme.Colors.textSecondary]
        )
        tf.textColor = Theme.Colors.textPrimary
        tf.font = Theme.Fonts.regular(16)
        tf.backgroundColor = Theme.Colors.cardBackground
        tf.layer.cornerRadius = 12
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.leftViewMode = .always
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    /// 房间密码输入框（可选）
    private let roomPasswordField: UITextField = {
        let tf = UITextField()
        tf.attributedPlaceholder = NSAttributedString(
            string: "Password (optional)",
            attributes: [.foregroundColor: Theme.Colors.textSecondary]
        )
        tf.textColor = Theme.Colors.textPrimary
        tf.font = Theme.Fonts.regular(16)
        tf.backgroundColor = Theme.Colors.cardBackground
        tf.layer.cornerRadius = 12
        tf.keyboardType = .numberPad
        tf.isSecureTextEntry = true
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.leftViewMode = .always
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    /// 游戏标签选择区域标题
    private let tagTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Game Tag"
        label.font = Theme.Fonts.medium(14)
        label.textColor = Theme.Colors.textSecondary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 游戏标签容器
    private let tagStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 8
        sv.distribution = .fillEqually
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    /// 房间简介输入框（对应 Android etRoomProfile，120dp 高度）
    private let roomProfileField: UITextView = {
        let tv = UITextView()
        tv.text = ""
        tv.textColor = Theme.Colors.textPrimary
        tv.font = Theme.Fonts.regular(14)
        tv.backgroundColor = Theme.Colors.cardBackground
        tv.layer.cornerRadius = 12
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    /// 简介占位文字
    private let profilePlaceholder: UILabel = {
        let label = UILabel()
        label.text = "Set up your room profile.."
        label.font = Theme.Fonts.regular(14)
        label.textColor = Theme.Colors.textSecondary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 创建按钮（对应 Android btnContinue，56dp 高度，黄色）
    private let createButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Create Room", for: .normal)
        btn.setTitleColor(Theme.Colors.darkerBackground, for: .normal)
        btn.titleLabel?.font = Theme.Fonts.bold(16)
        btn.backgroundColor = Theme.Colors.primaryYellow
        btn.layer.cornerRadius = 28
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Create voice room"
        view.backgroundColor = Theme.Colors.darkBackground
        setupUI()
        setupActions()
        setupGameTags()
    }

    // MARK: - 界面搭建

    private func setupUI() {
        navigationItem.leftBarButtonItem = makeAppBackButton(action: #selector(backTapped))

        view.addSubview(coverContainer)
        coverContainer.addSubview(coverImageView)
        coverContainer.addSubview(addCoverLabel)
        view.addSubview(roomNameField)
        view.addSubview(roomPasswordField)
        view.addSubview(tagTitleLabel)
        view.addSubview(tagStack)
        view.addSubview(roomProfileField)
        roomProfileField.addSubview(profilePlaceholder)
        view.addSubview(createButton)

        NSLayoutConstraint.activate([
            coverContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            coverContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            coverContainer.widthAnchor.constraint(equalToConstant: 72),
            coverContainer.heightAnchor.constraint(equalToConstant: 72),

            coverImageView.centerXAnchor.constraint(equalTo: coverContainer.centerXAnchor),
            coverImageView.centerYAnchor.constraint(equalTo: coverContainer.centerYAnchor),
            coverImageView.widthAnchor.constraint(equalToConstant: 64),
            coverImageView.heightAnchor.constraint(equalToConstant: 64),

            addCoverLabel.centerXAnchor.constraint(equalTo: coverContainer.centerXAnchor),
            addCoverLabel.centerYAnchor.constraint(equalTo: coverContainer.centerYAnchor),

            // 房间名
            roomNameField.topAnchor.constraint(equalTo: coverContainer.bottomAnchor, constant: 24),
            roomNameField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            roomNameField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            roomNameField.heightAnchor.constraint(equalToConstant: 48),

            // 密码
            roomPasswordField.topAnchor.constraint(equalTo: roomNameField.bottomAnchor, constant: 16),
            roomPasswordField.leadingAnchor.constraint(equalTo: roomNameField.leadingAnchor),
            roomPasswordField.trailingAnchor.constraint(equalTo: roomNameField.trailingAnchor),
            roomPasswordField.heightAnchor.constraint(equalToConstant: 48),

            // 标签标题
            tagTitleLabel.topAnchor.constraint(equalTo: roomPasswordField.bottomAnchor, constant: 24),
            tagTitleLabel.leadingAnchor.constraint(equalTo: roomNameField.leadingAnchor),

            // 标签按钮（2x2 网格）
            tagStack.topAnchor.constraint(equalTo: tagTitleLabel.bottomAnchor, constant: 12),
            tagStack.leadingAnchor.constraint(equalTo: roomNameField.leadingAnchor),
            tagStack.trailingAnchor.constraint(equalTo: roomNameField.trailingAnchor),
            tagStack.heightAnchor.constraint(equalToConstant: 36),

            // 简介
            roomProfileField.topAnchor.constraint(equalTo: tagStack.bottomAnchor, constant: 24),
            roomProfileField.leadingAnchor.constraint(equalTo: roomNameField.leadingAnchor),
            roomProfileField.trailingAnchor.constraint(equalTo: roomNameField.trailingAnchor),
            roomProfileField.heightAnchor.constraint(equalToConstant: 120),

            // 占位文字
            profilePlaceholder.topAnchor.constraint(equalTo: roomProfileField.topAnchor, constant: 12),
            profilePlaceholder.leadingAnchor.constraint(equalTo: roomProfileField.leadingAnchor, constant: 16),

            // 创建按钮
            createButton.topAnchor.constraint(equalTo: roomProfileField.bottomAnchor, constant: 32),
            createButton.leadingAnchor.constraint(equalTo: roomNameField.leadingAnchor),
            createButton.trailingAnchor.constraint(equalTo: roomNameField.trailingAnchor),
            createButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    /// 创建游戏标签按钮（对应 Android 2x2 grid RadioButton）
    private func setupGameTags() {
        for (index, tag) in gameTags.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(tag, for: .normal)
            btn.titleLabel?.font = Theme.Fonts.medium(13)
            btn.layer.cornerRadius = 18
            btn.tag = index
            btn.addTarget(self, action: #selector(tagTapped(_:)), for: .touchUpInside)
            tagStack.addArrangedSubview(btn)
            tagButtons.append(btn)
        }
        updateTagUI()
    }

    private func assetPrefix(for tag: String) -> String {
        switch tag {
        case "Mobile Legends": return "pubg"
        case "Roblox": return "minecraft"
        case "Brawl Stars": return "fortnite"
        case "Among Us": return "thesims"
        default: return tag.lowercased().replacingOccurrences(of: " ", with: "")
        }
    }

    // MARK: - 事件

    private func setupActions() {
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        coverContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(coverTapped)))
        roomProfileField.delegate = self
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    /// 游戏标签点击切换
    @objc private func tagTapped(_ sender: UIButton) {
        selectedTag = gameTags[sender.tag]
        updateTagUI()
        if selectedCoverImageName != nil {
            updateCoverForSelectedTag()
        }
    }

    @objc private func coverTapped() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func updateCoverForSelectedTag() {
        guard selectedCoverImage == nil else { return }
        let imageName = "ph_\(assetPrefix(for: selectedTag))"
        selectedCoverImageName = imageName
        coverImageView.image = UIImage(named: imageName)
        addCoverLabel.isHidden = true
    }

    private func saveCoverImage(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return nil }
        let fileName = "room_cover_\(UUID().uuidString).jpg"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: url)
            return url.path
        } catch {
            return nil
        }
    }

    /// 更新标签选中状态 UI
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

    /// 创建房间（对应 Android CreateRoomActivity 创建逻辑）
    @objc private func createTapped() {
        let roomName = roomNameField.text?.trimmingCharacters(in: .whitespaces) ?? ""

        // 房间名不能为空
        guard !roomName.isEmpty else {
            showToast("Please enter room name")
            return
        }

        guard selectedCoverImage != nil || selectedCoverImageName != nil else {
            showToast("Please select a cover image")
            return
        }

        // 生成6位房间ID（对应 Android 100000-999999 随机）
        let roomId = "\(Int.random(in: 100000...999999))"
        let user = UserManager.shared.currentUser ?? MockDataManager.shared.users[0]
        let profileText = roomProfileField.text ?? ""

        // 创建房间数据
        let room = VoiceRoom(
            roomId: roomId,
            title: roomName,
            coverImage: selectedCoverImageName ?? "ph_\(assetPrefix(for: selectedTag))",
            coverUri: selectedCoverUri,
            gameTag: selectedTag,
            description: profileText.isEmpty ? "Welcome to \(roomName)!" : profileText,
            roomName: roomName,
            isCollected: false,
            hostName: user.name,
            hostAvatarImage: user.displayAvatar,
            hostCountry: "",
            hostCountryFlag: "",
            memberCount: 1,
            hotValue: 0
        )

        MockDataManager.shared.addUserCreatedRoom(room)

        // 跳转到语音房（对应 Android → VoiceRoomActivity with is_owner=true）
        let vc = VoiceRoomViewController()
        vc.room = room
        vc.isOwner = true
        pushAppViewController(vc, animated: true)
    }

}

extension CreateRoomViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }

        provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
            guard let self, let image = image as? UIImage else { return }
            DispatchQueue.main.async {
                self.selectedCoverImage = image
                self.selectedCoverImageName = "ph_\(self.assetPrefix(for: self.selectedTag))"
                self.selectedCoverUri = self.saveCoverImage(image)
                self.coverImageView.image = image
                self.addCoverLabel.isHidden = true
            }
        }
    }
}

// MARK: - UITextViewDelegate（简介占位文字显隐）
extension CreateRoomViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        profilePlaceholder.isHidden = !textView.text.isEmpty
    }
}
