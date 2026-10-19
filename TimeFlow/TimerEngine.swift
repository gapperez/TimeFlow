import Combine
import Foundation

/// Lleva el tiempo del cronómetro y del temporizador.
/// Se basa en fechas, así que sigue siendo exacto aunque la app pase a segundo plano.
final class TimerEngine: ObservableObject {
    @Published private(set) var mode: TimerMode = .countdown
    @Published var duration: TimeInterval = 30 * 60
    @Published private(set) var isRunning = false
    /// Cambia varias veces por segundo mientras corre, para refrescar la pantalla.
    @Published private(set) var tick = Date()

    /// Se llama cada vez que se inicia, pausa, reinicia o termina.
    var onStateChange: ((TimerEngine) -> Void)?

    private var segmentStart: Date?
    private var accumulated: TimeInterval = 0
    private var ticker: AnyCancellable?

    var hasStarted: Bool { isRunning || accumulated > 0 }

    var isFinished: Bool { mode == .countdown && hasStarted && remaining() <= 0 }

    func elapsed(at date: Date = Date()) -> TimeInterval {
        accumulated + (segmentStart.map { date.timeIntervalSince($0) } ?? 0)
    }

    func remaining(at date: Date = Date()) -> TimeInterval {
        max(0, duration - elapsed(at: date))
    }

    /// Segundos a mostrar: el temporizador redondea hacia arriba (30:00 al empezar, 00:00 al terminar).
    var displaySeconds: Int {
        switch mode {
        case .countdown: return Int(remaining().rounded(.up))
        case .stopwatch: return Int(elapsed())
        }
    }

    /// Temporizador: fracción que queda. Cronómetro: avance dentro del minuto actual.
    var progress: Double {
        switch mode {
        case .countdown: return duration > 0 ? remaining() / duration : 0
        case .stopwatch: return elapsed().truncatingRemainder(dividingBy: 60) / 60
        }
    }

    func setMode(_ newMode: TimerMode) {
        guard newMode != mode else { return }
        reset()
        mode = newMode
    }

    func start() {
        if isFinished { reset() }
        guard !isRunning, mode == .stopwatch || duration > 0 else { return }
        segmentStart = Date()
        isRunning = true
        startTicker()
        changed()
    }

    func pause() {
        guard isRunning else { return }
        accumulated = elapsed()
        segmentStart = nil
        isRunning = false
        stopTicker()
        changed()
    }

    func toggle() {
        isRunning ? pause() : start()
    }

    func reset() {
        stopTicker()
        isRunning = false
        segmentStart = nil
        accumulated = 0
        changed()
    }

    /// Recalcula el tiempo; detecta cuándo termina el temporizador.
    func refresh() {
        tick = Date()
        if mode == .countdown, isRunning, remaining() <= 0 {
            finish()
        }
    }

    private func finish() {
        accumulated = duration
        segmentStart = nil
        isRunning = false
        stopTicker()
        changed()
    }

    private func startTicker() {
        ticker = Timer.publish(every: 0.2, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.refresh() }
    }

    private func stopTicker() {
        ticker = nil
    }

    private func changed() {
        tick = Date()
        onStateChange?(self)
    }
}
