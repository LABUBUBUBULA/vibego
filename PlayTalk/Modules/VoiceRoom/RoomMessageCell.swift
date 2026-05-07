import UIKit

/// 房间消息 Cell - 对应 Android RoomMessageAdapter 的 4 种消息布局
/// welcome: 黄色用户名欢迎消息
/// gift: 礼物赠送通知（发送者→接收者+礼物图标+数量）
/// comment: 用户聊天消息（头像+昵称+等级+内容）
/// announcement: 房间公告/提示（紫色背景）
class RoomMessageCell: UITableViewCell {
    static let reuseId = "RoomMessageCell"

    // MARK: - UI 组件

    /// 消息内容标签（用于 welcome 和 announcement 类型）
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.regular(13)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 消息容器（带背景色）
    private let bubbleView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 8
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - 初始化

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 布局

    private func setupUI() {
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(contentLabel)

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -60),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2),

            contentLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 6),
            contentLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 10),
            contentLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -10),
            contentLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -6)
        ])
    }

    // MARK: - 配置

    /// 根据消息类型配置 Cell 显示
    func configure(with message: RoomMessage) {
        switch message.type {
        case .welcome:
            // 欢迎消息 — 黄色用户名（对应 Android WelcomeViewHolder）
            bubbleView.backgroundColor = Theme.Colors.cardBackground
            let attrText = NSMutableAttributedString(string: message.content)
            // 高亮用户名部分
            if let range = message.content.range(of: "Welcome ") {
                let nameStart = message.content.index(range.upperBound, offsetBy: 0)
                if let nameEnd = message.content.range(of: " into") {
                    let nameRange = NSRange(nameStart..<nameEnd.lowerBound, in: message.content)
                    attrText.addAttribute(.foregroundColor, value: Theme.Colors.primaryYellow, range: nameRange)
                    attrText.addAttribute(.font, value: Theme.Fonts.bold(13), range: nameRange)
                }
            }
            attrText.addAttribute(.foregroundColor, value: Theme.Colors.textSecondary, range: NSRange(location: 0, length: 8))
            contentLabel.attributedText = attrText

        case .gift:
            // 礼物消息（对应 Android GiftViewHolder）
            bubbleView.backgroundColor = Theme.Colors.primaryYellow.withAlphaComponent(0.15)
            let text = "\(message.senderName ?? "") sent \(message.receiverName ?? "") 🎁 x\(message.giftCount ?? 1)"
            let attrText = NSMutableAttributedString(string: text)
            // 发送者和接收者名字用黄色
            if let sender = message.senderName {
                let senderRange = (text as NSString).range(of: sender)
                attrText.addAttribute(.foregroundColor, value: Theme.Colors.primaryYellow, range: senderRange)
                attrText.addAttribute(.font, value: Theme.Fonts.bold(13), range: senderRange)
            }
            if let receiver = message.receiverName {
                let receiverRange = (text as NSString).range(of: receiver)
                attrText.addAttribute(.foregroundColor, value: Theme.Colors.primaryYellow, range: receiverRange)
                attrText.addAttribute(.font, value: Theme.Fonts.bold(13), range: receiverRange)
            }
            contentLabel.attributedText = attrText

        case .comment:
            // 聊天消息（对应 Android CommentViewHolder）
            bubbleView.backgroundColor = Theme.Colors.cardBackground
            let nameText = "\(message.senderName ?? ""): "
            let fullText = nameText + message.content
            let attrText = NSMutableAttributedString(string: fullText)
            // 用户名黄色粗体
            let nameRange = NSRange(location: 0, length: nameText.count)
            attrText.addAttribute(.foregroundColor, value: Theme.Colors.primaryYellow, range: nameRange)
            attrText.addAttribute(.font, value: Theme.Fonts.bold(13), range: nameRange)
            // 内容白色
            let contentRange = NSRange(location: nameText.count, length: message.content.count)
            attrText.addAttribute(.foregroundColor, value: Theme.Colors.textPrimary, range: contentRange)
            attrText.addAttribute(.font, value: Theme.Fonts.regular(13), range: contentRange)
            contentLabel.attributedText = attrText

        case .announcement:
            // 公告消息（对应 Android AnnouncementViewHolder，紫色背景）
            bubbleView.backgroundColor = UIColor(hex: "#2A1B4A")
            contentLabel.text = message.content
            contentLabel.textColor = UIColor(hex: "#B8A9D4")
            contentLabel.font = Theme.Fonts.regular(11)
        }
    }
}
