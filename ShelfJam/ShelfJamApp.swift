//
//  ShelfJamApp.swift
//  ShelfJam
//
//  Created by Talha Gergin on 2.05.2026.
//

import SwiftUI

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

@main
struct ShelfJamApp: App {
    private let progressStore = UserDefaultsProgressStore()

    init() {
        #if canImport(GoogleMobileAds)
        MobileAds.shared.start(completionHandler: nil)
        #endif
    }

    var body: some Scene {
        WindowGroup {
            MainMenuView(
                progressStore: progressStore,
                levelProvider: StaticLevelProvider()
            )
        }
    }
}
