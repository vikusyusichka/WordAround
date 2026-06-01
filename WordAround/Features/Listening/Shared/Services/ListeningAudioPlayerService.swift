import Foundation
import AVFoundation

/// `AVAudioPlayer`-backed playback for imported audio. Emits progress on a timer
/// and a finish callback when playback reaches the end.
@MainActor
final class AVFoundationAudioPlayerService: NSObject, ListeningAudioPlaying {

    var onProgress: ((TimeInterval, TimeInterval) -> Void)?
    var onFinish: (() -> Void)?

    private var player: AVAudioPlayer?
    private var displayTimer: Timer?

    var duration: TimeInterval { player?.duration ?? 0 }
    var currentTime: TimeInterval { player?.currentTime ?? 0 }
    var isPlaying: Bool { player?.isPlaying ?? false }

    func load(url: URL) throws {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.duckOthers])
        try? session.setActive(true, options: [])

        let player = try AVAudioPlayer(contentsOf: url)
        player.delegate = self
        player.enableRate = true
        player.prepareToPlay()
        self.player = player
        onProgress?(0, player.duration)
    }

    func play() {
        guard let player else { return }
        player.play()
        startTimer()
    }

    func pause() {
        player?.pause()
        stopTimer()
    }

    func seek(to time: TimeInterval) {
        guard let player else { return }
        player.currentTime = min(max(0, time), player.duration)
        onProgress?(player.currentTime, player.duration)
    }

    func setRate(_ rate: Float) {
        player?.rate = rate
    }

    func stop() {
        player?.stop()
        stopTimer()
        player = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func startTimer() {
        stopTimer()
        let timer = Timer(timeInterval: 0.2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, let player = self.player else { return }
                self.onProgress?(player.currentTime, player.duration)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        displayTimer = timer
    }

    private func stopTimer() {
        displayTimer?.invalidate()
        displayTimer = nil
    }
}

extension AVFoundationAudioPlayerService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.stopTimer()
            self.onProgress?(self.duration, self.duration)
            self.onFinish?()
        }
    }
}
