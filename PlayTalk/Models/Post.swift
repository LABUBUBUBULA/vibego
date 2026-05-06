import UIKit

/// 帖子模型 - 对应 Android GameMic 的 Post.java
/// 用于论坛板块的帖子列表和详情
struct Post {
    let id: Int                     // 帖子 ID
    var authorId: String            // 作者用户 ID
    var authorName: String          // 作者昵称
    var authorAvatar: String        // 作者头像
    var authorAvatarUri: String?    // 作者上传的头像 URI
    var time: String                // 发布时间（如 "5 min ago"）
    var title: String               // 帖子标题
    var content: String             // 帖子内容
    var images: [String]            // 图片资源名列表
    var imageUris: [String]         // 用户上传的图片 URI 列表
    var viewCount: Int              // 浏览量
    var commentCount: Int           // 评论数
    var likeCount: Int              // 点赞数
    var isLiked: Bool               // 当前用户是否已点赞
    var isFollowing: Bool           // 是否已关注作者
    var gameTag: String             // 所属游戏分类

    /// 浏览量显示文本（如 "78K"）
    var viewCountText: String {
        if viewCount >= 1000 {
            return String(format: "%.1fK", Double(viewCount) / 1000.0)
        }
        return "\(viewCount)"
    }
}
