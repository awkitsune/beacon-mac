//
//  ServiceConfig.swift
//  beacon
//
//  Created by Vladimir Kosickij on 07.07.2026.
//

import Foundation
import SwiftData

enum CheckerType: String, Codable, CaseIterable, Sendable {
    case http
    case tcp
    case githubRunner
    //    case script
}

@Model
class ServiceConfig {
    var id: String
    var name: String
    var type: CheckerType
    var interval: Double
    var config: [String: String]
    var sortOrder: Int

    init(
        name: String,
        type: CheckerType,
        interval: Double,
        config: [String: String],
        sortOrder: Int = 0
    ) {
        self.id = UUID().uuidString
        self.name = name
        self.type = type
        self.interval = interval
        self.config = config
        self.sortOrder = sortOrder
    }

    init(
        id: String,
        name: String,
        type: CheckerType,
        interval: Double,
        config: [String: String],
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.interval = interval
        self.config = config
        self.sortOrder = sortOrder
    }

    static func seedExampleIfNeeded(in context: ModelContext) {
        guard
            !UserDefaults.standard.bool(forKey: SettingsKeys.seededKey.rawValue)
        else { return }

        let example = ServiceConfig(
            name: "Example",
            type: .http,
            interval: 30,
            config: ["url": "https://example.com"],
            sortOrder: 0
        )
        context.insert(example)

        do {
            try context.save()
            UserDefaults.standard.set(
                true,
                forKey: SettingsKeys.seededKey.rawValue
            )
        } catch {
            print("Failed to save seeded services: \(error)")
        }
    }
}
