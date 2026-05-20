import UIKit

/// Mock 数据管理器 - 对应 Android GameMic 的 MockDataRepository.java
/// 提供所有页面的模拟数据，不接真实 API
@MainActor
final class MockDataManager {

    static let shared = MockDataManager()
    private init() {}

    // MARK: - 固定用户列表（对应 Android GameMic 的 TestAccountManager + MockDataRepository）

    /// 20 个固定用户数据（index 0 = Silas Brooks 测试账号，index 1-19 = Android MockDataRepository 用户）
    lazy var users: [User] = {
        // (name, id, avatar, gender, level, bg, interests, bio, isFollowing)
        let data: [(String, Int, String, String, Int, String, String, String, Bool)] = [
            // 测试账号 - 对应 Android TestAccountManager
            ("Silas Brooks",       54782, "avatar_21", "male",   8, "pubg_3",  "PUBG,Minecraft",    "Welcome to GameMic! Let's game together!", false),
            // Android MockDataRepository 用户 index 0-18
            ("James Smith",        23491, "avatar_1",  "male",   5, "bg_1",   "PUBG",              "Love gaming and making new friends!",        false),
            ("Emma Johnson",       78234, "avatar_2",  "female", 7, "bg_2",   "Minecraft",         "Just here to have fun and share awesome moments!", false),
            ("Michael Williams",   91456, "avatar_3",  "male",   3, "bg_3",   "PUBG,Fortnite",     "Gamer for life! Let's squad up!",            false),
            ("Sophia Brown",       12789, "avatar_4",  "female", 6, "bg_4",   "TheSims",           "Living my best gaming life!",                false),
            ("William Jones",      67823, "avatar_5",  "male",   4, "bg_5",   "Fortnite,PUBG",     "Always ready for new adventures!",           true),
            ("Olivia Garcia",      45129, "avatar_6",  "female", 8, "bg_6",   "Minecraft,TheSims", "Game hard, play harder!",                    true),
            ("David Miller",       89237, "avatar_7",  "male",   2, "bg_7",   "PUBG",              "Making memories one game at a time!",        true),
            ("Ava Davis",          34567, "avatar_8",  "female", 9, "bg_8",   "Fortnite",          "Friendly gamer looking for squad mates!",    true),
            ("Joseph Rodriguez",   71289, "avatar_9",  "male",   5, "bg_9",   "Minecraft,PUBG",    "Let's win together!",                        true),
            ("Isabella Martinez",  52341, "avatar_10", "female", 7, "bg_10",  "TheSims,Minecraft", "Passionate about gaming and good vibes!",    true),
            ("Daniel Hernandez",   98765, "avatar_11", "male",   3, "bg_11",  "PUBG,Fortnite",     "Here to chat and play! Hit me up!",          true),
            ("Mia Lopez",          43218, "avatar_12", "female", 6, "bg_12",  "TheSims",           "Gaming is my escape! Join me!",              true),
            ("Matthew Wilson",     65432, "avatar_13", "male",   4, "bg_13",  "Minecraft",         "Pro player in training!",                    true),
            ("Charlotte Anderson", 29876, "avatar_14", "female", 8, "bg_14",  "Fortnite,PUBG",     "Casual gamer with competitive spirit!",      true),
            ("Christopher Thomas", 81234, "avatar_15", "male",   5, "bg_15",  "PUBG,Minecraft",    "Love meeting new people through gaming!",    true),
            ("Amelia Taylor",      37654, "avatar_16", "female", 7, "bg_16",  "TheSims,Fortnite",  "Always up for a good game session!",         true),
            ("Andrew Moore",       56789, "avatar_17", "male",   2, "bg_17",  "Minecraft",         "Gaming enthusiast and proud of it!",         false),
            ("Harper Jackson",     42398, "avatar_18", "female", 6, "bg_18",  "Fortnite",          "Let's create epic gaming moments!",          false),
            ("Joshua Martin",      73456, "avatar_19", "male",   4, "bg_19",  "PUBG,Minecraft",    "Friendly, fun, and ready to play!",          false),
        ]

        return data.map { d in
            User(
                id: d.1,
                name: d.0,
                avatarImage: d.2,
                avatarUri: nil,
                bio: d.7,
                gender: d.3,
                countryFlag: "",
                level: d.4,
                backgroundImage: d.5,
                // 关注关系统一放在 MockDataManager，所有页面都从这里读写，避免语聊房/主页/Mine 不同步。
                isFollowing: d.8,
                interests: d.6
            )
        }
    }()

