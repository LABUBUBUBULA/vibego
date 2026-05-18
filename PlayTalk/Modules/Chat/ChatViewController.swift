import UIKit
import PhotosUI
import AVFoundation
import AVKit

/// 私聊页面 - 对应 Android GameMic 的 ChatActivity
/// 布局：顶部用户信息 → 消息列表 → 底部输入框 + 语音/图片/视频/礼物功能
class ChatViewController: UIViewController {

    // MARK: - 传入数据

    /// 聊天对方的用户信息
    var chatUser: Message?

    // MARK: - 数据

    /// 私聊消息类型：文本、语音、图片、视频、礼物
    fileprivate enum ChatMessageKind {
        case text(String)
        case voice(url: URL, duration: Int)
        case image(UIImage)
        case video(url: URL, thumbnail: UIImage?)
        case gift(Gift, count: Int)
    }

    /// Mock 聊天消息列表
    private struct ChatMessageItem {
        let kind: ChatMessageKind
        let isMe: Bool
        let time: String
    }

    private var chatMessages: [ChatMessageItem] = []
    private let reportReasons = [
        "Harassment or bullying",
        "Sexual content",
        "Hate speech",
        "Scam or fraud",
        "Spam",
        "Fake profile",
        "Underage user",
        "Other"
    ]
    private var selectedReportReason: String?
    private var inputBarBottomConstraint: NSLayoutConstraint?
    private var audioRecorder: AVAudioRecorder?
    private var recordingStartTime: Date?
    private var recordingURL: URL?
    private var isRecording = false

    // MARK: - UI 组件

