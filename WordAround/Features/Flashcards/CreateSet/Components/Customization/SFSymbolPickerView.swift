import SwiftUI

struct SFSymbolPickerView: View {
    @Binding var selectedSymbol: String
    let theme: CreateSetTheme

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: Layout.symbolPickerGridItemSpacing),
            count: Layout.symbolPickerGridColumns
        )
    }

    private var filteredSymbols: [String] {
        guard !searchText.isEmpty else {
            return SFSymbolCatalog.allSymbols
        }

        return SFSymbolCatalog.allSymbols.filter {
            $0.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Layout.symbolPickerContentSpacing) {
                topBar

                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: Layout.symbolPickerGridSpacing) {
                        ForEach(Array(filteredSymbols.prefix(120)), id: \.self) { symbol in
                            symbolButton(symbol)
                        }
                    }
                    .padding(.bottom, Layout.symbolPickerBottomPadding)
                }
            }
            .padding(.horizontal, Layout.symbolPickerHorizontalPadding)
            .padding(.top, Layout.symbolPickerTopPadding)
            .background(theme.screenBackground.ignoresSafeArea())
        }
        .preferredColorScheme(.light)
    }

    private var topBar: some View {
        HStack(alignment: .center, spacing: Layout.symbolPickerTopBarSpacing) {
            closeButton

            Text("Choose icon")
                .font(.system(
                    size: Layout.symbolPickerTitleSize,
                    weight: .bold,
                    design: .rounded
                ))
                .foregroundStyle(theme.titleColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .center)

            searchBar
                .frame(width: Layout.symbolPickerSearchWidth)
        }
        .frame(height: Layout.symbolPickerTopBarHeight)
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: Layout.symbolPickerCloseIconSize, weight: .bold))
                .foregroundStyle(theme.accent)
                .frame(
                    width: Layout.symbolPickerCloseButtonSize,
                    height: Layout.symbolPickerCloseButtonSize
                )
                .background {
                    Circle()
                        .fill(theme.softAccent.opacity(0.72))
                        .overlay {
                            Circle()
                                .stroke(theme.accent.opacity(0.14), lineWidth: 1)
                        }
                }
        }
        .buttonStyle(.plain)
    }

    private var searchBar: some View {
        HStack(spacing: Layout.symbolPickerSearchIconSpacing) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: Layout.symbolPickerSearchIconSize, weight: .semibold))
                .foregroundStyle(theme.accent)

            TextField("Search symbol", text: $searchText)
                .font(.system(
                    size: Layout.symbolPickerSearchTextSize,
                    weight: .regular,
                    design: .rounded
                ))
                .foregroundStyle(theme.titleColor)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .tint(theme.accent)
                .lineLimit(1)
        }
        .padding(.horizontal, Layout.symbolPickerSearchHorizontalPadding)
        .frame(height: Layout.symbolPickerSearchHeight)
        .background {
            Capsule()
                .fill(theme.softAccent.opacity(0.48))
        }
    }

    private func symbolButton(_ symbol: String) -> some View {
        let isSelected = selectedSymbol == symbol

        return Button {
            selectedSymbol = symbol
            dismiss()
        } label: {
            ZStack {
                Circle()
                    .fill(isSelected ? theme.softAccent : theme.softAccent.opacity(0.55))
                    .frame(
                        width: Layout.symbolPickerCircleSize,
                        height: Layout.symbolPickerCircleSize
                    )
                    .overlay {
                        Circle()
                            .stroke(
                                isSelected ? theme.accent.opacity(0.22) : Color.clear,
                                lineWidth: 1
                            )
                    }

                Image(systemName: symbol)
                    .font(.system(
                        size: Layout.symbolPickerIconSize,
                        weight: .bold,
                        design: .rounded
                    ))
                    .foregroundStyle(theme.accent)
            }
            .scaleEffect(isSelected ? 1.06 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

#Preview("iPad") {
    SFSymbolPickerView(
        selectedSymbol: .constant("train.side.front.car"),
        theme: .blue
    )
    .frame(width: 900, height: 600)
}

#Preview("iPhone") {
    SFSymbolPickerView(
        selectedSymbol: .constant("train.side.front.car"),
        theme: .green
    )
    .frame(width: 390, height: 700)
}
