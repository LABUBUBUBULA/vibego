import UIKit

/// Mock 数据管理器 - 对应 Android GameMic 的 MockDataRepository.java
/// 提供所有页面的模拟数据，不接真实 API
@MainActor
final class MockDataManager {

    static let shared = MockDataManager()
    private init() {}

    // MARK: - 固定用户列表（对应 Android 的 20 个 Mock 用户）

    /// 20 个固定用户数据
    lazy var users: [User] = {
        let names = ["Sophia", "Liam", "Emma", "Noah", "Olivia",
                     "William", "Ava", "James", "Isabella", "Oliver",
                     "Mia", "Benjamin", "Charlotte", "Elijah", "Amelia",
                     "Lucas", "Harper", "Mason", "Evelyn", "Logan"]

        let genders = ["female", "male", "female", "male", "female",
                       "male", "female", "male", "female", "male",
                       "female", "male", "female", "male", "female",
                       "male", "female", "male", "female", "male"]

        let ids = [54782, 23491, 87634, 19283, 65847,
                   42198, 73516, 31847, 96421, 58273,
                   14769, 82345, 67912, 45638, 29174,
                   83651, 37482, 91536, 64829, 15743]

        let bios = [
            "Love gaming and making new friends!",
            "PUBG pro player, looking for teammates",
            "Building worlds in Minecraft since 2015",
            "Fortnite enthusiast, let's squad up!",
            "Casual gamer, here for the vibes",
            "Competitive FPS player, always improving",
            "Creative mode builder, check my worlds!",
            "Stream sniper... just kidding 😄",
            "Looking for a chill voice chat room",
            "Game developer by day, gamer by night",
            "Sims 4 builder, gallery featured 3x",
            "Esports commentator, love voice chat",
            "New to gaming, please be nice!",
            "Speedrunner | WR holder in 3 games",
            "Music + gaming = perfect evening",
            "Minecraft redstone engineer",
            "Battle royale addict",
            "RPG lover, currently playing Fortnite",
            "Voice chat host, join my room!",
            "Just here to have fun and chat"
        ]

        let interests = ["PUBG,Minecraft", "PUBG", "Minecraft,TheSims", "Fortnite",
                         "PUBG,Fortnite", "PUBG,Fortnite", "Minecraft", "Fortnite,PUBG",
                         "TheSims", "Minecraft,Fortnite", "TheSims,Minecraft", "PUBG",
                         "Minecraft", "Fortnite,PUBG", "TheSims", "Minecraft",
                         "Fortnite", "PUBG,Minecraft", "PUBG", "Fortnite,TheSims"]

        return (0..<20).map { i in
            User(
                id: ids[i],
                name: names[i],
                avatarImage: "avatar_\(i + 1)",
                avatarUri: nil,
                bio: bios[i],
                gender: genders[i],
                countryFlag: "flag_\(i + 1)",
                level: (i % 10) + 1,
                backgroundImage: "bg_\(i + 1)",
                isFollowing: i % 3 == 0,
                interests: interests[i]
            )
        }
    }()

    // MARK: - 当前登录用户

    /// 当前登录用户（默认第一个用户）
    lazy var currentUser: User = users[0]

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
                hostCountry: "US",
                hostCountryFlag: user.countryFlag,
                memberCount: Int.random(in: 3...50),
                hotValue: Int.random(in: 100...9999)
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

    func removeUserCreatedRoom(roomId: String) {
        userCreatedRooms.removeAll { $0.roomId == roomId }
        if minimizedRoom?.roomId == roomId {
            clearMinimizedRoom()
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
        return (userCreatedRooms + voiceRooms).first { room in
            room.hostName == currentUser.name || room.hostAvatarImage == currentUser.avatarImage
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

        return (0..<5).map { i in
            let user = users[i]
            return Post(
                id: i + 1,
                authorId: "\(user.id)",
                authorName: user.name,
                authorAvatar: user.avatarImage,
                authorAvatarUri: nil,
                time: "\(Int.random(in: 1...24))h ago",
                title: titles[i],
                content: "This is the content for post \(i + 1)...",
                images: [],
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

    // MARK: - 消息数据

    /// 私聊消息列表
    lazy var messages: [Message] = {
        return (0..<8).map { i in
            let user = users[i + 1]
            return Message(
                userId: user.id,
                avatarImage: user.avatarImage,
                name: user.name,
                lastMessage: "Hey, want to join my room?",
                time: "\(Int.random(in: 1...59)) min ago",
                unreadCount: i < 3 ? Int.random(in: 1...5) : 0,
                timestamp: Date().timeIntervalSince1970 - Double(i * 3600),
                gender: user.gender,
                countryFlag: user.countryFlag,
                level: user.level,
                bio: user.bio
            )
        }
    }()

    // MARK: - 用户统计数据（对应 Android MineFragment）

    var fansCount: Int = 8486
    var followingCount: Int = 346
    var friendsCount: Int = 487000
    var coinBalance: Int = 12580
}