    // MARK: - 当前登录用户

    /// 当前登录用户（默认第一个用户）
    lazy var currentUser: User = users[0]

    /// 判断当前用户是否为预设用户（非新注册）
    var isPresetUser: Bool {
        guard let current = UserManager.shared.currentUser else { return false }
        return users.contains { $0.id == current.id }
    }

    // MARK: - 语音房数据（对应 Android VoiceRoomRepository）

    /// 游戏分类列表
    let gameCategories = ["Popular", "PUBG", "Minecraft", "Fortnite", "TheSims"]

    /// 所有语音房数据
    lazy var voiceRooms: [VoiceRoom] = {
        let roomTitles = [
            "PUBG Squad Up!", "Minecraft Build Party", "Fortnite Duo Arena",
            "Sims House Tour", "Battle Royale Chat", "Redstone Engineering",
            "Creative Mode Fun", "Pro Scrims Lobby", "Chill Gaming Vibes",
            "Tournament Practice", "New Player Welcome", "Speed Build Challenge",
            "Story Mode Discussion", "Rank Push Together", "Music & Gaming",
            "Late Night Chat", "Morning Coffee Games", "Weekend Warriors",
            "Strategy Discussion", "Just Chatting"
        ]

        let tags = ["PUBG", "Minecraft", "Fortnite", "TheSims", "PUBG",
                    "Minecraft", "Minecraft", "PUBG", "Fortnite", "PUBG",
                    "Fortnite", "Minecraft", "TheSims", "PUBG", "TheSims",
                    "Fortnite", "PUBG", "Minecraft", "Fortnite", "TheSims"]

        let descriptions = [
            "Looking for squad members, mic required",
            "Come build amazing structures together",
            "Duo arena practice, NAE servers",
            "Touring the best Sims builds",
            "Open chat for all BR fans",
            "Learning redstone circuits together",
            "Free build, no rules, just fun",
            "Serious practice only, no trolling",
            "Relax and play, all games welcome",
            "Preparing for next tournament",
            "Beginners welcome, we'll teach you",
            "Timed builds, vote for the best",
            "Discussing game lore and stories",
            "Grinding ranks together, let's go!",
            "Share music while we game",
            "Night owls gaming session",
            "Early birds, grab your coffee",
            "Weekend gaming marathon",
            "Discussing strategies and tactics",
            "No game needed, just hang out"
        ]

        return (0..<20).map { i in
            let user = users[i % users.count]
            return VoiceRoom(
                roomId: "room_\(1000 + i)",
                title: roomTitles[i],
                coverImage: "\(tags[i].lowercased())_\((i % 6) + 1)",
                coverUri: nil,
                gameTag: tags[i],
                description: descriptions[i],
                roomName: roomTitles[i],
                isCollected: i % 5 == 0,
                hostName: user.name,
                hostAvatarImage: user.avatarImage,
                hostCountry: "",
                hostCountryFlag: "",
                memberCount: Int.random(in: 3...50),
                hotValue: Int.random(in: 80...980)
            )
        }
    }()

    // MARK: - 用户创建/最小化房间

    private var userCreatedRooms: [VoiceRoom] = []
    private var minimizedRoom: VoiceRoom?
    private var minimizedRoomIsOwner = false

    /// 按分类筛选语音房（Popular 按热度排前10，用户创建房间排前面）
    func getRooms(for category: String) -> [VoiceRoom] {
        let allRooms = userCreatedRooms + voiceRooms
        if category == "Popular" {
            let createdIds = Set(userCreatedRooms.map { $0.roomId })
            let sortedMockRooms = voiceRooms.sorted { $0.hotValue > $1.hotValue }
                .prefix(10)
                .filter { !createdIds.contains($0.roomId) }
            return userCreatedRooms + sortedMockRooms
        }
        return allRooms.filter { $0.gameTag == category }
    }

