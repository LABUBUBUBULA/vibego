import UIKit

/// 房间消息模型 - 对应 Android GameMic 的 RoomMessage.java
/// 支持 4 种消息类型：欢迎、礼物、评论、公告
struct RoomMessage: Codable {

    /// 消息类型枚举（对应 Android TYPE_WELCOME/GIFT/COMMENT/ANNOUNCEMENT）
    enum MessageType: String, Codable {
        case welcome        // 用户进入房间
        case gift           // 礼物赠送通知
        case comment        // 用户聊天消息
        case announcement   // 房间公告/提示
    }

    let type: MessageType       // 消息类型
    var content: String         // 消息内容
    var senderName: String?     // 发送者昵称
    var senderAvatar: String?   // 发送者头像
    var senderLevel: Int?       // 发送者等级
    var receiverName: String?   // 接收者昵称（礼物消息用）
    var giftImage: String?      // 礼物图片名（礼物消息用）
    var giftCount: Int?         // 礼物数量（礼物消息用）

    // MARK: - 工厂方法（对应 Android RoomMessage 的静态创建方法）

    /// 创建欢迎消息 - "Welcome {username} into the room"
    static func createWelcome(username: String) -> RoomMessage {
        return RoomMessage(
            type: .welcome,
            content: "Welcome \(username) into the room"
        )
    }

    /// 创建礼物消息 - "{sender} Send to {receiver} [gift] x{count}"
    static func createGift(senderName: String, receiverName: String, giftImage: String, giftCount: Int) -> RoomMessage {
        return RoomMessage(
            type: .gift,
            content: "",
            senderName: senderName,
            receiverName: receiverName,
            giftImage: giftImage,
            giftCount: giftCount
        )
    }

    /// 创建聊天消息 - 带用户头像和等级
    static func createComment(sender: User, content: String) -> RoomMessage {
        return RoomMessage(
            type: .comment,
            content: content,
            senderName: sender.name,
            senderAvatar: sender.displayAvatar,
            senderLevel: sender.level
        )
    }

    /// 创建公告消息 - 房间规则/提示
    static func createAnnouncement(content: String) -> RoomMessage {
        return RoomMessage(
            type: .announcement,
            content: content
        )
    }
}
