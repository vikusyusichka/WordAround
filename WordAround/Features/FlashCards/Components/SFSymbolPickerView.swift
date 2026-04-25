import SwiftUI

struct SFSymbolPickerView: View {
    @Binding var selectedSymbol: String

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 14),
        count: 5
    )

    private let symbols: [String: [String]] = [
        "Learning": [
            "book.fill", "book.closed.fill", "books.vertical.fill",
            "graduationcap.fill", "brain.head.profile",
            "pencil", "pencil.and.outline", "square.and.pencil",
            "text.book.closed.fill", "doc.text.fill",
            "note.text", "clipboard.fill"
        ],

        "Languages": [
            "globe", "globe.europe.africa.fill", "globe.americas.fill",
            "character.bubble.fill", "text.bubble.fill",
            "quote.bubble.fill", "bubble.left.and.bubble.right.fill",
            "translate", "mic.fill", "speaker.wave.2.fill"
        ],

        "Nature": [
            "leaf.fill", "tree.fill", "sun.max.fill",
            "moon.fill", "cloud.fill", "cloud.rain.fill",
            "flame.fill", "drop.fill", "snowflake"
        ],

        "Health": [
            "heart.fill", "cross.case.fill", "stethoscope",
            "bandage.fill", "pills.fill", "bed.double.fill",
            "figure.walk", "figure.run", "figure.cooldown"
        ],

        "Food": [
            "fork.knife", "cup.and.saucer.fill",
            "wineglass.fill", "takeoutbag.and.cup.and.straw.fill",
            "birthday.cake.fill", "carrot.fill"
        ],

        "Tech": [
            "laptopcomputer", "desktopcomputer", "ipad",
            "iphone", "apple.logo", "keyboard.fill",
            "cpu.fill", "server.rack", "wifi", "antenna.radiowaves.left.and.right"
        ],

        "Travel": [
            "airplane", "car.fill", "bus.fill",
            "tram.fill", "bicycle", "map.fill",
            "location.fill", "suitcase.fill"
        ],

        "Work": [
            "briefcase.fill", "calendar", "calendar.badge.clock",
            "clock.fill", "checkmark.seal.fill",
            "chart.bar.fill", "chart.pie.fill"
        ],

        "Creativity": [
            "paintbrush.fill", "paintpalette.fill",
            "scissors", "camera.fill",
            "video.fill", "music.note",
            "guitars.fill", "headphones"
        ],

        "General": [
            "star.fill", "sparkles", "bolt.fill",
            "trophy.fill", "flag.fill", "bell.fill",
            "tag.fill", "folder.fill", "paperplane.fill",
            "bookmark.fill", "link", "gearshape.fill"
        ]
    ]

    private var filteredSymbols: [String] {
        let allSymbols = symbols.values.flatMap { $0 }

        guard !searchText.isEmpty else {
            return allSymbols
        }

        return allSymbols.filter {
            $0.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Array(filteredSymbols.prefix(80)), id: \.self) { symbol in
                        symbolButton(symbol)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
            .background(Color(red: 0.965, green: 0.955, blue: 0.935))
            .searchable(text: $searchText, prompt: "Search symbol")
            .navigationTitle("Choose icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func symbolButton(_ symbol: String) -> some View {
        Button {
            selectedSymbol = symbol
            dismiss()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        selectedSymbol == symbol
                        ? Color.blue.opacity(0.16)
                        : Color.white.opacity(0.78)
                    )
                    .frame(width: 58, height: 58)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                selectedSymbol == symbol
                                ? Color.blue.opacity(0.35)
                                : Color.black.opacity(0.05),
                                lineWidth: 1
                            )
                    }

                Image(systemName: symbol)
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(selectedSymbol == symbol ? Color.blue : Color.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SFSymbolPickerView(selectedSymbol: .constant("book.fill"))
}
