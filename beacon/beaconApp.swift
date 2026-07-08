//
//  beaconApp.swift
//  beacon
//
//  Created by Vladimir Kosickij on 07.07.2026.
//

import SwiftData
import SwiftUI

@main
struct beaconApp: App {
    let container: ModelContainer = {
        do {
            return try ModelContainer(for: ServiceConfig.self)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @State private var scheduler = CheckScheduler()

    var body: some Scene {
        MenuBarScene(scheduler: scheduler, container: container)

        Window("beacon Preferences", id: "preferences") {
            PreferencesView(scheduler: scheduler)
                .environment(\.modelContext, container.mainContext)
        }
        .defaultSize(width: 640, height: 420)
    }

}
