import SwiftUI

enum ShelfTheme: String, Codable, CaseIterable, Identifiable {
    case kitchen
    case playroom
    case library
    case greenhouse
    case bathroom
    case vanity
    case garage
    case camping
    case office
    case bedroom
    case gaming

    var id: String { rawValue }

    var title: String {
        switch self {
        case .kitchen: "Kitchen"
        case .playroom: "Playroom"
        case .library: "Library"
        case .greenhouse: "Greenhouse"
        case .bathroom: "Bathroom Cabinet"
        case .vanity: "Vanity Table"
        case .garage: "Garage Shelf"
        case .camping: "Camp Bag"
        case .office: "Office Desk"
        case .bedroom: "Bedroom Shelf"
        case .gaming: "Gaming Setup"
        }
    }

    var accent: Color {
        switch self {
        case .kitchen: .orange
        case .playroom: .pink
        case .library: .indigo
        case .greenhouse: .green
        case .bathroom: .cyan
        case .vanity: .purple
        case .garage: .gray
        case .camping: .mint
        case .office: .blue
        case .bedroom: .pink
        case .gaming: .purple
        }
    }

    var itemTypes: [ShelfItemType] {
        switch self {
        case .kitchen: [.apple, .cheese, .bread, .milk, .honey, .cup]
        case .playroom: [.teddy, .car, .dice, .ball, .puzzle, .rocket]
        case .library: [.book, .notebook, .pen, .paperclip, .lamp, .gift]
        case .greenhouse: [.plant, .apple, .cup, .honey, .sponge, .book]
        case .bathroom: [.soap, .towel, .shampoo, .sponge, .cup, .plant]
        case .vanity: [.perfume, .lipstick, .mirror, .comb, .gift, .cup]
        case .garage: [.wrench, .tire, .helmet, .fuel, .car, .paperclip]
        case .camping: [.compass, .flashlight, .boot, .marshmallow, .cup, .plant]
        case .office: [.paperclip, .pen, .notebook, .lamp, .cup, .book]
        case .bedroom: [.pillow, .alarmClock, .slipper, .book, .plant, .cup]
        case .gaming: [.gamepad, .headphones, .console, .dice, .puzzle, .rocket]
        }
    }

    var shelfSymbol: String {
        switch self {
        case .kitchen: "fork.knife"
        case .playroom: "gamecontroller.fill"
        case .library: "books.vertical.fill"
        case .greenhouse: "leaf.fill"
        case .bathroom: "drop.fill"
        case .vanity: "sparkles"
        case .garage: "wrench.and.screwdriver.fill"
        case .camping: "tent.fill"
        case .office: "paperclip"
        case .bedroom: "bed.double.fill"
        case .gaming: "gamecontroller.fill"
        }
    }

    var shelfGradient: [Color] {
        switch self {
        case .kitchen:
            [Color(red: 1.00, green: 0.78, blue: 0.42), Color(red: 0.92, green: 0.44, blue: 0.25), Color(red: 0.38, green: 0.72, blue: 0.78)]
        case .playroom:
            [Color(red: 1.00, green: 0.65, blue: 0.76), Color(red: 0.54, green: 0.45, blue: 0.96), Color(red: 0.28, green: 0.83, blue: 0.78)]
        case .library:
            [Color(red: 0.46, green: 0.34, blue: 0.74), Color(red: 0.29, green: 0.18, blue: 0.42), Color(red: 0.87, green: 0.62, blue: 0.36)]
        case .greenhouse:
            [Color(red: 0.61, green: 0.88, blue: 0.47), Color(red: 0.18, green: 0.56, blue: 0.42), Color(red: 0.80, green: 0.71, blue: 0.45)]
        case .bathroom:
            [Color(red: 0.55, green: 0.88, blue: 0.96), Color(red: 0.22, green: 0.58, blue: 0.78), Color(red: 0.87, green: 0.94, blue: 1.00)]
        case .vanity:
            [Color(red: 0.96, green: 0.55, blue: 0.82), Color(red: 0.62, green: 0.36, blue: 0.90), Color(red: 1.00, green: 0.78, blue: 0.54)]
        case .garage:
            [Color(red: 0.36, green: 0.39, blue: 0.44), Color(red: 0.16, green: 0.18, blue: 0.22), Color(red: 0.95, green: 0.55, blue: 0.28)]
        case .camping:
            [Color(red: 0.32, green: 0.66, blue: 0.50), Color(red: 0.16, green: 0.36, blue: 0.34), Color(red: 0.96, green: 0.67, blue: 0.34)]
        case .office:
            [Color(red: 0.40, green: 0.55, blue: 0.86), Color(red: 0.21, green: 0.27, blue: 0.44), Color(red: 0.78, green: 0.87, blue: 0.95)]
        case .bedroom:
            [Color(red: 1.00, green: 0.66, blue: 0.78), Color(red: 0.67, green: 0.42, blue: 0.96), Color(red: 1.00, green: 0.84, blue: 0.48)]
        case .gaming:
            [Color(red: 0.78, green: 0.34, blue: 1.00), Color(red: 0.22, green: 0.13, blue: 0.42), Color(red: 0.15, green: 0.85, blue: 1.00)]
        }
    }

