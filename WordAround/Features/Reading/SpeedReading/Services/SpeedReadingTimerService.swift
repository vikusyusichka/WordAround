import Foundation
import Combine

@MainActor
final class SpeedReadingTimerService {

    private var cancellable: AnyCancellable?
    private var lastTickAt: Date?
    private var isRunning: Bool { cancellable != nil }

    func start(onTick: @escaping @MainActor (Int) -> Void) {
        guard !isRunning else { return }
        if lastTickAt == nil { lastTickAt = Date() }
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.lastTickAt = Date()
                onTick(1)
            }
    }

    func stop() {
        cancellable?.cancel()
        cancellable = nil
    }

    func reset() {
        stop()
        lastTickAt = nil
    }
}

enum SpeedReadingTimerFormat {

    static func mmss(_ seconds: Int) -> String {
        let clamped = max(0, seconds)
        let minutes = clamped / 60
        let secs = clamped % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}
