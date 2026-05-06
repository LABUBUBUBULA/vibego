import UIKit

/// 消息模型 - 对应 Android GameMic 的 Message.java
/// 用于消息列表展示私聊记录
struct Message {
    let userId: Int                 // 对方用户 ID
    var avatarImage: String         // 对方头像
    var name: String                // 对方昵称
    var lastMessage: String         // 最后一条消息预览（单行省略）
    var time: String                // 时间（如 "2 min ago"）
    var unreadCount: Int            // 未读消息数
    var timestamp: TimeInterval     // 时间戳（用于排序）
    var gender: String              // 性别
    var countryFlag: String         // 国旗
    var level: Int                  // 等级
    var bio: String                 // 个人签名
}