    func addUserCreatedRoom(_ room: VoiceRoom) {
        userCreatedRooms.removeAll { $0.roomId == room.roomId }
        userCreatedRooms.insert(room, at: 0)
    }

    func isUserCreatedRoom(_ room: VoiceRoom) -> Bool {
        userCreatedRooms.contains { $0.roomId == room.roomId }
    }

    func removeUserCreatedRoom(roomId: String) {
        userCreatedRooms.removeAll { $0.roomId == roomId }
        if minimizedRoom?.roomId == roomId {
            clearMinimizedRoom()
        }
    }

    func updateUserCreatedRoom(_ room: VoiceRoom) {
        if let index = userCreatedRooms.firstIndex(where: { $0.roomId == room.roomId }) {
            userCreatedRooms[index] = room
        }
        if let index = voiceRooms.firstIndex(where: { $0.roomId == room.roomId }) {
            voiceRooms[index] = room
        }
        if minimizedRoom?.roomId == room.roomId {
            minimizedRoom = room
        }
    }

    func setRoomCollected(roomId: String, isCollected: Bool) {
        if let index = userCreatedRooms.firstIndex(where: { $0.roomId == roomId }) {
            userCreatedRooms[index].isCollected = isCollected
        }
        if let index = voiceRooms.firstIndex(where: { $0.roomId == roomId }) {
            voiceRooms[index].isCollected = isCollected
        }
    }

    /// 我的收藏 - 对应 Android RoomCollectionManager.getCollections
    func getCollectedRooms() -> [VoiceRoom] {
        (userCreatedRooms + voiceRooms).filter { $0.isCollected }
    }

    /// 浏览记录 - 对应 Android BrowseHistoryManager，最新浏览排前，最多50条
    private var browseHistoryRoomIds: [String] = []

    func addBrowseHistory(_ room: VoiceRoom) {
        browseHistoryRoomIds.removeAll { $0 == room.roomId }
        browseHistoryRoomIds.insert(room.roomId, at: 0)
        if browseHistoryRoomIds.count > 50 {
            browseHistoryRoomIds = Array(browseHistoryRoomIds.prefix(50))
        }
    }

    func getBrowseHistoryRooms() -> [VoiceRoom] {
        browseHistoryRoomIds.compactMap { roomId in
            (userCreatedRooms + voiceRooms).first { $0.roomId == roomId }
        }
    }

    /// 我的房间 - 对应 Android MessageFragment.findUserRoom，只找当前用户作为房主的房间
    func getMyRoom() -> VoiceRoom? {
        guard let currentUser = UserManager.shared.currentUser else { return nil }
        return userCreatedRooms.first { room in
            room.hostName == currentUser.name && room.hostAvatarImage == currentUser.displayAvatar
        }
    }

    func saveMinimizedRoom(_ room: VoiceRoom, isOwner: Bool) {
        minimizedRoom = room
        minimizedRoomIsOwner = isOwner
    }

    func clearMinimizedRoom() {
        minimizedRoom = nil
        minimizedRoomIsOwner = false
    }

    func getMinimizedRoom() -> (room: VoiceRoom, isOwner: Bool)? {
        guard let room = minimizedRoom else { return nil }
        return (room, minimizedRoomIsOwner)
    }

    // MARK: - 论坛帖子数据

