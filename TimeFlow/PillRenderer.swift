import CoreMedia
import UIKit

/// Lo que se dibuja en la pastilla. Solo se vuelve a dibujar cuando cambia.
struct PillSnapshot: Equatable {
    var text: String
    var mode: TimerMode
    var isRunning: Bool
    var isFinished: Bool
    var progress: Double

    init(engine: TimerEngine) {
        text = TimeFormat.string(engine.displaySeconds)
        mode = engine.mode
        isRunning = engine.isRunning
        isFinished = engine.isFinished
        progress = (engine.progress * 100).rounded() / 100
    }
}

/// Dibuja la pastilla (tiempo + aro con pausa/play) como un cuadro de video
/// para la ventanita flotante.
enum PillRenderer {
    /// Proporción 10:3, alargada como la pastilla del teléfono.
    static let pixelSize = CGSize(width: 600, height: 180)

    private static let background = UIColor(red: 0.16, green: 0.16, blue: 0.18, alpha: 1)
    private static let ringFill = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
    private static let purple = UIColor(red: 0.48, green: 0.42, blue: 1.00, alpha: 1)
    private static let green = UIColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1)
    private static let orange = UIColor(red: 1.00, green: 0.62, blue: 0.04, alpha: 1)

    static func sampleBuffer(for snapshot: PillSnapshot) -> CMSampleBuffer? {
        let width = Int(pixelSize.width)
        let height = Int(pixelSize.height)

        var pixelBufferOut: CVPixelBuffer?
        let attributes: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
            kCVPixelBufferIOSurfacePropertiesKey: [:] as [CFString: Any],
        ]
        guard CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA,
                                  attributes as CFDictionary, &pixelBufferOut) == kCVReturnSuccess,
              let pixelBuffer = pixelBufferOut else { return nil }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        if let context = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer),
                                   width: width,
                                   height: height,
                                   bitsPerComponent: 8,
                                   bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                   space: CGColorSpaceCreateDeviceRGB(),
                                   bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue) {
            // Coordenadas de UIKit (origen arriba a la izquierda).
            context.translateBy(x: 0, y: CGFloat(height))
            context.scaleBy(x: 1, y: -1)
            UIGraphicsPushContext(context)
            draw(snapshot, size: pixelSize)
            UIGraphicsPopContext()
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])

        var formatOut: CMVideoFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                     imageBuffer: pixelBuffer,
                                                     formatDescriptionOut: &formatOut)
        guard let format = formatOut else { return nil }

        var timing = CMSampleTimingInfo(duration: .invalid,
                                        presentationTimeStamp: CMClockGetTime(CMClockGetHostTimeClock()),
                                        decodeTimeStamp: .invalid)
        var sampleBufferOut: CMSampleBuffer?
        CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault,
                                                 imageBuffer: pixelBuffer,
                                                 formatDescription: format,
                                                 sampleTiming: &timing,
                                                 sampleBufferOut: &sampleBufferOut)
        guard let sampleBuffer = sampleBufferOut else { return nil }

        // Mostrar el cuadro de inmediato, sin esperar a un reloj de reproducción.
        if let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: true),
           CFArrayGetCount(attachments) > 0 {
            let dictionary = unsafeBitCast(CFArrayGetValueAtIndex(attachments, 0), to: CFMutableDictionary.self)
            let trueValue: CFBoolean = kCFBooleanTrue
            CFDictionarySetValue(dictionary,
                                 Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(),
                                 Unmanaged.passUnretained(trueValue).toOpaque())
        }
        return sampleBuffer
    }

    static func draw(_ snapshot: PillSnapshot, size: CGSize) {
        background.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))

        let accent: UIColor
        if snapshot.isFinished {
            accent = orange
        } else {
            accent = snapshot.mode == .countdown ? purple : green
        }

        // Aro a la derecha.
        let diameter = size.height * 0.70
        let ring = CGRect(x: size.width - diameter - size.height * 0.15,
                          y: (size.height - diameter) / 2,
                          width: diameter,
                          height: diameter)
        ringFill.setFill()
        UIBezierPath(ovalIn: ring).fill()

        let lineWidth = diameter * 0.075
        let track = ring.insetBy(dx: lineWidth / 2 + 2, dy: lineWidth / 2 + 2)
        let trackPath = UIBezierPath(ovalIn: track)
        trackPath.lineWidth = lineWidth
        UIColor(white: 1, alpha: 0.14).setStroke()
        trackPath.stroke()

        if snapshot.progress > 0 {
            let start = -CGFloat.pi / 2
            let arc = UIBezierPath(arcCenter: CGPoint(x: track.midX, y: track.midY),
                                   radius: track.width / 2,
                                   startAngle: start,
                                   endAngle: start + 2 * .pi * CGFloat(snapshot.progress),
                                   clockwise: true)
            arc.lineWidth = lineWidth
            arc.lineCapStyle = .round
            accent.setStroke()
            arc.stroke()
        }

        // Ícono de pausa (corriendo) o play (detenido).
        UIColor.white.setFill()
        let iconHeight = diameter * 0.30
        let center = CGPoint(x: ring.midX, y: ring.midY)
        if snapshot.isRunning {
            let barWidth = iconHeight * 0.28
            let gap = iconHeight * 0.26
            for offset in [-(gap / 2 + barWidth), gap / 2] {
                let bar = CGRect(x: center.x + offset, y: center.y - iconHeight / 2, width: barWidth, height: iconHeight)
                UIBezierPath(roundedRect: bar, cornerRadius: barWidth * 0.3).fill()
            }
        } else {
            let triangle = UIBezierPath()
            let w = iconHeight * 0.9
            triangle.move(to: CGPoint(x: center.x - w * 0.38, y: center.y - iconHeight / 2))
            triangle.addLine(to: CGPoint(x: center.x + w * 0.62, y: center.y))
            triangle.addLine(to: CGPoint(x: center.x - w * 0.38, y: center.y + iconHeight / 2))
            triangle.close()
            triangle.fill()
        }

        // Tiempo, centrado en el espacio a la izquierda del aro.
        let fontSize = size.height * (snapshot.text.count > 5 ? 0.42 : 0.52)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .semibold),
            .foregroundColor: snapshot.isFinished ? accent : UIColor.white,
        ]
        let text = snapshot.text as NSString
        let textSize = text.size(withAttributes: attributes)
        let textAreaWidth = ring.minX
        text.draw(at: CGPoint(x: (textAreaWidth - textSize.width) / 2 + size.height * 0.05,
                              y: (size.height - textSize.height) / 2),
                  withAttributes: attributes)
    }
}
