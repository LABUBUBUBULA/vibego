import UIKit

/// 语音房模型 - 对应 Android GameMic 的 GameDiscussion.java
/// 包含房间信息、房主信息、热度等
struct VoiceRoom {
    let roomId: String              // 房间 ID
    var title: String               // 房间标题
    var coverImage: String          // 封面图片名
    var coverUri: String?           // 用户上传的封面 URI
    var gameTag: String             // 游戏分类标签（PUBG/Minecraft/Fortnite/TheSims）
    var description: String         // 房间描述（最多2行）
    var roomName: String            // 房间名称
    var isCollected: Bool           // 是否已收藏

    // 房主信息
    var hostName: String            // 房主昵称
    var hostAvatarImage: String     // 房主头像
    var hostCountry: String         // 房主国家
    var hostCountryFlag: String     // 房主国旗图片名

    // 房间数据
    var memberCount: Int            // 在线人数
    var hotValue: Int               // 热度值（用于排序）

    /// 热度显示文本（如 "1.2K"）
    var hotCountText: String {
        if hotValue >= 1000 {
            return String(format: "%.1fK", Double(hotValue) / 1000.0)
        }
        return "\(hotValue)"
    }

    /// 获取显示用的封面（优先 URI）
    var displayCover: String {
        return coverUri ?? coverImage
    }
}
