import UserNotifications

/// Aviso con sonido cuando termina el temporizador, aunque la app esté cerrada.
enum TimerAlerts {
    private static let identifier = "timeflow.countdown.finished"

    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func sync(with engine: TimerEngine) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard engine.mode == .countdown, engine.isRunning else { return }
        let remaining = engine.remaining()
        guard remaining > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "TimeFlow"
        content.body = "El temporizador terminó"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: remaining, repeats: false)
        center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }
}
