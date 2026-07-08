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
            fatalError(
                String(
                    localized: "message.failed.model-container",
                    defaultValue:
                        "Could not create ModelContainer: \(error.localizedDescription)",
                )
            )
        }
    }()

    @State private var scheduler = CheckScheduler()
    @Environment(\.openWindow) private var openWindow

    init() {
        UserDefaults.standard.register(defaults: [
            SettingsKeys.showStatusBadge.rawValue: false,
            SettingsKeys.notifyOnDown.rawValue: true,
            SettingsKeys.seededKey.rawValue: false,
        ])
        NotificationManager.requestNotificationPermission()
    }

    var body: some Scene {
        MenuBarScene(scheduler: scheduler, container: container)

        Window(
            String(
                localized: "window.preferences.title",
                defaultValue:
                    "beacon Preferences",
            ),
            id: "preferences"
        ) {
            PreferencesView(scheduler: scheduler)
                .environment(\.modelContext, container.mainContext)
        }
        .defaultSize(width: 640, height: 420)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button(
                    String(
                        localized: "labels.buttons.about",
                        defaultValue:
                            "About beacon",
                    )
                ) {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "about")
                }
            }
        }

        Window(
            String(
                localized: "window.about.title",
                defaultValue:
                    "About beacon",
            ),
            id: "about"
        ) {
            AboutView()
        }
        .windowResizability(.contentSize)
    }
}
