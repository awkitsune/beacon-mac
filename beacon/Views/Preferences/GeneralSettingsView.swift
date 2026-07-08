//
//  GeneralSettingsView.swift
//  beacon
//
//  Created by Vladimir Kosickij on 07.07.2026.
//

import Foundation
import ServiceManagement
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct GeneralSettingsView: View {
    let services: [ServiceConfig]
    let context: ModelContext

    @AppStorage(SettingsKeys.showStatusBadge.rawValue) private
        var showStatusBadge = false
    @AppStorage(SettingsKeys.notifyOnDown.rawValue) private var notifyOnDown =
        true
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Section("Menu Bar") {
                Toggle("Show up/down counts on icon", isOn: $showStatusBadge)
                Toggle("Notify when a service goes down", isOn: $notifyOnDown)
            }
            Section("Startup") {
                Toggle("Launch beacon at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        do {
                            if enabled {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            print("Failed to update launch-at-login: \(error)")
                        }
                    }

            }
            Section("Configuration") {
                HStack(spacing: 8) {
                    Button("Export Config...") { exportConfig() }
                    Button("Import Config...") { importConfig() }
                }
                
                Text(
                    "Exported files don't include Keychain tokens — you'll need to re-add those after importing on a new Mac."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Preferences")
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
              let snapshots = try? JSONDecoder().decode([ServiceSnapshot].self, from: data) else { return }

        var existingByID = Dictionary(uniqueKeysWithValues: services.map { ($0.id, $0) })
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
                nextSortOrder += 1
            }
        }

        try? context.save()
    }
}
