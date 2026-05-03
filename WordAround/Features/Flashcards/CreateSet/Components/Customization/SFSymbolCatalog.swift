import Foundation

enum SFSymbolCatalog {
    static let sections: [String: [String]] = [
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

    static var allSymbols: [String] {
        sections.values.flatMap { $0 }
    }
}