    /// 热门帖子（对应 Android ForumFragment 的 5 个热帖）
    lazy var hotPosts: [Post] = {
        let titles = [
            "Best PUBG drop locations in 2024",
            "Minecraft 1.21 update features revealed",
            "Fortnite Chapter 5 Season 2 tier list",
            "The Sims 5 announcement breakdown",
            "Top 10 gaming headsets for voice chat"
        ]

        let viewCounts = [78000, 45000, 32000, 28000, 15000]
        let postImages = ["pubg_1", "minecraft_1", "fortnite_1", "thesims_1", "bg_room_background"]

        return (0..<5).map { i in
            let user = users[i + 1]
            return Post(
                id: i + 1,
                authorId: "\(user.id)",
                authorName: user.name,
                authorAvatar: user.avatarImage,
                authorAvatarUri: nil,
                time: "\(Int.random(in: 1...24))h ago",
                title: titles[i],
                content: "This is the content for post \(i + 1)...",
                images: [postImages[i]],
                imageUris: [],
                viewCount: viewCounts[i],
                commentCount: Int.random(in: 10...200),
                likeCount: Int.random(in: 50...500),
                isLiked: false,
                isFollowing: false,
                gameTag: gameCategories[i % 4 + 1]
            )
        }
    }()

    /// 游戏频道数据（对应 Android ForumFragment 的 4 个频道）
    struct GameChannel {
        let name: String            // 游戏名
        let discussionCount: String // 讨论人数（如 "2228.21K"）
        let coverImage: String      // 频道封面图
    }

    let gameChannels: [GameChannel] = [
        GameChannel(name: "PUBG", discussionCount: "228 People Discuss", coverImage: "ph_pubg"),
        GameChannel(name: "Minecraft", discussionCount: "486 People Discuss", coverImage: "ph_minecraft"),
        GameChannel(name: "Fortnite", discussionCount: "368 People Discuss", coverImage: "ph_fortnite"),
        GameChannel(name: "TheSims", discussionCount: "325 People Discuss", coverImage: "ph_thesims")
    ]

    // MARK: - 用户发布的帖子（持久化）

    private let userPostsKey = "MockDataManager.userPosts"

    lazy var userPosts: [Post] = {
        guard let data = UserDefaults.standard.data(forKey: userPostsKey),
              let posts = try? JSONDecoder().decode([Post].self, from: data) else { return [] }
        return posts
    }()

    private func saveUserPosts() {
        guard let data = try? JSONEncoder().encode(userPosts) else { return }
        UserDefaults.standard.set(data, forKey: userPostsKey)
    }

    func addUserPost(_ post: Post) {
        userPosts.insert(post, at: 0)
        saveUserPosts()
    }

    func removeUserPost(id: Int) {
        userPosts.removeAll { $0.id == id }
        saveUserPosts()
    }

    func updateUserPost(_ post: Post) {
        if let index = userPosts.firstIndex(where: { $0.id == post.id }) {
            userPosts[index] = post
            saveUserPosts()
        }
    }

    func getUserPosts(gameTag: String) -> [Post] {
        userPosts.filter { $0.gameTag == gameTag }
    }

    // MARK: - 用户评论（持久化）

    private let userCommentsKey = "MockDataManager.userComments"

    struct UserComment: Codable {
        let postId: Int
        let userName: String
        let userAvatar: String
        let content: String
        let time: String
    }

    lazy var userComments: [UserComment] = {
        guard let data = UserDefaults.standard.data(forKey: userCommentsKey),
              let comments = try? JSONDecoder().decode([UserComment].self, from: data) else { return [] }
        return comments
    }()

    private func saveUserComments() {
        guard let data = try? JSONEncoder().encode(userComments) else { return }
        UserDefaults.standard.set(data, forKey: userCommentsKey)
    }

    func addUserComment(_ comment: UserComment) {
        userComments.insert(comment, at: 0)
        saveUserComments()
    }

    func getUserComments(postId: Int) -> [UserComment] {
        userComments.filter { $0.postId == postId }
    }

    // MARK: - 消息数据

    private let messagesStorageKey = "MockDataManager.messages"

