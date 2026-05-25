import Foundation

/// 用户行为上报 - 异步，不阻塞用户流程
/// 接口: /opi/v1/track/activv (末尾 v)
/// 参数通配符：最后一个字母匹配即可
final class BehaviorTracker {

    static let shared = BehaviorTracker()
    private init() {
        openViewId = UUID().uuidString
        appOpenTime = Date()
        checkFirstOpen()
    }

    /// 每次打开生成唯一 ID，关联同一次打开的所有事件
    private(set) var openViewId: String

    /// App 启动时间，用于计算耗时
    private let appOpenTime: Date

    /// 是否首次打开
    private var isFirstOpen: Bool = false

    private static let firstOpenKey = "BehaviorTracker.hasOpened"

    private func checkFirstOpen() {
        if !UserDefaults.standard.bool(forKey: Self.firstOpenKey) {
            isFirstOpen = true
            UserDefaults.standard.set(true, forKey: Self.firstOpenKey)
        }
    }

    /// 重置（每次 App 启动调一次）
    func resetSession() {
        openViewId = UUID().uuidString
    }

    // MARK: - 事件上报

    /// 事件名称枚举
    enum Event: String {
        case appOpen            = "app_open"
        case originalView       = "original_view"       // 进入 A 面
        case normalView         = "normal_view"          // 进入 B 面
        case viewError          = "view_error"           // H5 地址异常
        case pageLoadBegin      = "page_load_begin"
        case pageLoadEnd        = "page_load_end"
        case pageLoadError      = "page_load_error"
        case viewLogin          = "view_login"           // 登录页面
        case loginBtnClick      = "login_btn_click"
        case loginError         = "login_error"
        case loginSuccess       = "login_success"
    }

    /// 上报事件
    func track(_ event: Event) {
        let elapsed = Int(Date().timeIntervalSince(appOpenTime) * 1000) // 毫秒

        // 参数通配符：最后一个字母匹配即可
        // e → viewEventName, n → firstOpen, g → timeConsuming, i → openViewId
        let params: [String: Any] = [
            "rpe": event.rawValue,               // 末尾 e
            "fon": isFirstOpen ? 1 : 0,          // 末尾 n
            "tmcg": elapsed,                      // 末尾 g
            "vwi": openViewId                     // 末尾 i
        ]

        GatewayAPI.shared.reportAsync(
            path: GatewayConfig.Path.behaviorReport,
            params: params
        )
    }
}
