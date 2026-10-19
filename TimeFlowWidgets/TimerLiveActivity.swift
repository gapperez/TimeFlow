import ActivityKit
import SwiftUI
import WidgetKit

struct TimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            LockScreenTimerView(state: context.state)
                .activityBackgroundTint(Color.black.opacity(0.75))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.state.mode.title, systemImage: context.state.mode.symbol)
                        .font(.caption)
                        .foregroundStyle(context.state.mode.tint)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TimerText(state: context.state)
                        .font(.title2.monospacedDigit())
                        .multilineTextAlignment(.trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    TimerProgress(state: context.state)
                }
            } compactLeading: {
                Image(systemName: context.state.mode.symbol)
                    .foregroundStyle(context.state.mode.tint)
            } compactTrailing: {
                TimerText(state: context.state)
                    .monospacedDigit()
                    .frame(width: 56)
            } minimal: {
                Image(systemName: context.state.mode.symbol)
                    .foregroundStyle(context.state.mode.tint)
            }
        }
    }
}

/// Tarjeta de la pantalla de bloqueo.
struct LockScreenTimerView: View {
    let state: TimerActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: state.mode.symbol)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(state.mode.tint, in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text("TimeFlow · \(state.mode.title)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TimerText(state: state)
                    .font(.system(size: 30, weight: .semibold).monospacedDigit())
                    .foregroundStyle(.white)
                TimerProgress(state: state)
            }

            Spacer(minLength: 0)

            Image(systemName: state.isRunning ? "pause.fill" : "play.fill")
                .font(.body)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.15), in: Circle())
        }
        .padding(16)
    }
}

/// El sistema actualiza el tiempo solo, sin que la app tenga que estar abierta.
struct TimerText: View {
    let state: TimerActivityAttributes.ContentState

    var body: some View {
        if state.isRunning {
            switch state.mode {
            case .countdown:
                Text(timerInterval: state.referenceDate.addingTimeInterval(-state.duration)...state.referenceDate,
                     countsDown: true)
            case .stopwatch:
                Text(timerInterval: state.referenceDate...Date.distantFuture, countsDown: false)
            }
        } else {
            Text(TimeFormat.string(Int(state.pausedSeconds)))
        }
    }
}

/// Barra de lo que queda del temporizador (el cronómetro no la muestra).
struct TimerProgress: View {
    let state: TimerActivityAttributes.ContentState

    var body: some View {
        if state.mode == .countdown {
            Group {
                if state.isRunning {
                    ProgressView(timerInterval: state.referenceDate.addingTimeInterval(-state.duration)...state.referenceDate,
                                 countsDown: true) {
                        EmptyView()
                    } currentValueLabel: {
                        EmptyView()
                    }
                } else {
                    ProgressView(value: state.duration > 0 ? state.pausedSeconds / state.duration : 0)
                }
            }
            .progressViewStyle(.linear)
            .tint(state.mode.tint)
        }
    }
}
