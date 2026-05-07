import UIKit

/// 用户管理器 - 对应 Android GameMic 的 UserManager.java
/// 负责登录状态、注册、密码重置、用户资料更新
/// 使用 UserDefaults 本地持久化（Mock 实现，不接真实 API）
@MainActor
final class UserManager {

    static let shared = UserManager()
    private init() {
        loadLocalState()
    }

    // MARK: - 登录状态

    /// 当前是否已登录
    private(set) var isLoggedIn: Bool = false

    /// 当前登录用户（登录后才有值）
    private(set) var currentUser: User?

    // MARK: - 已注册邮箱列表（Mock 数据，模拟服务端存储）

    private var registeredEmails: [String: String] = [:] // email -> password

    // MARK: - 快速注册（对应 Android UserManager.quickRegister）

    /// 一键快速注册，生成随机用户，直接登录
    /// - Returns: 注册成功的用户
    @discardableResult
    func quickRegister() -> User {
        let mockUser = MockDataManager.shared.users[0]
        let newUser = User(
            id: Int.random(in: 10000...99999),
            name: "User\(Int.random(in: 1000...9999))",
            avatarImage: mockUser.avatarImage,
            avatarUri: nil,
            bio: "",
            gender: "male",
            countryFlag: "flag_usa",
            level: 1,
            backgroundImage: "bg_mine",
            isFollowing: false,
            interests: ""
        )
        currentUser = newUser
        isLoggedIn = true
        saveLocalState()
        return newUser
    }

    // MARK: - 邮箱注册（对应 Android UserManager.registerWithEmail）

    /// 邮箱注册
    /// - Parameters:
    ///   - email: 邮箱地址
    ///   - password: 密码（至少6位）
    /// - Returns: 注册成功返回用户ID，失败返回nil
    func registerWithEmail(_ email: String, _ password: String) -> Int? {
        // 检查邮箱是否已注册
        if registeredEmails[email] != nil {
            return nil
        }
        // 保存注册信息
        registeredEmails[email] = password
        let userId = Int.random(in: 10000...99999)
        return userId
    }

    /// 检查邮箱是否已注册
    func isEmailRegistered(_ email: String) -> Bool {
        return registeredEmails[email] != nil
    }

    // MARK: - 邮箱登录（对应 Android UserManager.loginWithEmail）

    /// 邮箱登录
    /// - Parameters:
    ///   - email: 邮箱
    ///   - password: 密码
    /// - Returns: 登录成功返回true
    func loginWithEmail(_ email: String, _ password: String) -> Bool {
        // Mock: 任意邮箱密码都能登录
        if let storedPassword = registeredEmails[email] {
            if storedPassword != password {
                return false
            }
        }
        let mockUser = MockDataManager.shared.users[0]
        currentUser = User(
            id: mockUser.id,
            name: mockUser.name,
            avatarImage: mockUser.avatarImage,
            avatarUri: nil,
            bio: mockUser.bio,
            gender: mockUser.gender,
            countryFlag: mockUser.countryFlag,
            level: mockUser.level,
            backgroundImage: mockUser.backgroundImage,
            isFollowing: false,
            interests: mockUser.interests
        )
        isLoggedIn = true
        saveLocalState()
        return true
    }

    // MARK: - 密码重置（对应 Android UserManager.resetPassword）

    /// 重置密码
    /// - Parameters:
    ///   - email: 已注册的邮箱
    ///   - newPassword: 新密码
    /// - Returns: 重置成功返回true
    func resetPassword(_ email: String, _ newPassword: String) -> Bool {
        guard registeredEmails[email] != nil else {
            return false
        }
        registeredEmails[email] = newPassword
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
        interests: String
    ) {
        currentUser?.name = nickname
        currentUser?.gender = gender
        currentUser?.avatarUri = avatarUri
        currentUser?.countryFlag = countryFlag
        currentUser?.interests = interests
        isLoggedIn = true
        saveLocalState()
    }

    // MARK: - 退出登录

    /// 退出登录，清除用户数据
    func logout() {
        currentUser = nil
        isLoggedIn = false
        UserDefaults.standard.removeObject(forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "userName")
    }

    // MARK: - 本地状态持久化

    /// 保存登录状态到 UserDefaults
    private func saveLocalState() {
        UserDefaults.standard.set(isLoggedIn, forKey: "isLoggedIn")
        UserDefaults.standard.set(currentUser?.name, forKey: "userName")
    }

    /// 从 UserDefaults 恢复登录状态
    private func loadLocalState() {
        isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        if isLoggedIn {
            let mockUser = MockDataManager.shared.users[0]
            let savedName = UserDefaults.standard.string(forKey: "userName") ?? mockUser.name
            currentUser = User(
                id: mockUser.id,
                name: savedName,
                avatarImage: mockUser.avatarImage,
                avatarUri: nil,
                bio: mockUser.bio,
                gender: mockUser.gender,
                countryFlag: mockUser.countryFlag,
                level: mockUser.level,
                backgroundImage: mockUser.backgroundImage,
                isFollowing: false,
                interests: mockUser.interests
            )
        }
    }
}
