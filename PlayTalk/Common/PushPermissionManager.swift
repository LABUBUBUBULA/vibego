import UIKit
import UserNotifications

final class PushPermissionManager {
    static let shared = PushPermissionManager()

    private var hasCheckedAuthorizationThisSession = false

    private init() {}

    func registerForRemoteNotifications(_ application: UIApplication) {
        if Thread.isMainThread {
            application.registerForRemoteNotifications()
        } else {
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
    }

    func requestAuthorizationAfterHomeVisible() {
        guard !hasCheckedAuthorizationThisSession else { return }
        hasCheckedAuthorizationThisSession = true

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else {
                DispatchQueue.main.async {
                    self.registerForRemoteNotifications(UIApplication.shared)
                }
                return
            }

            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                print("🔔 [Push] 权限: \(granted)")
                DispatchQueue.main.async {
                    self.registerForRemoteNotifications(UIApplication.shared)
                }
            }
        }
    }
}
