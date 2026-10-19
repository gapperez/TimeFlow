import AVKit
import Combine
import SwiftUI
import UIKit

/// Muestra la pastilla en una ventanita flotante (Picture in Picture).
/// iPadOS solo permite ventanitas flotantes de video, así que la pastilla se
/// dibuja como cuadros de video en un AVSampleBufferDisplayLayer.
final class PiPController: NSObject, ObservableObject {
    @Published private(set) var isActive = false
    @Published private(set) var isPossible = false

    let displayLayer = AVSampleBufferDisplayLayer()

    private let engine: TimerEngine
    private var controller: AVPictureInPictureController?
    private var possibleObservation: NSKeyValueObservation?
    private var renderTimer: Timer?
    private var lastSnapshot: PillSnapshot?

    init(engine: TimerEngine) {
        self.engine = engine
        super.init()
        displayLayer.videoGravity = .resizeAspect
        configureAudioSession()
        renderIfNeeded()
        configurePictureInPicture()

        let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.renderIfNeeded()
        }
        RunLoop.main.add(timer, forMode: .common)
        renderTimer = timer
    }

    func toggle() {
        guard let controller else { return }
        if controller.isPictureInPictureActive {
            controller.stopPictureInPicture()
        } else {
            controller.startPictureInPicture()
        }
    }

    /// La ventanita flotante necesita una sesión de audio de reproducción.
    /// Se mezcla con otros audios para no cortar tu música.
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    private func configurePictureInPicture() {
        guard AVPictureInPictureController.isPictureInPictureSupported() else { return }
        let source = AVPictureInPictureController.ContentSource(sampleBufferDisplayLayer: displayLayer,
                                                                playbackDelegate: self)
        let controller = AVPictureInPictureController(contentSource: source)
        controller.delegate = self
        controller.requiresLinearPlayback = true
        // Si sales de la app con el tiempo corriendo, la ventanita se abre sola.
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        possibleObservation = controller.observe(\.isPictureInPicturePossible, options: [.initial, .new]) { [weak self] controller, _ in
            DispatchQueue.main.async {
                self?.isPossible = controller.isPictureInPicturePossible
            }
        }
        self.controller = controller
    }

    private func renderIfNeeded() {
        if displayLayer.status == .failed || displayLayer.requiresFlushToResumeDecoding {
            displayLayer.flush()
            lastSnapshot = nil
        }

        let snapshot = PillSnapshot(engine: engine)
        guard snapshot != lastSnapshot else { return }
        let runningChanged = snapshot.isRunning != lastSnapshot?.isRunning
        lastSnapshot = snapshot

        if let sampleBuffer = PillRenderer.sampleBuffer(for: snapshot) {
            displayLayer.enqueue(sampleBuffer)
        }
        if runningChanged {
            // Actualiza el botón de pausa/play de la ventanita.
            controller?.invalidatePlaybackState()
        }
    }
}

extension PiPController: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        isActive = true
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        isActive = false
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController,
                                    failedToStartPictureInPictureWithError error: Error) {
        isActive = false
    }
}

extension PiPController: AVPictureInPictureSampleBufferPlaybackDelegate {
    /// El botón de pausa/play de la ventanita pausa o reanuda el tiempo.
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, setPlaying playing: Bool) {
        DispatchQueue.main.async {
            if playing {
                self.engine.start()
            } else {
                self.engine.pause()
            }
            self.renderIfNeeded()
        }
    }

    /// Rango infinito: la ventanita lo trata como transmisión en vivo y no muestra barra de avance.
    func pictureInPictureControllerTimeRangeForPlayback(_ pictureInPictureController: AVPictureInPictureController) -> CMTimeRange {
        CMTimeRange(start: .negativeInfinity, duration: .positiveInfinity)
    }

    func pictureInPictureControllerIsPlaybackPaused(_ pictureInPictureController: AVPictureInPictureController) -> Bool {
        !engine.isRunning
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController,
                                    didTransitionToRenderSize newRenderSize: CMVideoDimensions) {}

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController,
                                    skipByInterval skipInterval: CMTime,
                                    completion completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}

/// Muestra en la app la misma capa que usa la ventanita flotante.
/// Tiene que estar en pantalla para que la ventanita se pueda abrir.
struct PiPSourceView: UIViewRepresentable {
    let displayLayer: AVSampleBufferDisplayLayer

    func makeUIView(context: Context) -> LayerHostView {
        let view = LayerHostView()
        view.hostedLayer = displayLayer
        return view
    }

    func updateUIView(_ uiView: LayerHostView, context: Context) {}

    final class LayerHostView: UIView {
        var hostedLayer: CALayer? {
            didSet {
                oldValue?.removeFromSuperlayer()
                if let hostedLayer {
                    layer.addSublayer(hostedLayer)
                }
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            hostedLayer?.frame = bounds
            CATransaction.commit()
        }
    }
}