    var roomGradient: [Color] {
        switch self {
        case .kitchen:
            [Color(red: 0.98, green: 0.66, blue: 0.36), Color(red: 0.72, green: 0.30, blue: 0.22), Color(red: 0.15, green: 0.22, blue: 0.28)]
        case .playroom:
            [Color(red: 0.96, green: 0.46, blue: 0.66), Color(red: 0.42, green: 0.35, blue: 0.88), Color(red: 0.12, green: 0.20, blue: 0.34)]
        case .library:
            [Color(red: 0.44, green: 0.29, blue: 0.66), Color(red: 0.20, green: 0.14, blue: 0.30), Color(red: 0.10, green: 0.08, blue: 0.14)]
        case .greenhouse:
            [Color(red: 0.56, green: 0.82, blue: 0.50), Color(red: 0.16, green: 0.47, blue: 0.39), Color(red: 0.09, green: 0.23, blue: 0.28)]
        case .bathroom:
            [Color(red: 0.55, green: 0.86, blue: 0.96), Color(red: 0.23, green: 0.56, blue: 0.78), Color(red: 0.11, green: 0.22, blue: 0.35)]
        case .vanity:
            [Color(red: 0.96, green: 0.52, blue: 0.78), Color(red: 0.55, green: 0.31, blue: 0.76), Color(red: 0.18, green: 0.11, blue: 0.28)]
        case .garage:
            [Color(red: 0.42, green: 0.44, blue: 0.48), Color(red: 0.18, green: 0.20, blue: 0.24), Color(red: 0.08, green: 0.09, blue: 0.12)]
        case .camping:
            [Color(red: 0.40, green: 0.66, blue: 0.45), Color(red: 0.19, green: 0.38, blue: 0.32), Color(red: 0.08, green: 0.15, blue: 0.18)]
        case .office:
            [Color(red: 0.45, green: 0.58, blue: 0.86), Color(red: 0.24, green: 0.30, blue: 0.47), Color(red: 0.10, green: 0.13, blue: 0.22)]
        case .bedroom:
            [Color(red: 0.98, green: 0.56, blue: 0.74), Color(red: 0.46, green: 0.30, blue: 0.68), Color(red: 0.16, green: 0.10, blue: 0.24)]
        case .gaming:
            [Color(red: 0.30, green: 0.14, blue: 0.58), Color(red: 0.10, green: 0.09, blue: 0.22), Color(red: 0.10, green: 0.62, blue: 0.84)]
        }
    }

    var decorSymbols: [String] {
        switch self {
        case .kitchen: ["fork.knife", "takeoutbag.and.cup.and.straw.fill", "refrigerator.fill"]
        case .playroom: ["gamecontroller.fill", "die.face.5.fill", "balloon.2.fill"]
        case .library: ["books.vertical.fill", "bookmark.fill", "lamp.desk.fill"]
        case .greenhouse: ["leaf.fill", "camera.macro", "drop.fill"]
        case .bathroom: ["drop.fill", "shower.fill", "bubbles.and.sparkles.fill"]
        case .vanity: ["sparkles", "mirror.side.left.fill", "heart.fill"]
        case .garage: ["wrench.and.screwdriver.fill", "car.fill", "gearshape.2.fill"]
        case .camping: ["tent.fill", "flame.fill", "mountain.2.fill"]
        case .office: ["paperclip", "pencil", "folder.fill"]
        case .bedroom: ["bed.double.fill", "moon.stars.fill", "alarm.fill"]
        case .gaming: ["gamecontroller.fill", "headphones", "sparkles"]
        }
    }

    var foregroundMotif: String {
        switch self {
        case .kitchen: "cabinet"
        case .playroom: "blocks"
        case .library: "bookcase"
        case .greenhouse: "leaves"
        case .bathroom: "tiles"
        case .vanity: "lights"
        case .garage: "workbench"
        case .camping: "hills"
        case .office: "desk"
        case .bedroom: "lights"
        case .gaming: "blocks"
        }
    }

    var backgroundAssetName: String? {
        switch self {
        case .kitchen:
            "ThemeKitchen"
        case .bathroom:
            "ThemeBathroom"
        case .office:
            "ThemeOffice"
        case .bedroom:
            "ThemeBedroom"
        case .gaming:
            "ThemeGaming"
        default:
            nil
        }
    }

    var railGradient: [Color] {
        switch self {
        case .garage:
            [Color(red: 0.12, green: 0.13, blue: 0.15), Color(red: 0.63, green: 0.66, blue: 0.70), Color(red: 0.18, green: 0.19, blue: 0.22)]
        case .bathroom, .office:
            [Color(red: 0.22, green: 0.42, blue: 0.55), Color.white.opacity(0.92), Color(red: 0.20, green: 0.50, blue: 0.72)]
        case .vanity, .bedroom, .gaming:
            [Color(red: 0.62, green: 0.24, blue: 0.56), Color(red: 1.00, green: 0.80, blue: 0.44), Color(red: 0.49, green: 0.20, blue: 0.52)]
        default:
            [Color(red: 0.49, green: 0.22, blue: 0.12), Color(red: 1.00, green: 0.64, blue: 0.32), Color(red: 0.55, green: 0.24, blue: 0.15)]
        }
    }
}
