import ActivityKit
import Foundation

/// Datos que la app comparte con la Live Activity (pantalla de bloqueo).
struct TimerActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var mode: TimerMode
        var isRunning: Bool
        /// Cronómetro: hora virtual de inicio. Temporizador: hora en que termina.
        var referenceDate: Date
        /// Segundos que se muestran cuando está en pausa.
        var pausedSeconds: TimeInterval
        /// Duración total del temporizador (0 en cronómetro).
        var duration: TimeInterval
    }
}
