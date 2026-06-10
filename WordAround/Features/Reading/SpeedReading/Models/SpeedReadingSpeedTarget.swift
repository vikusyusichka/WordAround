import Foundation

extension ReadingSpeedTarget {

    var wpmRange: ClosedRange<Int> {
        switch self {
        case .relaxed:   return 120...160
        case .balanced:  return 180...240
        case .fast:      return 250...320
        case .challenge: return 350...450
        }
    }

    var wordsPerChunk: Int {
        switch self {
        case .relaxed:   return 55
        case .balanced:  return 75
        case .fast:      return 95
        case .challenge: return 120
        }
    }

    var timerMultiplier: Double {
        switch self {
        case .relaxed:   return 1.25
        case .balanced:  return 1.0
        case .fast:      return 0.9
        case .challenge: return 0.8
        }
    }

    var summaryLabel: String {
        let lo = wpmRange.lowerBound
        let hi = wpmRange.upperBound
        return "\(lo)–\(hi) WPM"
    }

    func rating(forAchievedWPM achieved: Int) -> SpeedReadingRating {
        let lo = wpmRange.lowerBound
        let hi = wpmRange.upperBound
        if achieved >= hi + 40 { return .excellent }
        if achieved >= lo      { return .balanced }
        if achieved >= lo - 30 { return .fast }
        return .tooSlow
    }
}

enum SpeedReadingRating: String, Codable, CaseIterable {
    case tooSlow, balanced, fast, excellent

    var label: String {
        switch self {
        case .tooSlow:   return "Too Slow"
        case .balanced:  return "Balanced"
        case .fast:      return "Fast"
        case .excellent: return "Excellent"
        }
    }

    var systemImage: String {
        switch self {
        case .tooSlow:   return "tortoise.fill"
        case .balanced:  return "scope"
        case .fast:      return "bolt.fill"
        case .excellent: return "flame.fill"
        }
    }
}