    /// 私聊消息列表（带 UserDefaults 持久化，对应 ChatViewController 同款方案）
    lazy var messages: [Message] = {
        // 先尝试读取持久化数据
        if let data = UserDefaults.standard.data(forKey: messagesStorageKey),
           let saved = try? JSONDecoder().decode([Message].self, from: data),
           !saved.isEmpty {
            return saved
        }
        // 新注册用户不预填消息
        guard isPresetUser else { return [] }
        // 无持久化数据 → 使用预设值
        let lastMessages = [
            "Let's play PUBG together!",
            "I saved you a seat in my room.",
            "Minecraft build party starts soon.",
            "Send me your squad invite.",
            "Voice chat later?"
        ]
        let times = ["5 min ago", "18 min ago", "42 min ago", "1h ago", "2h ago"]
        let unreadCounts = [2, 1, 4, 0, 0]

        let defaults = (0..<5).map { i -> Message in
            let user = users[i + 1]
            return Message(
                userId: user.id,
                avatarImage: user.avatarImage,
                name: user.name,
                lastMessage: lastMessages[i],
                time: times[i],
                unreadCount: unreadCounts[i],
                timestamp: Date().timeIntervalSince1970 - Double([300, 1080, 2520, 3600, 7200][i]),
                gender: user.gender,
                countryFlag: "",
                level: user.level,
                bio: user.bio
            )
        }
        // 首次写入持久化
        if let data = try? JSONEncoder().encode(defaults) {
            UserDefaults.standard.set(data, forKey: messagesStorageKey)
        }
        return defaults
    }()

    private func saveMessages() {
        guard let data = try? JSONEncoder().encode(messages) else { return }
        UserDefaults.standard.set(data, forKey: messagesStorageKey)
    }

    func clearMessageSummary(userId: Int) {
        messages.removeAll { $0.userId == userId }
        saveMessages()
    }

    func markMessageRead(userId: Int) {
        guard let index = messages.firstIndex(where: { $0.userId == userId }) else { return }
        messages[index].unreadCount = 0
        saveMessages()
    }

    func updateMessageSummary(userId: Int, lastMessage: String, time: String, timestamp: TimeInterval) {
        if let index = messages.firstIndex(where: { $0.userId == userId }) {
            messages[index].lastMessage = lastMessage
            messages[index].time = time
            messages[index].timestamp = timestamp
        } else if let user = users.first(where: { $0.id == userId }) {
            messages.append(Message(
                userId: user.id,
                avatarImage: user.displayAvatar,
                name: user.name,
                lastMessage: lastMessage,
                time: time,
                unreadCount: 0,
                timestamp: timestamp,
                gender: user.gender,
                countryFlag: "",
                level: user.level,
                bio: user.bio
            ))
        }
        messages.sort { $0.timestamp > $1.timestamp }
        saveMessages()
    }

    // MARK: - 用户统计数据（对应 Android MineFragment）

    lazy var coinBalance: Int = isPresetUser ? 12580 : 0

    /// 固定粉丝：对应 Android 测试账号的 15 个粉丝（Android mock users index 0-14 = iOS index 1-15）
    private var fanUserIds: Set<Int> {
        Set(users.dropFirst().prefix(15).map { $0.id })
    }

    func getFansUsers() -> [User] {
        guard isPresetUser else { return [] }
        return users.filter { fanUserIds.contains($0.id) }
    }

    func getFollowingUsers() -> [User] {
        guard isPresetUser else { return users.filter { $0.isFollowing && $0.id != (UserManager.shared.currentUser?.id ?? 0) } }
        return users.filter { $0.isFollowing && $0.id != currentUser.id }
    }

    func getFriendUsers() -> [User] {
        guard isPresetUser else { return [] }
        return users.filter { $0.isFollowing && fanUserIds.contains($0.id) && $0.id != currentUser.id }
    }

    var fansCount: Int { getFansUsers().count }
    var followingCount: Int { getFollowingUsers().count }
    var friendsCount: Int { getFriendUsers().count }

    func user(withId userId: Int) -> User? {
        users.first { $0.id == userId }
    }

    func isFollowing(userId: Int) -> Bool {
        users.first { $0.id == userId }?.isFollowing == true
    }

    func userWithSyncedFollowState(_ user: User) -> User {
        guard let storedUser = self.user(withId: user.id) else { return user }
        return storedUser
    }

    func setFollowing(userId: Int, isFollowing: Bool) {
        guard let index = users.firstIndex(where: { $0.id == userId }), users[index].id != currentUser.id else { return }
        users[index].isFollowing = isFollowing
    }
}
