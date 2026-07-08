//
//  GeneralSettingsView.swift
//  beacon
//
//  Created by Vladimir Kosickij on 07.07.2026.
//

import Foundation
import ServiceManagement
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct GeneralSettingsView: View {
    let scheduler: CheckScheduler
    let services: [ServiceConfig]
    let context: ModelContext

    @AppStorage(SettingsKeys.showStatusBadge.rawValue) private
        var showStatusBadge = false
    @AppStorage(SettingsKeys.notifyOnDown.rawValue) private var notifyOnDown =
        true
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Section(
                String(
                    localized: "preferences.menubar.title",
                    defaultValue: "Menu Bar",
                )
            ) {
                Toggle(
                    String(
                        localized: "preferences.menubar.up-down",
                        defaultValue: "Show up/down counts on icon",
                    ),
                    isOn: $showStatusBadge
                )
                Toggle(
                    String(
                        localized:
                            "preferences.menubar.notifications",
                        defaultValue: "Notify when a service goes down",
                    ),
                    isOn: $notifyOnDown
                )
            }
            Section(
                String(
                    localized: "preferences.startup.title",
                    defaultValue: "Startup",
                )
            ) {
                Toggle(
                    String(
                        localized:
                            "preferences.startup.launch-at-login",
                        defaultValue: "Launch beacon at login",
                    ),
                    isOn: $launchAtLogin
                )
                .onChange(of: launchAtLogin) { _, enabled in
                    do {
                        if enabled {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        print(
                            String(
                                localized:
                                    "message.failed.launch-at-login",
                                defaultValue:
                                    "Failed to update launch-at-login: \(error.localizedDescription)",
                            )
                        )
                    }
                }

            }
            Section(
                String(
                    localized: "preferences.configuration.title",
                    defaultValue: "Configuration",
                )
            ) {
                HStack(spacing: 8) {
                    Button(
                        String(
                            localized: "preferences.configuration.export",
                            defaultValue: "Export Config...",
                        )
                    ) { exportConfig() }
                    Button(
                        String(
                            localized: "preferences.configuration.import",
                            defaultValue: "Import Config...",
                        )
                    ) { importConfig() }
                }

                Text(
                    String(
                        localized: "message.info.configuration-export-keychain",
                        defaultValue:
                            "Exported files don't include Keychain tokens — you'll need to re-add those after importing on a new Mac.",
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(
            String(
                localized: "preferences.title",
                defaultValue: "Preferences",
            )
        )
    }

    @MainActor
    private func exportConfig() {
        let snapshots = services.map(ServiceSnapshot.init(from:))
        guard let data = try? JSONEncoder().encode(snapshots) else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "beacon-config.json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? data.write(to: url)
    }

    @MainActor
    private func importConfig() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url,
            let data = try? Data(contentsOf: url),
            let snapshots = try? JSONDecoder().decode(
                [ServiceSnapshot].self,
                from: data
            )
        else { return }

        var existingByID = Dictionary(
            uniqueKeysWithValues: services.map { ($0.id, $0) }
        )
        var nextSortOrder = (services.map(\.sortOrder).max() ?? -1) + 1

        for snapshot in snapshots {
            if let existing = existingByID[snapshot.id] {
                existing.name = snapshot.name
                existing.type = snapshot.type
                existing.interval = snapshot.interval
                existing.config = snapshot.config
                // sortOrder deliberately untouched - keep its current position
            } else {
                let newService = ServiceConfig(
                    id: snapshot.id,
                    name: snapshot.name,
                    type: snapshot.type,
                    interval: snapshot.interval,
                    config: snapshot.config,
                    sortOrder: nextSortOrder
                )
                context.insert(newService)
                existingByID[snapshot.id] = newService
                scheduler.start(newService)
                nextSortOrder += 1
            }
        }

        try? context.save()
    }
}
