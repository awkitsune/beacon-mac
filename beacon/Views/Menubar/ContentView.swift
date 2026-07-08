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
    @Query(sort: \ServiceConfig.sortOrder) private var services: [ServiceConfig]
    let scheduler: CheckScheduler

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MenuHeaderView(
                lastUpdated: scheduler.lastUpdated,
                scheduler: scheduler
            ) {
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
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxHeight: 320)
            }

            Divider()
                .padding(.horizontal, 14)

            VStack(alignment: .leading, spacing: 0) {
                MenuActionRow(
                    icon: "gearshape",
                    title: String(
                        localized: "labels.buttons.preferences",
                        defaultValue: "Preferences...",
                    )
                ) {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "preferences")
                }
                MenuActionRow(
                    icon: "info.circle",
                    title: String(
                        localized: "labels.buttons.about",
                        defaultValue: "About beacon",
                    )
                ) {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "about")
                }
                MenuActionRow(
                    icon: "power",
                    title: String(
                        localized: "labels.buttons.quit",
                        defaultValue: "Quit",
                    )
                ) {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(.vertical, 5)
            #if DEBUG
                Divider()
                    .padding(.horizontal, 14)

                VStack(alignment: .leading, spacing: 0) {
                    MenuActionRow(
                        icon: "gearshape",
                        title: String(
                            localized: "labels.buttons.reset-data",
                            defaultValue: "Reset data",
                        )
                    ) {
                        resetAndReseed()
                    }
                }
                .padding(.vertical, 5)
            #endif
        }
        .frame(width: 260)
        .onChange(of: services.map(\.id)) { _, _ in
            scheduler.reconcile(services: services)
        }
    }

    private var emptyServicesState: some View {
        VStack(spacing: 6) {
            Image(systemName: "server.rack")
                .font(.system(size: 20))
                .foregroundStyle(.tertiary)
            Text(
                String(
                    localized: "info.no-configured-services.label",
                    defaultValue: "No services configured",
                )
            )
            .font(.system(size: 12, weight: .medium))
            Text(
                String(
                    localized: "info.no-configured-services.description",
                    defaultValue: "Add one in Preferences",
                )
            )
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    #if DEBUG
        private func resetAndReseed() {
            scheduler.stopAll()
            for service in services {
                context.delete(service)
            }
            UserDefaults.standard.set(
                false,
                forKey: SettingsKeys.seededKey.rawValue
            )
            ServiceConfig.seedExampleIfNeeded(in: context)
            scheduler.reconcile(services: services)
        }
    #endif
}
