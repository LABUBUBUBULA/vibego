import UIKit

/// 用户管理器 - 对应 Android GameMic 的 UserManager.java
/// 负责登录状态、注册、密码重置、用户资料更新
/// 使用 UserDefaults 本地持久化（Mock 实现，不接真实 API）
@MainActor
final class UserManager {

    static let shared = UserManager()
    private init() {
        loadRegisteredData()
        loadLocalState()
    }

    private enum Keys {
        static let isLoggedIn = "isLoggedIn"
        static let currentUserEmail = "currentUserEmail"
        static let currentUserData = "currentUserData"
        static let registeredEmails = "registeredEmails"
        static let registeredProfiles = "registeredProfiles"
        static let deletedEmails = "deletedEmails"
    }

    // MARK: - 登录状态

    /// 当前是否已登录
    private(set) var isLoggedIn: Bool = false

    /// 当前登录用户（登录后才有值）
    private(set) var currentUser: User?

    /// 当前登录账号邮箱（注册用户用）
    private var currentUserEmail: String?

    // MARK: - 已注册邮箱列表（Mock 数据，模拟服务端存储）

    private var registeredEmails: [String: String] = [:] // email -> password
    private var registeredProfiles: [String: User] = [:] // email -> profile
    private var deletedEmails: Set<String> = []

    private let presetAccountUserIds: Set<Int> = [54782]

    /// 预设登录账号：用于展示完整 Mock 用户资料、头像、粉丝、聊天等
    private let presetAccounts: [String: (password: String, userIndex: Int)] = [
        "gamemic@gmail.com": ("123456789", 0),
        "playmeet@gmail.com": ("123456789", 0)
    ]

    // MARK: - 快速注册（对应 Android UserManager.quickRegister）

    private let defaultAvatarImage = "default_avatar"

    /// 一键快速注册，生成随机用户，直接登录
    /// - Returns: 注册成功的用户
    @discardableResult
    func quickRegister() -> User {
        let newUser = User(
            id: Int.random(in: 10000...99999),
            name: "User\(Int.random(in: 1000...9999))",
            avatarImage: defaultAvatarImage,
            avatarUri: nil,
            bio: "",
            gender: "male",
            countryFlag: "",
            level: 1,
            backgroundImage: "bg_mine",
            isFollowing: false,
            interests: ""
        )
        currentUser = newUser
        currentUserEmail = nil
        isLoggedIn = true
        saveLocalState()
        MockDataManager.shared.resetSessionDataForAccountSwitch()
        return newUser
    }

    // MARK: - 邮箱注册（对应 Android UserManager.registerWithEmail）

    /// 邮箱注册
    /// - Parameters:
    ///   - email: 邮箱地址
    ///   - password: 密码（至少6位）
    /// - Returns: 注册成功返回用户ID，失败返回nil
    func registerWithEmail(_ email: String, _ password: String) -> Int? {
        let normalizedEmail = email.lowercased()
        if deletedEmails.contains(normalizedEmail) || registeredEmails[normalizedEmail] != nil {
            return nil
        }

        registeredEmails[normalizedEmail] = password
        let newUser = makeRegisteredUser(email: normalizedEmail)
        registeredProfiles[normalizedEmail] = newUser
        currentUser = newUser
        currentUserEmail = normalizedEmail
        isLoggedIn = true
        saveRegisteredData()
        saveLocalState()
        MockDataManager.shared.resetSessionDataForAccountSwitch()
        return newUser.id
    }

    /// 检查邮箱是否已注册
    func isEmailRegistered(_ email: String) -> Bool {
        let normalizedEmail = email.lowercased()
        return !deletedEmails.contains(normalizedEmail) && (registeredEmails[normalizedEmail] != nil || presetAccounts[normalizedEmail] != nil)
    }

    // MARK: - 邮箱登录（对应 Android UserManager.loginWithEmail）

    /// 邮箱登录
    /// - Parameters:
    ///   - email: 邮箱
    ///   - password: 密码
    /// - Returns: 登录成功返回true
    func loginWithEmail(_ email: String, _ password: String) -> Bool {
        let normalizedEmail = email.lowercased()
        guard !deletedEmails.contains(normalizedEmail) else { return false }

        if let preset = presetAccounts[normalizedEmail] {
            guard preset.password == password else { return false }
            currentUser = MockDataManager.shared.users[preset.userIndex]
            currentUserEmail = nil
            isLoggedIn = true
            saveLocalState()
            MockDataManager.shared.resetSessionDataForAccountSwitch()
            return true
        }

        guard let storedPassword = registeredEmails[normalizedEmail], storedPassword == password else {
            return false
        }

        if let profile = registeredProfiles[normalizedEmail] {
            currentUser = profile
        } else {
            let profile = makeRegisteredUser(email: normalizedEmail)
            registeredProfiles[normalizedEmail] = profile
            currentUser = profile
            saveRegisteredData()
        }

        currentUserEmail = normalizedEmail
        isLoggedIn = true
        saveLocalState()
        MockDataManager.shared.resetSessionDataForAccountSwitch()
        return true
    }

    // MARK: - 密码重置（对应 Android UserManager.resetPassword）

