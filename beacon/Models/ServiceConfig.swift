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

    init(
        name: String,
        type: CheckerType,
        interval: Double,
        config: [String: String]
    ) {
        self.id = UUID().uuidString
        self.name = name
        self.type = type
        self.interval = interval
        self.config = config
    }
}