    /// 消息列表
    private lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.delegate = self
        tv.dataSource = self
        tv.register(ChatBubbleCell.self, forCellReuseIdentifier: ChatBubbleCell.reuseId)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.keyboardDismissMode = .interactive
        return tv
    }()

    /// 底部输入区域容器
    private let inputContainer: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.Colors.darkerBackground
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// 键盘弹出时上移的输入栏，只包含输入框和发送按钮
    private let inputBar: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.Colors.darkerBackground
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// 消息输入框
    private lazy var inputField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Type a message..."
        tf.textColor = Theme.Colors.textPrimary
        tf.font = Theme.Fonts.regular(14)
        tf.backgroundColor = Theme.Colors.cardBackground
        tf.layer.cornerRadius = 20
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.leftViewMode = .always
        tf.returnKeyType = .send
        tf.delegate = self
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    /// 发送按钮（对应 Android ic_chat_send）
    private let sendButton: UIButton = {
        let btn = UIButton(type: .system)
        let image = UIImage(named: "ic_chat_send") ?? UIImage(systemName: "paperplane.fill")
        btn.setImage(image, for: .normal)
        btn.tintColor = Theme.Colors.primaryYellow
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    /// 底部四个扩展功能：语音、图片、视频、礼物（对应 Android ChatActivity 第二行功能按钮）
    private lazy var functionStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        title = chatUser?.name ?? "Chat"
        view.backgroundColor = Theme.Colors.darkBackground
        setupNavigationItems()
        setupUI()
        setupActions()
        setupKeyboardObservers()
        loadMockMessages()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - 界面搭建

    private func setupNavigationItems() {
        let image = UIImage(named: "ic_forum_more") ?? UIImage(systemName: "ellipsis")
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: image,
            style: .plain,
            target: self,
            action: #selector(moreTapped)
        )
    }

    private func setupUI() {
        view.addSubview(tableView)
        view.addSubview(inputContainer)
        view.addSubview(inputBar)
        inputBar.addSubview(inputField)
        inputBar.addSubview(sendButton)
        inputContainer.addSubview(functionStack)
        setupFunctionButtons()

        inputBarBottomConstraint = inputBar.bottomAnchor.constraint(equalTo: functionStack.topAnchor, constant: -10)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputBar.topAnchor),

            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            inputContainer.heightAnchor.constraint(equalToConstant: 76),

            inputBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputBarBottomConstraint!,
            inputBar.heightAnchor.constraint(equalToConstant: 56),

            inputField.leadingAnchor.constraint(equalTo: inputBar.leadingAnchor, constant: 16),
            inputField.topAnchor.constraint(equalTo: inputBar.topAnchor, constant: 6),
            inputField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            inputField.heightAnchor.constraint(equalToConstant: 44),

            sendButton.trailingAnchor.constraint(equalTo: inputBar.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: inputField.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 44),
            sendButton.heightAnchor.constraint(equalToConstant: 44),

            functionStack.topAnchor.constraint(equalTo: inputContainer.topAnchor, constant: 10),
            functionStack.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 16),
            functionStack.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -16),
            functionStack.heightAnchor.constraint(equalToConstant: 62)
        ])
    }

    /// 创建底部四个功能按钮
    private func setupFunctionButtons() {
        let items: [(icon: String, title: String, action: Selector)] = [
            ("ic_voice", "Voice", #selector(voiceTapped)),
            ("ic_chat_img", "Image", #selector(imageTapped)),
            ("ic_video", "Video", #selector(videoTapped)),
            ("ic_room_gift", "Gift", #selector(giftTapped))
        ]

        items.forEach { item in
            let button = makeFunctionButton(icon: item.icon, title: item.title, action: item.action)
            functionStack.addArrangedSubview(button)
        }
    }

    /// 单个功能入口：圆形深色底 + 图标 + 文字，对齐 Android 原型第二行
    private func makeFunctionButton(icon: String, title: String, action: Selector) -> UIControl {
        let control = UIControl()
        control.translatesAutoresizingMaskIntoConstraints = false
        control.addTarget(self, action: action, for: .touchUpInside)

        let iconWrap = UIView()
        iconWrap.backgroundColor = Theme.Colors.cardBackground
        iconWrap.layer.cornerRadius = 27
        iconWrap.translatesAutoresizingMaskIntoConstraints = false
        iconWrap.isUserInteractionEnabled = false

        let imageView = UIImageView(image: UIImage(named: icon))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = title
        label.font = Theme.Fonts.regular(11)
        label.textColor = Theme.Colors.textSecondary
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        control.addSubview(iconWrap)
        iconWrap.addSubview(imageView)
        control.addSubview(label)

        NSLayoutConstraint.activate([
            iconWrap.topAnchor.constraint(equalTo: control.topAnchor),
            iconWrap.centerXAnchor.constraint(equalTo: control.centerXAnchor),
            iconWrap.widthAnchor.constraint(equalToConstant: 54),
            iconWrap.heightAnchor.constraint(equalToConstant: 54),

            imageView.centerXAnchor.constraint(equalTo: iconWrap.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: iconWrap.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 34),
            imageView.heightAnchor.constraint(equalToConstant: 34),

            label.topAnchor.constraint(equalTo: iconWrap.bottomAnchor, constant: 3),
            label.centerXAnchor.constraint(equalTo: control.centerXAnchor)
        ])

        return control
    }

    // MARK: - 事件

    private func setupActions() {
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let keyboardFrameInView = view.convert(keyboardFrame, from: nil)
        let overlap = max(0, view.bounds.maxY - keyboardFrameInView.minY - view.safeAreaInsets.bottom)
        updateInputContainerBottom(overlap, notification: notification)
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        updateInputContainerBottom(0, notification: notification)
    }

    private func updateInputContainerBottom(_ offset: CGFloat, notification: Notification) {
        inputBarBottomConstraint?.constant = offset > 0 ? -offset : -10
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        let curveValue = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? UIView.AnimationOptions.curveEaseInOut.rawValue
        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curveValue << 16)) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.scrollToBottom(animated: false)
        }
    }

    @objc private func moreTapped() {
        dismissKeyboard()
        let alert = UIAlertController(title: chatUser?.name ?? "Chat", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Delete Chat", style: .destructive) { [weak self] _ in
            self?.confirmDeleteChat()
        })
        alert.addAction(UIAlertAction(title: "Report", style: .default) { [weak self] _ in
            self?.showReportSheet()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        present(alert, animated: true)
    }

    private func confirmDeleteChat() {
        let alert = UIAlertController(
            title: "Delete Chat?",
            message: "This will clear local messages in this chat.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.chatMessages.removeAll()
            self?.tableView.reloadData()
            self?.showAlert(title: "Chat deleted", message: "Local chat history has been cleared.")
        })
        present(alert, animated: true)
    }

    private func showReportSheet() {
        selectedReportReason = nil
        let alert = UIAlertController(
            title: "Report User",
            message: "Choose a reason. PlayTalk reviews reports about chat safety, scams, spam, fake profiles, and inappropriate content.",
            preferredStyle: .actionSheet
        )
        reportReasons.forEach { reason in
            alert.addAction(UIAlertAction(title: reason, style: .default) { [weak self] _ in
                self?.selectedReportReason = reason
                self?.showReportDetail(reason: reason)
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        present(alert, animated: true)
    }

    private func showReportDetail(reason: String) {
        let userName = chatUser?.name ?? "this user"
        let alert = UIAlertController(
            title: "Report \(userName)",
            message: "Reason: \(reason)\nAdd details to help us review faster.",
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.placeholder = "Describe what happened"
            textField.clearButtonMode = .whileEditing
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Submit", style: .destructive) { [weak self, weak alert] _ in
            let detail = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            self?.submitReport(reason: reason, detail: detail)
        })
        present(alert, animated: true)
    }

    private func submitReport(reason: String, detail: String) {
        let userName = chatUser?.name ?? "User"
        let message = detail.isEmpty
            ? "Thanks. We will review \(userName)'s recent chat activity."
            : "Thanks. We will review \(userName)'s recent chat activity and your details."
        selectedReportReason = reason
        showAlert(title: "Report submitted", message: message)
    }

    /// 语音：真实录音，再发送录音文件消息
    @objc private func voiceTapped() {
        dismissKeyboard()
        isRecording ? finishRecording() : requestMicrophoneAndStartRecording()
    }

    private func requestMicrophoneAndStartRecording() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                guard granted else {
                    self?.showAlert(title: "Microphone denied", message: "Enable microphone permission in Settings.")
                    return
                }
                self?.startRecording()
            }
        }
    }

    private func startRecording() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)

            let url = FileManager.default.temporaryDirectory.appendingPathComponent("voice-\(Int(Date().timeIntervalSince1970)).m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            recordingURL = url
            recordingStartTime = Date()
            isRecording = true
            showAlert(title: "Recording", message: "Tap Voice again to send.")
        } catch {
            showAlert(title: "Record failed", message: error.localizedDescription)
        }
    }

    private func finishRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false

        guard let url = recordingURL else { return }
        let duration = max(1, Int(Date().timeIntervalSince(recordingStartTime ?? Date())))
        recordingURL = nil
        recordingStartTime = nil
        appendMessage(.voice(url: url, duration: duration), isMe: true)
    }

    /// 图片：打开系统相册选择图片并插入聊天列表
    @objc private func imageTapped() {
        dismissKeyboard()
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        picker.view.tag = 1
        present(picker, animated: true)
    }

    /// 视频：打开系统相册选择视频，插入视频占位消息
    @objc private func videoTapped() {
        dismissKeyboard()
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .videos
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        picker.view.tag = 2
        present(picker, animated: true)
    }

    /// 礼物：复用语音房礼物选择器，发送后生成私聊礼物消息
    @objc private func giftTapped() {
        dismissKeyboard()
        let vc = GiftSelectorViewController()
        vc.modalPresentationStyle = .pageSheet
        if let sheet = vc.sheetPresentationController {
            if #available(iOS 16.0, *) {
                sheet.detents = [.custom { _ in 420 }]
            } else {
                sheet.detents = [.medium()]
            }
            sheet.prefersGrabberVisible = true
        }
        vc.onGiftSend = { [weak self] gift, count in
            self?.appendMessage(.gift(gift, count: count), isMe: true)
        }
        present(vc, animated: true)
    }

    /// 发送文本消息
    @objc private func sendTapped() {
        guard let text = inputField.text?.trimmingCharacters(in: .whitespaces), !text.isEmpty else { return }
        appendMessage(.text(text), isMe: true)
        inputField.text = ""
        dismissKeyboard()
    }

    private func appendMessage(_ kind: ChatMessageKind, isMe: Bool) {
        chatMessages.append(ChatMessageItem(kind: kind, isMe: isMe, time: "Just now"))
        tableView.reloadData()
        scrollToBottom()
    }

    // MARK: - 数据

    /// 加载 Mock 历史消息
    private func loadMockMessages() {
        chatMessages = [
            ChatMessageItem(kind: .text("Hey, how are you?"), isMe: false, time: "10 min ago"),
            ChatMessageItem(kind: .text("I'm good! Want to join my room?"), isMe: false, time: "9 min ago"),
            ChatMessageItem(kind: .text("Sure! Which game?"), isMe: true, time: "8 min ago"),
            ChatMessageItem(kind: .text("Let's play PUBG together!"), isMe: false, time: "7 min ago"),
            ChatMessageItem(kind: .text("Sounds fun! I'll be there in 5"), isMe: true, time: "5 min ago")
        ]
        tableView.reloadData()
        scrollToBottom()
    }

    /// 滚动到底部
    private func scrollToBottom(animated: Bool = true) {
        guard !chatMessages.isEmpty else { return }
        let lastRow = chatMessages.count - 1
        tableView.scrollToRow(at: IndexPath(row: lastRow, section: 0), at: .bottom, animated: animated)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    fileprivate func playVoice(url: URL) {
        let player = AVPlayerViewController()
        player.player = AVPlayer(url: url)
        present(player, animated: true) {
            player.player?.play()
        }
    }

    fileprivate func playVideo(url: URL) {
        let player = AVPlayerViewController()
        player.player = AVPlayer(url: url)
        present(player, animated: true) {
            player.player?.play()
        }
    }

    nonisolated private static func makeVideoThumbnail(url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        guard let cgImage = try? generator.copyCGImage(at: CMTime(seconds: 0.2, preferredTimescale: 600), actualTime: nil) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - 相册选择回调

extension ChatViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        let pickerType = picker.view.tag
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider else { return }

        if pickerType == 1, provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                guard let image = object as? UIImage else { return }
                DispatchQueue.main.async {
                    self?.appendMessage(.image(image), isMe: true)
                }
            }
        } else if pickerType == 2, provider.hasItemConformingToTypeIdentifier("public.movie") {
            provider.loadFileRepresentation(forTypeIdentifier: "public.movie") { [weak self] url, _ in
                guard let url else { return }
                let destination = FileManager.default.temporaryDirectory.appendingPathComponent("video-\(UUID().uuidString).mov")
                do {
                    if FileManager.default.fileExists(atPath: destination.path) {
                        try FileManager.default.removeItem(at: destination)
                    }
                    try FileManager.default.copyItem(at: url, to: destination)
                    let thumbnail = Self.makeVideoThumbnail(url: destination)
                    DispatchQueue.main.async {
                        self?.appendMessage(.video(url: destination, thumbnail: thumbnail), isMe: true)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self?.showAlert(title: "Video failed", message: error.localizedDescription)
                    }
                }
            }
        }
    }
}

