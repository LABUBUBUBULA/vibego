import Foundation

@MainActor
final class ModerationManager {
    static let shared = ModerationManager()
    static let moderationDidChange = Notification.Name("ModerationManagerDidChange")

    enum TargetType: String, Codable {
        case user
        case post
        case comment
        case chat
        case room
        case roomMessage
    }

    struct ContentCheck {
        let isAllowed: Bool
        let matchedTerms: [String]

        var userMessage: String {
            guard !isAllowed else { return "" }
            return "Please remove objectionable content before posting."
        }
    }

    struct ModerationReport: Codable {
        let id: String
        let targetType: TargetType
        let targetId: String
        let targetUserId: Int?
        let targetName: String
        let reason: String
        let detail: String
        let contentSnapshot: String
        let createdAt: Date
        let reviewDeadline: Date
        let status: String
    }

    private let blockedUsersKeyPrefix = "ModerationManager.blockedUsers"
    private let hiddenPostsKeyPrefix = "ModerationManager.hiddenPosts"
    private let hiddenRoomsKeyPrefix = "ModerationManager.hiddenRooms"
    private let reportsKeyPrefix = "ModerationManager.reports"

    private var loadedAccountKey: String?
    private var blockedUserIds: Set<Int> = []
    private var hiddenPostIds: Set<Int> = []
    private var hiddenRoomIds: Set<String> = []
    private var reports: [ModerationReport] = []

    private let objectionableTerms: [String] = [
        "abuse", "bully", "harass", "hate speech", "kill yourself",
        "nude", "porn", "sexually explicit", "minor sex", "underage sex",
        "racist", "scam", "fraud", "spam", "terrorist", "illegal drugs",
        "self harm", "suicide", "threat", "violence"
    ]

    private init() {}

    private var accountKey: String {
        UserManager.shared.currentAccountKey
    }

    private func key(_ prefix: String) -> String {
        "\(prefix).\(accountKey)"
    }

    private func ensureLoaded() {
        guard loadedAccountKey != accountKey else { return }
        loadedAccountKey = accountKey
        blockedUserIds = Set(UserDefaults.standard.array(forKey: key(blockedUsersKeyPrefix)) as? [Int] ?? [])
        hiddenPostIds = Set(UserDefaults.standard.array(forKey: key(hiddenPostsKeyPrefix)) as? [Int] ?? [])
        hiddenRoomIds = Set(UserDefaults.standard.array(forKey: key(hiddenRoomsKeyPrefix)) as? [String] ?? [])
        if let data = UserDefaults.standard.data(forKey: key(reportsKeyPrefix)),
           let savedReports = try? JSONDecoder().decode([ModerationReport].self, from: data) {
            reports = savedReports
        } else {
            reports = []
        }
    }

    private func saveBlockedUsers() {
        UserDefaults.standard.set(Array(blockedUserIds), forKey: key(blockedUsersKeyPrefix))
    }

    private func saveHiddenPosts() {
        UserDefaults.standard.set(Array(hiddenPostIds), forKey: key(hiddenPostsKeyPrefix))
    }

    private func saveHiddenRooms() {
        UserDefaults.standard.set(Array(hiddenRoomIds), forKey: key(hiddenRoomsKeyPrefix))
    }

    private func saveReports() {
        guard let data = try? JSONEncoder().encode(reports) else { return }
        UserDefaults.standard.set(data, forKey: key(reportsKeyPrefix))
    }

    private func notifyChange() {
        NotificationCenter.default.post(name: Self.moderationDidChange, object: nil)
    }

    func checkContent(_ texts: [String]) -> ContentCheck {
        let combined = texts
            .map { $0.lowercased() }
            .joined(separator: " ")

        let matches = objectionableTerms.filter { term in
            combined.contains(term)
        }
        return ContentCheck(isAllowed: matches.isEmpty, matchedTerms: matches)
    }

    @discardableResult
    func submitReport(
        targetType: TargetType,
        targetId: String,
        targetUserId: Int?,
        targetName: String,
        reason: String,
        detail: String,
        contentSnapshot: String
    ) -> ModerationReport {
        ensureLoaded()
        let createdAt = Date()
        let report = ModerationReport(
            id: UUID().uuidString,
            targetType: targetType,
            targetId: targetId,
            targetUserId: targetUserId,
            targetName: targetName,
            reason: reason,
            detail: detail,
            contentSnapshot: contentSnapshot,
            createdAt: createdAt,
            reviewDeadline: createdAt.addingTimeInterval(24 * 60 * 60),
            status: "pending_review"
        )
        reports.insert(report, at: 0)
        saveReports()
        return report
    }

    func blockUser(
        userId: Int,
        name: String,
        source: TargetType,
        sourceId: String,
        reason: String,
        detail: String = "",
        contentSnapshot: String = ""
    ) {
        ensureLoaded()
        let currentUserId = UserManager.shared.currentUser?.id ?? MockDataManager.shared.users[0].id
        guard userId != currentUserId else { return }
        blockedUserIds.insert(userId)
        saveBlockedUsers()
        submitReport(
            targetType: .user,
            targetId: "\(userId)",
            targetUserId: userId,
            targetName: name,
            reason: reason,
            detail: detail.isEmpty ? "User blocked from \(source.rawValue)." : detail,
            contentSnapshot: contentSnapshot
        )
        notifyChange()
    }

    func unblockUser(userId: Int) {
        ensureLoaded()
        blockedUserIds.remove(userId)
        saveBlockedUsers()
        notifyChange()
    }

    func isBlocked(userId: Int) -> Bool {
        ensureLoaded()
        return blockedUserIds.contains(userId)
    }

    func blockedUsers() -> [User] {
        ensureLoaded()
        return blockedUserIds
            .compactMap { MockDataManager.shared.user(withId: $0) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func hidePost(id: Int) {
        ensureLoaded()
        hiddenPostIds.insert(id)
        saveHiddenPosts()
        notifyChange()
    }

    func hideRoom(id: String) {
        ensureLoaded()
        hiddenRoomIds.insert(id)
        saveHiddenRooms()
        notifyChange()
    }

    func isRoomHidden(id: String) -> Bool {
        ensureLoaded()
        return hiddenRoomIds.contains(id)
    }

    func shouldShow(post: Post) -> Bool {
        ensureLoaded()
        if hiddenPostIds.contains(post.id) { return false }
        if let authorId = Int(post.authorId), blockedUserIds.contains(authorId) { return false }
        return true
    }

    func shouldShow(user: User) -> Bool {
        !isBlocked(userId: user.id)
    }

    func shouldShow(message: Message) -> Bool {
        !isBlocked(userId: message.userId)
    }

    func shouldShow(room: VoiceRoom) -> Bool {
        ensureLoaded()
        if hiddenRoomIds.contains(room.roomId) { return false }
        if let host = MockDataManager.shared.users.first(where: { $0.name == room.hostName || $0.displayAvatar == room.hostAvatarImage || $0.avatarImage == room.hostAvatarImage }) {
            return !blockedUserIds.contains(host.id)
        }
        return true
    }

    func reportsPendingReviewCount() -> Int {
        ensureLoaded()
        return reports.filter { $0.status == "pending_review" }.count
    }
}
