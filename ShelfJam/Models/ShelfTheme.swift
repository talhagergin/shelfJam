import SwiftUI

enum ShelfTheme: String, Codable, CaseIterable, Identifiable {
    case kitchen
    case playroom
    case library
    case greenhouse

    var id: String { rawValue }

    var title: String {
        switch self {
        case .kitchen: "Kitchen"
        case .playroom: "Playroom"
        case .library: "Library"
        case .greenhouse: "Greenhouse"
        }
    }

    var accent: Color {
        switch self {
        case .kitchen: .orange
        case .playroom: .pink
        case .library: .indigo
        case .greenhouse: .green
        }
    }
}
