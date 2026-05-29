import SwiftUI

/// Centralised pink/magenta palette for Debate Mode so no view hardcodes the
/// same RGB triples. Matches the `debate-mode` accent in `SpeakingMode`.
enum DebateTheme {
    static let accent = Color(red: 0.93, green: 0.40, blue: 0.60)
    static let accentDark = Color(red: 0.62, green: 0.18, blue: 0.42)
    static let soft = AppColors.blobPink
}
