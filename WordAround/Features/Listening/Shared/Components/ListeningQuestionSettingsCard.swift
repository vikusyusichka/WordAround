import SwiftUI

struct ListeningQuestionSettingsCard: View {
    @Binding var addQuestions: Bool
    @Binding var questionCount: Int
    @Binding var selectedTypes: Set<ListeningQuestionType>
    var accent: Color = ListeningTheme.accent
    var accentDark: Color = ListeningTheme.accentDark

    private let countOptions = [3, 5, 8]

    var body: some View {
        ListeningWhiteCard {
            VStack(alignment: .leading, spacing: 16) {
                ListeningToggleRow(
                    title: L10n.string("listenAddQuestions"),
                    isOn: $addQuestions,
                    accent: accent,
                    accentDark: accentDark
                )

                if addQuestions {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(L10n.string("listenQuestionCount"))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)

                        HStack(spacing: Layout.convSetupGridSpacing) {
                            ForEach(countOptions, id: \.self) { count in
                                countPill(count)
                            }
                        }

                        Text(L10n.string("listenQuestionTypes"))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.top, 4)

                        ListeningChipFlowLayout(spacing: 8) {
                            ForEach(ListeningQuestionType.allCases) { type in
                                typeChip(type)
                            }
                        }
                    }
                }
            }
        }
    }

    private func countPill(_ count: Int) -> some View {
        let isSelected = questionCount == count
        return Button {
            withAnimation(.easeInOut(duration: 0.16)) { questionCount = count }
        } label: {
            Text("\(count)")
                .font(.system(size: Layout.convSetupDurationChipTextSize, weight: .bold, design: .rounded))
                .foregroundColor(isSelected ? .white : accentDark)
                .frame(maxWidth: .infinity)
                .frame(height: Layout.convSetupDurationChipHeight)
                .background(isSelected ? accent : accent.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                        .stroke(isSelected ? Color.clear : accent.opacity(0.22), lineWidth: 1)
                )
        }
        .buttonStyle(ListeningSetupPressStyle())
    }

    private func typeChip(_ type: ListeningQuestionType) -> some View {
        let isSelected = selectedTypes.contains(type)
        return Button {
            withAnimation(.easeInOut(duration: 0.16)) {
                if isSelected {
                    selectedTypes.remove(type)
                } else {
                    selectedTypes.insert(type)
                }
            }
        } label: {
            Text(type.title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(isSelected ? .white : accentDark)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? accent : accent.opacity(0.10))
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? Color.clear : accent.opacity(0.22), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct ListeningChipFlowLayout: SwiftUI.Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint], sizes: [CGSize]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            sizes.append(size)
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions, sizes)
    }
}
