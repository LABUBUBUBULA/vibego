import UIKit
import PhotosUI

/// 创建帖子页 - 对应 Android GameMic 的 CreatePostActivity
/// 表单：标题 + 内容 + 图片选择 + 游戏标签选择 + 发布按钮
class CreatePostViewController: UIViewController {

    // MARK: - 状态

    /// 游戏标签（由上级页面传入）
    var gameTag: String = "Mobile Legends"

    /// 已选图片（最多4张）
    private var selectedImages: [(image: UIImage, uri: String)] = []

    /// 发布成功回调
    var onPostCreated: ((Post) -> Void)?

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

    /// 图片区域滚动容器
    private let imageScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    /// 图片缩略图 + 添加按钮 横向 stack
    private let imageStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 10
        sv.alignment = .center
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
        publishButton.addTarget(self, action: #selector(publishTapped), for: .touchUpInside)
    }

    // MARK: - 界面搭建

    private func setupUI() {
        view.addSubview(titleField)
        view.addSubview(contentTextView)
        view.addSubview(imageScrollView)
        imageScrollView.addSubview(imageStack)
        view.addSubview(publishButton)

        NSLayoutConstraint.activate([
            titleField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            titleField.heightAnchor.constraint(equalToConstant: 50),

            contentTextView.topAnchor.constraint(equalTo: titleField.bottomAnchor, constant: 12),
            contentTextView.leadingAnchor.constraint(equalTo: titleField.leadingAnchor),
            contentTextView.trailingAnchor.constraint(equalTo: titleField.trailingAnchor),
            contentTextView.heightAnchor.constraint(equalToConstant: 160),

            // 图片区域
            imageScrollView.topAnchor.constraint(equalTo: contentTextView.bottomAnchor, constant: 12),
            imageScrollView.leadingAnchor.constraint(equalTo: titleField.leadingAnchor),
            imageScrollView.trailingAnchor.constraint(equalTo: titleField.trailingAnchor),
            imageScrollView.heightAnchor.constraint(equalToConstant: 88),

            imageStack.topAnchor.constraint(equalTo: imageScrollView.topAnchor),
            imageStack.leadingAnchor.constraint(equalTo: imageScrollView.leadingAnchor),
            imageStack.trailingAnchor.constraint(equalTo: imageScrollView.trailingAnchor),
            imageStack.bottomAnchor.constraint(equalTo: imageScrollView.bottomAnchor),
            imageStack.heightAnchor.constraint(equalTo: imageScrollView.heightAnchor),

            publishButton.topAnchor.constraint(equalTo: imageScrollView.bottomAnchor, constant: 28),
            publishButton.leadingAnchor.constraint(equalTo: titleField.leadingAnchor),
            publishButton.trailingAnchor.constraint(equalTo: titleField.trailingAnchor),
            publishButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        rebuildImageStack()
    }



    // MARK: - 图片区域

    /// 重建图片横向列表（Add 按钮 + 已选缩略图）
    private func rebuildImageStack() {
        imageStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // 已选缩略图
        for (index, item) in selectedImages.enumerated() {
            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false

            let iv = UIImageView(image: item.image)
            iv.contentMode = .scaleAspectFill
            iv.layer.cornerRadius = 8
            iv.layer.masksToBounds = true
            iv.translatesAutoresizingMaskIntoConstraints = false

            let del = UIButton(type: .system)
            del.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            del.tintColor = .white
            del.tag = index
            del.translatesAutoresizingMaskIntoConstraints = false
            del.addTarget(self, action: #selector(removeImageTapped(_:)), for: .touchUpInside)

            container.addSubview(iv)
            container.addSubview(del)

            NSLayoutConstraint.activate([
                container.widthAnchor.constraint(equalToConstant: 80),
                iv.topAnchor.constraint(equalTo: container.topAnchor),
                iv.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                iv.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                iv.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                del.topAnchor.constraint(equalTo: container.topAnchor, constant: 2),
                del.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -2),
                del.widthAnchor.constraint(equalToConstant: 22),
                del.heightAnchor.constraint(equalToConstant: 22)
            ])
            imageStack.addArrangedSubview(container)
        }

        // 最多4张时才显示添加按钮
        if selectedImages.count < 4 {
            let addBtn = UIButton(type: .system)
            addBtn.setImage(UIImage(systemName: "plus.square.dashed"), for: .normal)
            addBtn.tintColor = Theme.Colors.primaryYellow
            addBtn.backgroundColor = Theme.Colors.cardBackground
            addBtn.layer.cornerRadius = 8
            addBtn.translatesAutoresizingMaskIntoConstraints = false
            addBtn.addTarget(self, action: #selector(addImageTapped), for: .touchUpInside)
            NSLayoutConstraint.activate([
                addBtn.widthAnchor.constraint(equalToConstant: 80),
                addBtn.heightAnchor.constraint(equalToConstant: 80)
            ])
            imageStack.addArrangedSubview(addBtn)
        }
    }

    @objc private func addImageTapped() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 4 - selectedImages.count
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func removeImageTapped(_ sender: UIButton) {
        let index = sender.tag
        guard selectedImages.indices.contains(index) else { return }
        selectedImages.remove(at: index)
        rebuildImageStack()
    }

    private func saveImage(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("post_img_\(UUID().uuidString).jpg")
        try? data.write(to: url)
        return url.path
    }

    /// 发布帖子
    @objc private func publishTapped() {
        let postTitle = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let postContent = (contentTextView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !postTitle.isEmpty else {
            showToast("Please enter a title")
            return
        }
        let check = ModerationManager.shared.checkContent([postTitle, postContent])
        guard check.isAllowed else {
            showToast(check.userMessage)
            return
        }
        let user = UserManager.shared.currentUser ?? MockDataManager.shared.users[0]
        let newPost = Post(
            id: Int.random(in: 10000...99999),
            authorId: "\(user.id)",
            authorName: user.name,
            authorAvatar: user.avatarImage,
            authorAvatarUri: user.avatarUri,
            time: "Just now",
            title: postTitle,
            content: postContent,
            images: [],
            imageUris: selectedImages.map { $0.uri },
            viewCount: 0,
            commentCount: 0,
            likeCount: 0,
            isLiked: false,
            isFollowing: false,
            gameTag: gameTag
        )
        MockDataManager.shared.addUserPost(newPost)
        onPostCreated?(newPost)
        showToast("Post published!")
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate
extension CreatePostViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        let group = DispatchGroup()
        var loaded: [(index: Int, image: UIImage)] = []

        for (i, result) in results.enumerated() {
            guard result.itemProvider.canLoadObject(ofClass: UIImage.self) else { continue }
            group.enter()
            result.itemProvider.loadObject(ofClass: UIImage.self) { obj, _ in
                // 在当前线程完成类型转换，不跨隔离边界传 obj
                let img = obj as? UIImage
                DispatchQueue.main.async {
                    if let img {
                        loaded.append((i, img))
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            for item in loaded.sorted(by: { $0.index < $1.index }) {
                let uri = self.saveImage(item.image) ?? ""
                self.selectedImages.append((image: item.image, uri: uri))
            }
            self.rebuildImageStack()
        }
    }
}
