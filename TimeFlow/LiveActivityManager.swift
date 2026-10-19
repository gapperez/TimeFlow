import ActivityKit
import Foundation

/// Muestra el tiempo en la pantalla de bloqueo (Live Activity).
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var activity: Activity<TimerActivityAttributes>?

    func sync(with engine: TimerEngine) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        guard engine.hasStarted, !engine.isFinished else {
            end()
            return
        }

        let now = Date()
        let referenceDate: Date
        switch engine.mode {
        case .countdown: referenceDate = now.addingTimeInterval(engine.remaining(at: now))
        case .stopwatch: referenceDate = now.addingTimeInterval(-engine.elapsed(at: now))
        }
        let state = TimerActivityAttributes.ContentState(mode: engine.mode,
                                                         isRunning: engine.isRunning,
                                                         referenceDate: referenceDate,
                                                         pausedSeconds: TimeInterval(engine.displaySeconds),
                                                         duration: engine.mode == .countdown ? engine.duration : 0)
        let content = ActivityContent(state: state, staleDate: nil)

        if let activity {
            Task { await activity.update(content) }
        } else {
            activity = try? Activity.request(attributes: TimerActivityAttributes(), content: content)
        }
    }

    func end() {
        guard let activity else { return }
        self.activity = nil
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }

    /// Cierra actividades que quedaron abiertas si la app se cerró a la fuerza.
    func endAll() {
        Task {
            for activity in Activity<TimerActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
