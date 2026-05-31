import SwiftUI
import UIKit

struct ReadingTappableTextView: UIViewRepresentable {
    let content: String
    let selectedWordRange: NSRange?
    let accent: UIColor
    let baseTextColor: UIColor
    let onWordTap: (String, NSRange) -> Void

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.delegate = context.coordinator
        textView.isUserInteractionEnabled = true
        textView.dataDetectorTypes = []
        textView.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        textView.adjustsFontForContentSizeCategory = true

        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        textView.setContentHuggingPriority(.required, for: .vertical)

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        textView.addGestureRecognizer(tap)
        context.coordinator.textView = textView

        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.onWordTap = onWordTap

        let base = ReadingTextHighlightService.plainNSAttributedString(
            for: content,
            baseColor: Color(baseTextColor)
        )
        textView.attributedText = ReadingTextHighlightService.applyingSelectionHighlight(
            to: base,
            range: selectedWordRange,
            highlightColor: accent
        )
        textView.invalidateIntrinsicContentSize()
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        guard let width = proposal.width, width > 0, width.isFinite else { return nil }
        let height = uiView.sizeThatFits(
            CGSize(width: width, height: .greatestFiniteMagnitude)
        ).height
        return CGSize(width: width, height: max(ceil(height), 1))
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, UITextViewDelegate {
        var textView: UITextView?
        var onWordTap: ((String, NSRange) -> Void)?

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let textView = gesture.view as? UITextView, let text = textView.text else { return }
            let location = gesture.location(in: textView)

            guard let position = textView.closestPosition(to: location) else { return }
            let index = textView.offset(from: textView.beginningOfDocument, to: position)

            let nsText = text as NSString
            guard index >= 0, index < nsText.length else { return }
            guard let range = ReadingTextHighlightService.wordRange(at: index, in: text) else { return }

            let word = nsText.substring(with: range)
                .trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            guard word.count >= 2 else { return }

            onWordTap?(word, range)
        }
    }
}
