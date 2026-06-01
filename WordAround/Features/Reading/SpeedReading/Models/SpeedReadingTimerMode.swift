import Foundation

extension ReadingTimerStyle {

    var enforcesPace: Bool {
        switch self {
        case .noTimer:        return false
        case .soft, .strict:  return true
        }
    }

    var locksChunkOnExpire: Bool {
        self == .strict
    }

    var penalisesViolations: Bool {
        self == .strict
    }

    var perChunkMultiplier: Double {
        switch self {
        case .noTimer: return 0
        case .soft:    return 1.4
        case .strict:  return 1.0
        }
    }

    var paceHelperText: String {
        switch self {
        case .noTimer: return "Read at your own pace."
        case .soft:    return "Recommended pace — keep moving."
        case .strict:  return "Strict pacing — the chunk advances when the timer ends."
        }
    }
}
