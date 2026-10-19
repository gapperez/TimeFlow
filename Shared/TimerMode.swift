import SwiftUI

enum TimerMode: String, Codable, Hashable, CaseIterable, Identifiable {
    case stopwatch
    case countdown

    var id: Self { self }

    var title: String {
        switch self {
        case .stopwatch: return "Cronómetro"
        case .countdown: return "Temporizador"
        }
    }

    var symbol: String {
        switch self {
        case .stopwatch: return "stopwatch"
        case .countdown: return "timer"
        }
    }

    /// Morado para el temporizador, verde para el cronómetro.
    var tint: Color {
        switch self {
        case .stopwatch: return Color(red: 0.20, green: 0.78, blue: 0.35)
        case .countdown: return Color(red: 0.48, green: 0.42, blue: 1.00)
        }
    }
}

enum TimeFormat {
    /// "29:57" o "1:05:09" cuando pasa de una hora.
    static func string(_ seconds: Int) -> String {
        let total = max(0, seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}
