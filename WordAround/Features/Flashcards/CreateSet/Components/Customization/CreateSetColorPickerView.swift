import SwiftUI

struct CreateSetColorPickerView: View {
    let theme: CreateSetTheme
    let colors: [SetColor]
    let selectedColor: SetColor
    let onSelectColor: (SetColor) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.createSetColorPickerSpacing) {
            CreateSetSectionLabel(text: "Choose color", theme: theme)

            HStack {
                ForEach(colors) { setColor in
                    colorButton(setColor)

                    if setColor != colors.last {
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, Layout.createSetColorPickerHorizontalPadding)
        }
    }

    private func colorButton(_ setColor: SetColor) -> some View {
        Button {
            onSelectColor(setColor)
        } label: {
            Circle()
                .fill(setColor.color.opacity(0.75))
                .frame(
                    width: Layout.createSetColorCircleSize,
                    height: Layout.createSetColorCircleSize
                )
                .overlay {
                    if selectedColor == setColor {
                        Circle()
                            .stroke(Color.white, lineWidth: Layout.createSetSelectedColorStrokeWidth)

                        Circle()
                            .stroke(setColor.color, lineWidth: 2)
                            .frame(
                                width: Layout.createSetSelectedColorOuterCircleSize,
                                height: Layout.createSetSelectedColorOuterCircleSize
                            )
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CreateSetColorPickerView(
        theme: .blue,
        colors: SetColor.allCases,
        selectedColor: .blue,
        onSelectColor: { _ in }
    )
    .padding()
    .background(CreateSetTheme.blue.screenBackground)
}
