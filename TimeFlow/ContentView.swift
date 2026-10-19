import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var engine: TimerEngine
    @EnvironmentObject private var pip: PiPController
    @Environment(\.scenePhase) private var scenePhase

    @State private var hours = 0
    @State private var minutes = 30
    @State private var seconds = 0

    private let presets = [1, 5, 10, 15, 30, 60]

    var body: some View {
        VStack(spacing: 32) {
            Picker("Modo", selection: Binding(get: { engine.mode }, set: { engine.setMode($0) })) {
                ForEach(TimerMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 380)

            if engine.mode == .countdown && !engine.hasStarted {
                durationPicker
            } else {
                Text(TimeFormat.string(engine.displaySeconds))
                    .font(.system(size: 120, weight: .thin))
                    .monospacedDigit()
                    .foregroundStyle(engine.isFinished ? Color.orange : Color.white)
                    .frame(height: 200)
            }

            controls

            pillPreview
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .onAppear(perform: loadDuration)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                engine.refresh()
            }
        }
    }

    // MARK: - Duración del temporizador

    private var durationPicker: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                wheel("h", range: 0..<24, selection: $hours)
                wheel("min", range: 0..<60, selection: $minutes)
                wheel("s", range: 0..<60, selection: $seconds)
            }
            .frame(height: 160)

            HStack(spacing: 10) {
                ForEach(presets, id: \.self) { preset in
                    Button(preset == 60 ? "1 h" : "\(preset) min") {
                        hours = preset / 60
                        minutes = preset % 60
                        seconds = 0
                    }
                    .buttonStyle(.bordered)
                    .tint(TimerMode.countdown.tint)
                }
            }
        }
        .frame(height: 200)
        .onChange(of: hours) { saveDuration() }
        .onChange(of: minutes) { saveDuration() }
        .onChange(of: seconds) { saveDuration() }
    }

    private func wheel(_ unit: String, range: Range<Int>, selection: Binding<Int>) -> some View {
        HStack(spacing: 4) {
            Picker(unit, selection: selection) {
                ForEach(range, id: \.self) { value in
                    Text("\(value)").tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 80)
            .clipped()

            Text(unit)
                .foregroundStyle(.secondary)
        }
    }

    private func loadDuration() {
        let total = Int(engine.duration)
        hours = total / 3600
        minutes = (total % 3600) / 60
        seconds = total % 60
    }

    private func saveDuration() {
        engine.duration = TimeInterval(hours * 3600 + minutes * 60 + seconds)
    }

    // MARK: - Botones

    private var primaryTitle: String {
        if engine.isRunning { return "Pausar" }
        if engine.hasStarted && !engine.isFinished { return "Reanudar" }
        return "Iniciar"
    }

    private var controls: some View {
        HStack(spacing: 20) {
            Button("Reiniciar") { engine.reset() }
                .buttonStyle(PillButtonStyle(color: Color(white: 0.25)))
                .disabled(!engine.hasStarted)

            Button(primaryTitle) { engine.toggle() }
                .buttonStyle(PillButtonStyle(color: engine.isRunning ? .orange : .green))
                .disabled(engine.mode == .countdown && engine.duration == 0)

            Button {
                pip.toggle()
            } label: {
                Label(pip.isActive ? "Cerrar ventanita" : "Ventanita flotante", systemImage: "pip")
            }
            .buttonStyle(PillButtonStyle(color: TimerMode.countdown.tint))
            .disabled(!pip.isPossible && !pip.isActive)
        }
    }

    // MARK: - Vista previa de la pastilla

    private var pillPreview: some View {
        VStack(spacing: 10) {
            PiPSourceView(displayLayer: pip.displayLayer)
                .aspectRatio(PillRenderer.pixelSize.width / PillRenderer.pixelSize.height, contentMode: .fit)
                .frame(width: 240)
                .clipShape(Capsule())

            Text("Así se ve la ventanita. Si sales de la app con el tiempo corriendo, se abre sola.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct PillButtonStyle: ButtonStyle {
    var color: Color
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 26)
            .padding(.vertical, 14)
            .background(color.opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.35), in: Capsule())
    }
}
