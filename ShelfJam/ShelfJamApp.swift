//
//  ShelfJamApp.swift
//  ShelfJam
//
//  Created by Talha Gergin on 2.05.2026.
//

import SwiftUI

@main
struct ShelfJamApp: App {
    private let progressStore = UserDefaultsProgressStore()

    var body: some Scene {
        WindowGroup {
            MainMenuView(
                progressStore: progressStore,
                levelProvider: StaticLevelProvider()
            )
        }
    }
}
