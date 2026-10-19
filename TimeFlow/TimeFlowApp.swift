import SwiftUI
import UserNotifications

@main
struct TimeFlowApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var engine: TimerEngine
    @StateObject private var pip: PiPController

    init() {
        let engine = TimerEngine()
        engine.onStateChange = { engine in
            TimerAlerts.sync(with: engine)
            LiveActivityManager.shared.sync(with: engine)
        }
        _engine = StateObject(wrappedValue: engine)
        _pip = StateObject(wrappedValue: PiPController(engine: engine))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(engine)
                .environmentObject(pip)
                .preferredColorScheme(.dark)
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        TimerAlerts.requestAuthorization()
        LiveActivityManager.shared.endAll()
        return true
    }

    /// Muestra el aviso también cuando la app está abierta.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
