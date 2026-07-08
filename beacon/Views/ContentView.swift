//
//  ContentView.swift
//  beacon
//
//  Created by Vladimir Kosickij on 07.07.2026.
//

import Foundation
import SwiftData
import SwiftUI

public struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.openWindow) private var openWindow
    @Query private var services: [ServiceConfig]
    let scheduler: CheckScheduler

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MenuHeaderView(lastUpdated: scheduler.lastUpdated, scheduler: scheduler) {
                scheduler.refreshAll(services: services)
            }

            Divider()
                .padding(.horizontal, 14)

            if services.isEmpty {
                emptyServicesState
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(services) { service in
                            ServiceRow(
                                service: service,
                                status: scheduler.statuses[service.id]
                                    ?? CheckStatus()
                            ) {
                                scheduler.refreshNow(service)
                            }
                        }
                    }
                }
                .frame(maxHeight: 320)
            }

            Divider()
                .padding(.horizontal, 14)

            VStack(alignment: .leading, spacing: 0) {
                MenuActionRow(icon: "gearshape", title: "Preferences...") {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "preferences")
                }
                MenuActionRow(icon: "power", title: "Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(.vertical, 5)
            #if DEBUG
                Divider()
                    .padding(.horizontal, 14)

                VStack(alignment: .leading, spacing: 0) {
                    MenuActionRow(icon: "gearshape", title: "Reset data...") {
                        resetAndReseed()

                    }
                }
                .padding(.vertical, 5)
            #endif
        }
        .frame(width: 260)
        .task {
            seedServicesIfNeeded()
            scheduler.reconcile(services: services)
        }
        .onChange(of: services.map(\.id)) { _, _ in
            scheduler.reconcile(services: services)
        }
    }

    private var emptyServicesState: some View {
        VStack(spacing: 6) {
            Image(systemName: "server.rack")
                .font(.system(size: 20))
                .foregroundStyle(.tertiary)
            Text("No services configured")
                .font(.system(size: 12, weight: .medium))
            Text("Add one in Preferences")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    private func seedServicesIfNeeded() {
        let seededKey = "hasSeededInitialData"
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }

        context.insert(
            ServiceConfig(
                name: "Example",
                type: .http,
                interval: 30,
                config: ["url": "https://example.com"]
            )
        )

        do {
            try context.save()
            UserDefaults.standard.set(true, forKey: seededKey)
        } catch {
            print("Failed to save seeded services: \(error)")
        }
    }

    #if DEBUG
        private func resetAndReseed() {
            scheduler.stopAll()
            for service in services {
                context.delete(service)
            }
            seedServicesIfNeeded()
            scheduler.reconcile(services: services)
        }
    #endif
}