// MARK: - TableView 数据源

extension ChatViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        chatMessages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatBubbleCell.reuseId, for: indexPath) as! ChatBubbleCell
        let msg = chatMessages[indexPath.row]
        cell.configure(kind: msg.kind, isMe: msg.isMe)
        cell.onVoiceTap = { [weak self] url in self?.playVoice(url: url) }
        cell.onVideoTap = { [weak self] url in self?.playVideo(url: url) }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        70
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        dismissKeyboard()
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                self?.chatMessages.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
            return UIMenu(children: [delete])
        }
    }
}

extension ChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendTapped()
        return true
    }
}

// MARK: - 聊天气泡 Cell

/// 聊天气泡（左=对方消息，右=我的消息）
class ChatBubbleCell: UITableViewCell {
    static let reuseId = "ChatBubbleCell"

    /// 气泡容器
    private let bubbleView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 16
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// 垂直内容容器，复用 cell 时清空后按消息类型重建
    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?
    var onVoiceTap: ((URL) -> Void)?
    var onVideoTap: ((URL) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(bubbleView)
        bubbleView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.72),

            contentStack.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 9),
            contentStack.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            contentStack.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            contentStack.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -9)
        ])

        leadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        trailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 配置气泡内容：文本/语音/图片/视频/礼物
    fileprivate func configure(kind: ChatViewController.ChatMessageKind, isMe: Bool) {
        contentStack.arrangedSubviews.forEach { view in
            contentStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        let isBareMedia: Bool
        if case .image = kind {
            isBareMedia = true
        } else {
            isBareMedia = false
        }

        bubbleView.backgroundColor = isBareMedia ? .clear : (isMe ? Theme.Colors.primaryYellow : Theme.Colors.cardBackground)
        leadingConstraint?.isActive = !isMe
        trailingConstraint?.isActive = isMe

        switch kind {
        case .text(let text):
            addText(text, textColor: isMe ? Theme.Colors.darkerBackground : Theme.Colors.textPrimary)
        case .voice(let url, let duration):
            addVoice(url: url, duration: duration, textColor: isMe ? Theme.Colors.darkerBackground : Theme.Colors.textPrimary)
        case .image(let image):
            addImage(image)
        case .video(let url, let thumbnail):
            addVideo(url: url, thumbnail: thumbnail, textColor: isMe ? Theme.Colors.darkerBackground : Theme.Colors.textPrimary)
        case .gift(let gift, let count):
            addGift(gift: gift, count: count, textColor: isMe ? Theme.Colors.darkerBackground : Theme.Colors.textPrimary)
        }
    }

    private func addText(_ text: String, textColor: UIColor) {
        let label = UILabel()
        label.text = text
        label.font = Theme.Fonts.regular(14)
        label.textColor = textColor
        label.numberOfLines = 0
        contentStack.addArrangedSubview(label)
    }

    private func addIconText(icon: UIImage?, text: String, textColor: UIColor) {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8

        let imageView = UIImageView(image: icon)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = textColor
        imageView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 24).isActive = true

        let label = UILabel()
        label.text = text
        label.font = Theme.Fonts.medium(14)
        label.textColor = textColor
        label.numberOfLines = 1

        row.addArrangedSubview(imageView)
        row.addArrangedSubview(label)
        contentStack.addArrangedSubview(row)
    }

    private func addVoice(url: URL, duration: Int, textColor: UIColor) {
        let button = UIButton(type: .system)
        button.tintColor = textColor
        button.setImage(UIImage(named: "ic_voice") ?? UIImage(systemName: "mic.fill"), for: .normal)
        button.setTitle("  Voice message  \(duration)s", for: .normal)
        button.setTitleColor(textColor, for: .normal)
        button.titleLabel?.font = Theme.Fonts.medium(14)
        button.contentHorizontalAlignment = .leading
        button.addAction(UIAction { [weak self] _ in
            self?.onVoiceTap?(url)
        }, for: .touchUpInside)
        contentStack.addArrangedSubview(button)
    }

    private func addImage(_ image: UIImage) {
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10
        imageView.widthAnchor.constraint(equalToConstant: 190).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 140).isActive = true
        contentStack.addArrangedSubview(imageView)
    }

    private func addVideo(url: URL, thumbnail: UIImage?, textColor: UIColor) {
        let button = UIButton(type: .custom)
        button.backgroundColor = Theme.Colors.cardBackground
        button.layer.cornerRadius = 12
        button.clipsToBounds = true
        button.widthAnchor.constraint(equalToConstant: 190).isActive = true
        button.heightAnchor.constraint(equalToConstant: 130).isActive = true
        button.addAction(UIAction { [weak self] _ in
            self?.onVideoTap?(url)
        }, for: .touchUpInside)

        if let thumbnail {
            button.setBackgroundImage(thumbnail, for: .normal)
        }

        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.28)
        overlay.isUserInteractionEnabled = false
        overlay.translatesAutoresizingMaskIntoConstraints = false

        let playIcon = UIImageView(image: UIImage(systemName: "play.circle.fill"))
        playIcon.tintColor = .white
        playIcon.contentMode = .scaleAspectFit
        playIcon.isUserInteractionEnabled = false
        playIcon.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "Video message"
        label.font = Theme.Fonts.medium(14)
        label.textColor = .white
        label.isUserInteractionEnabled = false
        label.translatesAutoresizingMaskIntoConstraints = false

        button.addSubview(overlay)
        button.addSubview(playIcon)
        button.addSubview(label)
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: button.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: button.bottomAnchor),
            playIcon.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            playIcon.centerYAnchor.constraint(equalTo: button.centerYAnchor, constant: -8),
            playIcon.widthAnchor.constraint(equalToConstant: 42),
            playIcon.heightAnchor.constraint(equalToConstant: 42),
            label.topAnchor.constraint(equalTo: playIcon.bottomAnchor, constant: 6),
            label.centerXAnchor.constraint(equalTo: button.centerXAnchor)
        ])
        contentStack.addArrangedSubview(button)
    }

    private func addGift(gift: Gift, count: Int, textColor: UIColor) {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8

        let imageView = UIImageView(image: UIImage(named: gift.imageName))
        imageView.contentMode = .scaleAspectFit
        imageView.widthAnchor.constraint(equalToConstant: 42).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 42).isActive = true

        let label = UILabel()
        label.text = "Sent \(gift.name) x\(count)"
        label.font = Theme.Fonts.medium(14)
        label.textColor = textColor
        label.numberOfLines = 2

        row.addArrangedSubview(imageView)
        row.addArrangedSubview(label)
        contentStack.addArrangedSubview(row)
    }
}
