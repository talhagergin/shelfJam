import SwiftUI

enum ShelfItemType: String, CaseIterable, Codable, Hashable, Identifiable {
    case apple
    case teddy
    case car
    case book
    case cup
    case plant
    case ball
    case gift

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .apple: "Apple"
        case .teddy: "Teddy"
        case .car: "Car"
        case .book: "Book"
        case .cup: "Cup"
        case .plant: "Plant"
        case .ball: "Ball"
        case .gift: "Gift"
        }
    }

    var icon: String {
        switch self {
        case .apple: "🍎"
        case .teddy: "🧸"
        case .car: "🚗"
        case .book: "📚"
        case .cup: "☕️"
        case .plant: "🪴"
        case .ball: "⚽️"
        case .gift: "🎁"
        }
    }

    var color: Color {
        switch self {
        case .apple: .red
        case .teddy: .brown
        case .car: .blue
        case .book: .purple
        case .cup: .orange
        case .plant: .green
        case .ball: .mint
        case .gift: .pink
        }
    }
}
