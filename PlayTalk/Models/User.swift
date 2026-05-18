import UIKit

/// 用户模型 - 对应 Android GameMic 的 User.java
/// 包含用户基本信息、社交属性、等级等
struct User: Codable {
    let id: Int                     // 用户 ID（5位数字，如 54782）
    var name: String                // 昵称
    var avatarImage: String         // 头像图片名（如 "avatar_1"）
    var avatarUri: String?          // 用户上传的头像 URI
    var bio: String                 // 个人签名
    var gender: String              // 性别："male" / "female"
    var countryFlag: String         // 国旗图片名
    var level: Int                  // 等级 1-10
    var backgroundImage: String     // 主页背景图
    var isFollowing: Bool           // 是否已关注

    /// 兴趣标签（逗号分隔，如 "PUBG,Minecraft"）
    var interests: String

    /// 获取显示用的头像（优先 URI，fallback 到本地资源）
    var displayAvatar: String {
        return avatarUri ?? avatarImage
    }
}
