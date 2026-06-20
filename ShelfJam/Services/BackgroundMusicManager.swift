import Foundation

#if canImport(AVFoundation)
import AVFoundation
#endif

final class BackgroundMusicManager {
    static let shared = BackgroundMusicManager()

    #if canImport(AVFoundation)
    private var engine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    private var phase: Double = 0
    private var sampleIndex: Double = 0
    private let melody: [Double] = [261.63, 329.63, 392.00, 523.25, 392.00, 329.63]
    #endif

    private init() {}

    func setEnabled(_ enabled: Bool) {
        enabled ? start() : stop()
    }

    private func start() {
        #if canImport(AVFoundation)
        guard engine == nil else { return }
        let engine = AVAudioEngine()
        let sampleRate = 44_100.0
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)

        let sourceNode = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList in
            guard let self else { return noErr }
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)

            for frame in 0..<Int(frameCount) {
                let beat = Int(self.sampleIndex / (sampleRate * 0.72)) % self.melody.count
                let frequency = self.melody[beat]
                let sample = Float(sin(self.phase) * 0.035 + sin(self.phase * 0.5) * 0.012)
                self.phase += 2.0 * .pi * frequency / sampleRate
                self.sampleIndex += 1

                for buffer in buffers {
                    let pointer = buffer.mData?.assumingMemoryBound(to: Float.self)
                    pointer?[frame] = sample
                }
            }

            return noErr
        }

        engine.attach(sourceNode)
        if let format {
            engine.connect(sourceNode, to: engine.mainMixerNode, format: format)
        }
        engine.mainMixerNode.outputVolume = 0.55

        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            self.engine = engine
            self.sourceNode = sourceNode
        } catch {
            engine.stop()
            self.engine = nil
            self.sourceNode = nil
        }
        #endif
    }

    private func stop() {
        #if canImport(AVFoundation)
        engine?.stop()
        engine = nil
        sourceNode = nil
        phase = 0
        sampleIndex = 0
        #endif
    }
}
