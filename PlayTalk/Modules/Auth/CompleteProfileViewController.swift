import UIKit
import PhotosUI

/// 完善资料页 - 对应 Android GameMic 的 CompleteProfileActivity
/// 注册成功后填写：头像、昵称、国家、性别
/// 完成后跳转 SelectInterestsViewController 选择兴趣
class CompleteProfileViewController: UIViewController {

    // MARK: - 传入数据（从注册页传来）

    var userId: String = ""
    var email: String = ""

    // MARK: - 表单状态

    /// 选中的性别（默认 male，对应 Android selectedGender）
    private var selectedGender: String = "male"
    private var currentAvatarUri: String?
    private var currentAvatarImage: UIImage?

    // MARK: - UI 组件

    /// 头像容器（对应 Android iv_avatar + iv_camera）
    private let avatarView: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.Colors.cardBackground
        v.layer.cornerRadius = 60
        v.layer.masksToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 60
        iv.layer.masksToBounds = true
        iv.image = UIImage(named: "default_avatar")
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let cameraImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "ic_camera"))
        iv.contentMode = .scaleAspectFit
        iv.isUserInteractionEnabled = false
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    /// 昵称输入框（对应 Android et_nickname）
    private let nicknameField: UITextField = {
        let tf = UITextField()
        tf.attributedPlaceholder = NSAttributedString(string: "Nickname", attributes: [.foregroundColor: UIColor.lightGray])
        tf.textColor = Theme.Colors.textPrimary
        tf.font = Theme.Fonts.regular(16)
        tf.backgroundColor = Theme.Colors.cardBackground
        tf.layer.cornerRadius = 12
        tf.layer.borderWidth = 1
        tf.layer.borderColor = Theme.Colors.separator.cgColor
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.leftViewMode = .always
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    /// 性别选择区域标题
    private let genderLabel: UILabel = {
        let label = UILabel()
        label.text = "Gender"
        label.font = Theme.Fonts.medium(14)
        label.textColor = Theme.Colors.textSecondary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 男性选择按钮（对应 Android iv_male）
    private let maleButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("♂ Male", for: .normal)
        btn.titleLabel?.font = Theme.Fonts.medium(14)
        btn.layer.cornerRadius = 20
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    /// 女性选择按钮（对应 Android iv_female）
    private let femaleButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("♀ Female", for: .normal)
        btn.titleLabel?.font = Theme.Fonts.medium(14)
        btn.layer.cornerRadius = 20
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    /// 下一步按钮（对应 Android btn_next）
    private let nextButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Next", for: .normal)
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
        title = "Complete Profile"
        view.backgroundColor = Theme.Colors.darkBackground
        setupUI()
        setupActions()
        updateGenderUI()
    }

    // MARK: - 界面搭建

    private func setupUI() {
        navigationItem.leftBarButtonItem = makeAppBackButton(action: #selector(backTapped))

        view.addSubview(avatarView)
        avatarView.addSubview(avatarImageView)
        avatarView.addSubview(cameraImageView)
        view.addSubview(nicknameField)
        view.addSubview(genderLabel)
        view.addSubview(maleButton)
        view.addSubview(femaleButton)
        view.addSubview(nextButton)

        NSLayoutConstraint.activate([
            // 头像（120x120，居中）
            avatarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            avatarView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 120),
            avatarView.heightAnchor.constraint(equalToConstant: 120),

            avatarImageView.topAnchor.constraint(equalTo: avatarView.topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: avatarView.leadingAnchor),
            avatarImageView.trailingAnchor.constraint(equalTo: avatarView.trailingAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: avatarView.bottomAnchor),

            cameraImageView.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            cameraImageView.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            cameraImageView.widthAnchor.constraint(equalToConstant: 40),
            cameraImageView.heightAnchor.constraint(equalToConstant: 40),

            // 昵称
            nicknameField.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 32),
            nicknameField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            nicknameField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            nicknameField.heightAnchor.constraint(equalToConstant: 50),

            // 性别标题
            genderLabel.topAnchor.constraint(equalTo: nicknameField.bottomAnchor, constant: 24),
            genderLabel.leadingAnchor.constraint(equalTo: nicknameField.leadingAnchor),

            // 男女按钮（并排）
            maleButton.topAnchor.constraint(equalTo: genderLabel.bottomAnchor, constant: 12),
            maleButton.leadingAnchor.constraint(equalTo: nicknameField.leadingAnchor),
            maleButton.widthAnchor.constraint(equalToConstant: 120),
            maleButton.heightAnchor.constraint(equalToConstant: 40),

            femaleButton.topAnchor.constraint(equalTo: maleButton.topAnchor),
            femaleButton.leadingAnchor.constraint(equalTo: maleButton.trailingAnchor, constant: 16),
            femaleButton.widthAnchor.constraint(equalToConstant: 120),
            femaleButton.heightAnchor.constraint(equalToConstant: 40),

            // 下一步按钮
            nextButton.topAnchor.constraint(equalTo: maleButton.bottomAnchor, constant: 48),
            nextButton.leadingAnchor.constraint(equalTo: nicknameField.leadingAnchor),
            nextButton.trailingAnchor.constraint(equalTo: nicknameField.trailingAnchor),
            nextButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    // MARK: - 事件

    private func setupActions() {
        maleButton.addTarget(self, action: #selector(maleTapped), for: .touchUpInside)
        femaleButton.addTarget(self, action: #selector(femaleTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        avatarView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarTapped)))
        avatarView.isUserInteractionEnabled = true
    }

    @objc private func avatarTapped() {
        let sheet = UIAlertController(title: "Change Avatar", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
            self?.pickFromLibrary()
        })
        sheet.addAction(UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
            self?.takePhoto()
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = avatarView
            popover.sourceRect = avatarView.bounds
        }
        present(sheet, animated: true)
    }

    private func pickFromLibrary() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func takePhoto() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showToast("Camera unavailable")
            return
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = false
        present(picker, animated: true)
    }

    private func updateAvatarPreview() {
        avatarImageView.image = currentAvatarImage ?? UIImage(named: "default_avatar")
        cameraImageView.isHidden = currentAvatarImage != nil
    }

    private func saveSelectedImage(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("avatars", isDirectory: true)
        do {
            if !FileManager.default.fileExists(atPath: directory.path) {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            }
            let fileURL = directory.appendingPathComponent("avatar_\(UUID().uuidString).jpg")
            try data.write(to: fileURL, options: .atomic)
            return fileURL.path
        } catch {
            return nil
        }
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    /// 选择男性
    @objc private func maleTapped() {
        selectedGender = "male"
        updateGenderUI()
    }

    /// 选择女性
    @objc private func femaleTapped() {
        selectedGender = "female"
        updateGenderUI()
    }

    /// 更新性别按钮样式（对应 Android checkbox checked/unchecked 状态切换）
    private func updateGenderUI() {
        if selectedGender == "male" {
            maleButton.backgroundColor = Theme.Colors.primaryYellow
            maleButton.setTitleColor(Theme.Colors.darkerBackground, for: .normal)
            femaleButton.backgroundColor = Theme.Colors.cardBackground
            femaleButton.setTitleColor(Theme.Colors.textSecondary, for: .normal)
        } else {
            femaleButton.backgroundColor = Theme.Colors.primaryYellow
            femaleButton.setTitleColor(Theme.Colors.darkerBackground, for: .normal)
            maleButton.backgroundColor = Theme.Colors.cardBackground
            maleButton.setTitleColor(Theme.Colors.textSecondary, for: .normal)
        }
    }

    /// 下一步点击 → 验证 → 跳转兴趣选择页
    @objc private func nextTapped() {
        let nickname = nicknameField.text?.trimmingCharacters(in: .whitespaces) ?? ""

        // 昵称不能为空（对应 Android "Please enter your nickname"）
        guard !nickname.isEmpty else {
            showToast("Please enter your nickname")
            return
        }

        // 跳转兴趣选择页（传递资料数据，对应 Android → SelectInterestsActivity）
        let vc = SelectInterestsViewController()
        vc.nickname = nickname
        vc.gender = selectedGender
        vc.avatarUri = currentAvatarUri
        navigationController?.pushViewController(vc, animated: true)
    }

}

extension CompleteProfileViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
            guard let self, let image = image as? UIImage else { return }
            DispatchQueue.main.async {
                self.currentAvatarImage = image
                self.currentAvatarUri = self.saveSelectedImage(image)
                self.updateAvatarPreview()
            }
        }
    }
}

extension CompleteProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        let image = (info[.originalImage] as? UIImage) ?? (info[.editedImage] as? UIImage)
        picker.dismiss(animated: true)
        guard let image else { return }
        currentAvatarImage = image
        currentAvatarUri = saveSelectedImage(image)
        updateAvatarPreview()
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
