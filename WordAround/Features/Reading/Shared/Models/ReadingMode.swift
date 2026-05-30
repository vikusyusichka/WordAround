import SwiftUI

/// A single Reading practice mode shown on the Reading home menu.
///
/// This is a pure presentation model. The list of modes shown on the home
/// screen is mock/placeholder data and lives in `ReadingHomeViewModel` — not
/// here and not in the views.
struct ReadingMode: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let accentColor: Color
    let blobColor: Color
    /// When `true`, the mode is rendered as a non-interactive "coming soon"
    /// card (its session is not implemented yet).
    var isComingSoon: Bool = false
}
