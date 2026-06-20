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
    case cheese
    case bread
    case milk
    case honey
    case dice
    case puzzle
    case rocket
    case drum
    case notebook
    case pen
    case paperclip
    case lamp
    case soap
    case towel
    case shampoo
    case sponge
    case perfume
    case lipstick
    case mirror
    case comb
    case wrench
    case tire
    case helmet
    case fuel
    case compass
    case flashlight
    case boot
    case marshmallow
    case pillow
    case alarmClock
    case slipper
    case headphones
    case gamepad
    case console

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
        case .cheese: "Cheese"
        case .bread: "Bread"
        case .milk: "Milk"
        case .honey: "Honey"
        case .dice: "Dice"
        case .puzzle: "Puzzle"
        case .rocket: "Rocket"
        case .drum: "Drum"
        case .notebook: "Notebook"
        case .pen: "Pen"
        case .paperclip: "Paperclip"
        case .lamp: "Lamp"
        case .soap: "Soap"
        case .towel: "Towel"
        case .shampoo: "Shampoo"
        case .sponge: "Sponge"
        case .perfume: "Perfume"
        case .lipstick: "Lipstick"
        case .mirror: "Mirror"
        case .comb: "Comb"
        case .wrench: "Wrench"
        case .tire: "Tire"
        case .helmet: "Helmet"
        case .fuel: "Fuel"
        case .compass: "Compass"
        case .flashlight: "Flashlight"
        case .boot: "Boot"
        case .marshmallow: "Marshmallow"
        case .pillow: "Pillow"
        case .alarmClock: "Alarm Clock"
        case .slipper: "Slipper"
        case .headphones: "Headphones"
        case .gamepad: "Gamepad"
        case .console: "Console"
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
        case .cheese: "🧀"
        case .bread: "🍞"
        case .milk: "🥛"
        case .honey: "🍯"
        case .dice: "🎲"
        case .puzzle: "🧩"
        case .rocket: "🚀"
        case .drum: "🥁"
        case .notebook: "📒"
        case .pen: "✏️"
        case .paperclip: "📎"
        case .lamp: "🛋️"
        case .soap: "🧼"
        case .towel: "🧺"
        case .shampoo: "🧴"
        case .sponge: "🧽"
        case .perfume: "🧪"
        case .lipstick: "💄"
        case .mirror: "🪞"
        case .comb: "🪮"
        case .wrench: "🔧"
        case .tire: "⚙️"
        case .helmet: "🪖"
        case .fuel: "⛽️"
        case .compass: "🧭"
        case .flashlight: "🔦"
        case .boot: "🥾"
        case .marshmallow: "🍡"
        case .pillow: "🛏️"
        case .alarmClock: "⏰"
        case .slipper: "🥿"
        case .headphones: "🎧"
        case .gamepad: "🎮"
        case .console: "🕹️"
        }
    }

    var assetName: String? {
        switch self {
        case .apple: "ItemApple"
        case .teddy: "ItemTeddy"
        case .car: "ItemCar"
        case .book: "ItemBook"
        case .cup: "ItemCup"
        case .plant: "ItemPlant"
        case .ball: "ItemBall"
        case .gift: "ItemGift"
        default: nil
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
        case .cheese, .bread, .honey, .lamp, .fuel, .marshmallow: .yellow
        case .milk, .soap, .towel, .shampoo, .sponge, .paperclip: .cyan
        case .dice, .puzzle, .rocket, .drum: .teal
        case .notebook, .pen, .perfume, .lipstick, .mirror, .comb: .purple
        case .wrench, .tire, .helmet, .compass, .flashlight, .boot: .gray
        case .pillow, .alarmClock, .slipper: .pink
        case .headphones, .gamepad, .console: .indigo
        }
    }
}