    /// 重置密码
    /// - Parameters:
    ///   - email: 已注册的邮箱
    ///   - newPassword: 新密码
    /// - Returns: 重置成功返回true
    func resetPassword(_ email: String, _ newPassword: String) -> Bool {
        let normalizedEmail = email.lowercased()
        guard !deletedEmails.contains(normalizedEmail), registeredEmails[normalizedEmail] != nil else {
            return false
        }
        registeredEmails[normalizedEmail] = newPassword
        saveRegisteredData()
        return true
    }

    // MARK: - 更新用户资料（对应 Android UserManager.updateUserProfile）

    /// 完善/更新用户资料
    func updateUserProfile(
        nickname: String,
        gender: String,
        avatarUri: String?,
        country: String,
        countryFlag: String,
        interests: String,
        bio: String? = nil
    ) {
        var user = currentUser ?? makeRegisteredUser(email: currentUserEmail ?? "")
        user.name = nickname
        user.gender = gender
        user.avatarUri = avatarUri
        user.countryFlag = countryFlag
        user.interests = interests
        if let bio = bio {
            user.bio = bio
        }
        currentUser = user
        isLoggedIn = true
        if let email = currentUserEmail {
            registeredProfiles[email] = user
            saveRegisteredData()
        }
        saveLocalState()
    }

    func isPresetAccountUserId(_ userId: Int) -> Bool {
        presetAccountUserIds.contains(userId)
    }

    var currentAccountKey: String {
        guard let user = currentUser else { return "guest" }
        return isPresetAccountUserId(user.id) ? "preset_\(user.id)" : "user_\(user.id)"
    }

    // MARK: - 退出登录

    /// 退出登录，清除用户数据
    func logout() {
        currentUser = nil
        currentUserEmail = nil
        isLoggedIn = false
        UserDefaults.standard.removeObject(forKey: Keys.isLoggedIn)
        UserDefaults.standard.removeObject(forKey: Keys.currentUserEmail)
        UserDefaults.standard.removeObject(forKey: Keys.currentUserData)
    }

    /// 删除当前账号，删除后邮箱不能重新登录或注册
    func deleteCurrentAccount() {
        if let email = currentUserEmail?.lowercased() {
            deletedEmails.insert(email)
            registeredEmails.removeValue(forKey: email)
            registeredProfiles.removeValue(forKey: email)
            saveRegisteredData()
        } else {
            deletedEmails.insert("playmeet@gmail.com")
            deletedEmails.insert("gamemic@gmail.com")
            saveRegisteredData()
        }
        logout()
    }

    // MARK: - 本地状态持久化

    /// 保存登录状态到 UserDefaults
    private func saveLocalState() {
        UserDefaults.standard.set(isLoggedIn, forKey: Keys.isLoggedIn)
        UserDefaults.standard.set(currentUserEmail, forKey: Keys.currentUserEmail)
        if let user = currentUser,
           let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: Keys.currentUserData)
        } else {
            UserDefaults.standard.removeObject(forKey: Keys.currentUserData)
        }
    }

    private func saveRegisteredData() {
        if let emailsData = try? JSONEncoder().encode(registeredEmails) {
            UserDefaults.standard.set(emailsData, forKey: Keys.registeredEmails)
        }
        if let profilesData = try? JSONEncoder().encode(registeredProfiles) {
            UserDefaults.standard.set(profilesData, forKey: Keys.registeredProfiles)
        }
        if let deletedData = try? JSONEncoder().encode(Array(deletedEmails)) {
            UserDefaults.standard.set(deletedData, forKey: Keys.deletedEmails)
        }
    }

    private func loadRegisteredData() {
        if let emailsData = UserDefaults.standard.data(forKey: Keys.registeredEmails),
           let emails = try? JSONDecoder().decode([String: String].self, from: emailsData) {
            registeredEmails = emails
        }
        if let profilesData = UserDefaults.standard.data(forKey: Keys.registeredProfiles),
           let profiles = try? JSONDecoder().decode([String: User].self, from: profilesData) {
            registeredProfiles = profiles
        }
        if let deletedData = UserDefaults.standard.data(forKey: Keys.deletedEmails),
           let emails = try? JSONDecoder().decode([String].self, from: deletedData) {
            deletedEmails = Set(emails.map { $0.lowercased() })
        }
    }

    /// 从 UserDefaults 恢复登录状态
    private func loadLocalState() {
        isLoggedIn = UserDefaults.standard.bool(forKey: Keys.isLoggedIn)
        currentUserEmail = UserDefaults.standard.string(forKey: Keys.currentUserEmail)

        if let data = UserDefaults.standard.data(forKey: Keys.currentUserData),
           let savedUser = try? JSONDecoder().decode(User.self, from: data) {
            currentUser = savedUser
            return
        }

        if isLoggedIn, let email = currentUserEmail, let savedProfile = registeredProfiles[email] {
            currentUser = savedProfile
            return
        }

        if isLoggedIn {
            currentUser = MockDataManager.shared.users[0]
        }
    }

    private func makeRegisteredUser(email: String) -> User {
        let namePart = email.split(separator: "@").first.map(String.init) ?? "User"
        return User(
            id: Int.random(in: 10000...99999),
            name: namePart,
            avatarImage: defaultAvatarImage,
            avatarUri: nil,
            bio: "",
            gender: "male",
            countryFlag: "",
            level: 1,
            backgroundImage: "bg_mine",
            isFollowing: false,
            interests: ""
        )
    }
}
