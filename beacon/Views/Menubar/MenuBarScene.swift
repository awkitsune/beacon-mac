//
//  MenuBarScene.swift
//  beacon
//
//  Created by Vladimir Kosickij on 07.07.2026.
//

import SwiftData
import SwiftUI

struct MenuBarScene: Scene {
    let scheduler: CheckScheduler
    let container: ModelContainer

    @AppStorage(SettingsKeys.showStatusBadge.rawValue) private
        var showStatusBadge = true

    var body: some Scene {
        MenuBarExtra {
            ContentView(scheduler: scheduler)
                .environment(\.modelContext, container.mainContext)
        } label: {
            HStack {
                Image(systemName: symbolName(for: scheduler.worstState))
                    .font(.system(size: 13))
                Text(badgeText)
                    .font(.system(size: 11, weight: .semibold))
            }
            .task {
                bootstrap()
            }
        }
        .menuBarExtraStyle(.window)
    }

    private func bootstrap() {
        let context = container.mainContext

        do {
            if !UserDefaults.standard.bool(forKey: SettingsKeys.seededKey.rawValue) {
                let example = ServiceConfig(
                    name: "Example",
                    type: .http,
                    interval: 30,
                    config: ["url": "https://example.com"],
                    sortOrder: 0
                )
                context.insert(example)
                try context.save()
                UserDefaults.standard.set(true, forKey: SettingsKeys.seededKey.rawValue)
            }

            let descriptor = FetchDescriptor<ServiceConfig>(sortBy: [
                SortDescriptor(\.sortOrder)
            ])
            let existing = try context.fetch(descriptor)
            scheduler.reconcile(services: existing)
        } catch {
            print("Bootstrap failed: \(error)")
        }
    }

    private func symbolName(for state: HealthState) -> String {
        switch state {
        case .up: return "server.rack"
        case .unknown: return "questionmark.circle"
        case .down: return "exclamationmark.triangle.fill"
        }
    }

    private var badgeText: String {
        guard showStatusBadge else { return "" }

        var parts: [String] = []
        if scheduler.upCount > 0 { parts.append("▲\(scheduler.upCount)") }
        if scheduler.downCount > 0 { parts.append("▼\(scheduler.downCount)") }
        return parts.joined(separator: " ")
    }
}
