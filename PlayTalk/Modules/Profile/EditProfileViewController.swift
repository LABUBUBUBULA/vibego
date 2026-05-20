import UIKit
import PhotosUI

/// 编辑资料页 - 对应 Android GameMic 的 EditProfileActivity
/// 表单：头像、昵称、性别、签名
final class EditProfileViewController: UIViewController {

    private var currentAvatarUri: String?
    private var currentAvatarImage: UIImage?

    // MARK: - UI

    private let avatarContainer: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.Colors.cardBackground
        v.layer.cornerRadius = 48
        v.layer.borderWidth = 2
        v.layer.borderColor = Theme.Colors.primaryYellow.withAlphaComponent(0.5).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 46
        iv.layer.masksToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let avatarPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.text = "Tap to change"
        label.font = Theme.Fonts.medium(13)
        label.textColor = Theme.Colors.textSecondary
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let nicknameField: UITextField = {
        let tf = UITextField()
        tf.attributedPlaceholder = NSAttributedString(
            string: "Nickname",
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

    private let genderLabel: UILabel = {
        let label = UILabel()
        label.text = "Gender"
        label.font = Theme.Fonts.medium(14)
        label.textColor = Theme.Colors.textSecondary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let genderControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Male", "Female"])
        control.selectedSegmentIndex = 0
        control.selectedSegmentTintColor = Theme.Colors.primaryYellow
        control.backgroundColor = Theme.Colors.cardBackground
        control.setTitleTextAttributes([.foregroundColor: Theme.Colors.textSecondary], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: Theme.Colors.darkerBackground], for: .selected)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    private let bioField: UITextView = {
        let tv = UITextView()
        tv.backgroundColor = Theme.Colors.cardBackground
        tv.textColor = Theme.Colors.textPrimary
        tv.font = Theme.Fonts.regular(16)
        tv.layer.cornerRadius = 12
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let bioPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.text = "Signature"
        label.font = Theme.Fonts.regular(16)
        label.textColor = Theme.Colors.textSecondary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let saveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Save", for: .normal)
        btn.setTitleColor(Theme.Colors.darkerBackground, for: .normal)
        btn.titleLabel?.font = Theme.Fonts.bold(16)
        btn.backgroundColor = Theme.Colors.primaryYellow
        btn.layer.cornerRadius = 25
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Edit Profile"
        view.backgroundColor = Theme.Colors.darkBackground
        setupUI()
        loadCurrentProfile()
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        avatarContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarTapped)))
        bioField.delegate = self
    }

    private func setupUI() {
        navigationItem.leftBarButtonItem = makeAppBackButton(action: #selector(backTapped))

        view.addSubview(avatarContainer)
        avatarContainer.addSubview(avatarImageView)
        avatarContainer.addSubview(avatarPlaceholderLabel)
        view.addSubview(nicknameField)
        view.addSubview(genderLabel)
        view.addSubview(genderControl)
        view.addSubview(bioField)
        bioField.addSubview(bioPlaceholderLabel)
        view.addSubview(saveButton)

        NSLayoutConstraint.activate([
            avatarContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            avatarContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avatarContainer.widthAnchor.constraint(equalToConstant: 96),
            avatarContainer.heightAnchor.constraint(equalToConstant: 96),

            avatarImageView.topAnchor.constraint(equalTo: avatarContainer.topAnchor, constant: 2),
            avatarImageView.leadingAnchor.constraint(equalTo: avatarContainer.leadingAnchor, constant: 2),
            avatarImageView.trailingAnchor.constraint(equalTo: avatarContainer.trailingAnchor, constant: -2),
            avatarImageView.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor, constant: -2),

            avatarPlaceholderLabel.centerXAnchor.constraint(equalTo: avatarContainer.centerXAnchor),
            avatarPlaceholderLabel.centerYAnchor.constraint(equalTo: avatarContainer.centerYAnchor),

            nicknameField.topAnchor.constraint(equalTo: avatarContainer.bottomAnchor, constant: 24),
            nicknameField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            nicknameField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            nicknameField.heightAnchor.constraint(equalToConstant: 50),

            genderLabel.topAnchor.constraint(equalTo: nicknameField.bottomAnchor, constant: 18),
            genderLabel.leadingAnchor.constraint(equalTo: nicknameField.leadingAnchor),

            genderControl.topAnchor.constraint(equalTo: genderLabel.bottomAnchor, constant: 10),
            genderControl.leadingAnchor.constraint(equalTo: nicknameField.leadingAnchor),
            genderControl.trailingAnchor.constraint(equalTo: nicknameField.trailingAnchor),
            genderControl.heightAnchor.constraint(equalToConstant: 36),

            bioField.topAnchor.constraint(equalTo: genderControl.bottomAnchor, constant: 18),
            bioField.leadingAnchor.constraint(equalTo: nicknameField.leadingAnchor),
            bioField.trailingAnchor.constraint(equalTo: nicknameField.trailingAnchor),
            bioField.heightAnchor.constraint(equalToConstant: 120),

            bioPlaceholderLabel.topAnchor.constraint(equalTo: bioField.topAnchor, constant: 12),
            bioPlaceholderLabel.leadingAnchor.constraint(equalTo: bioField.leadingAnchor, constant: 16),

            saveButton.topAnchor.constraint(equalTo: bioField.bottomAnchor, constant: 28),
            saveButton.leadingAnchor.constraint(equalTo: nicknameField.leadingAnchor),
            saveButton.trailingAnchor.constraint(equalTo: nicknameField.trailingAnchor),
            saveButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func loadCurrentProfile() {
        let user = UserManager.shared.currentUser ?? MockDataManager.shared.users[0]
        nicknameField.text = user.name
        genderControl.selectedSegmentIndex = user.gender == "female" ? 1 : 0
        bioField.text = user.bio
        bioPlaceholderLabel.isHidden = !user.bio.isEmpty
        currentAvatarUri = user.avatarUri
        currentAvatarImage = user.displayAvatarImage
        updateAvatarPreview()
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
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
            popover.sourceView = avatarContainer
            popover.sourceRect = avatarContainer.bounds
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
        if let image = currentAvatarImage {
            avatarImageView.image = image
            avatarImageView.isHidden = false
            avatarPlaceholderLabel.isHidden = true
        } else {
            avatarImageView.image = nil
            avatarImageView.isHidden = true
            avatarPlaceholderLabel.isHidden = false
        }
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

    @objc private func saveTapped() {
        let nickname = nicknameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !nickname.isEmpty else {
            showToast("Please enter your nickname")
            return
        }

        let user = UserManager.shared.currentUser ?? MockDataManager.shared.users[0]
        let avatarUri = currentAvatarUri ?? user.avatarUri
        UserManager.shared.updateUserProfile(
            nickname: nickname,
            gender: genderControl.selectedSegmentIndex == 1 ? "female" : "male",
            avatarUri: avatarUri,
            country: "",
            countryFlag: user.countryFlag,
            interests: user.interests,
            bio: bioField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        )

        navigationController?.popViewController(animated: true)
    }
}

extension EditProfileViewController: PHPickerViewControllerDelegate {
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

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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

extension EditProfileViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        bioPlaceholderLabel.isHidden = !textView.text.isEmpty
    }
}
