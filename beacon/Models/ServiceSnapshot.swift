//
//  ServiceSnapshot.swift
//  beacon
//
//  Created by Vladimir Kosickij on 07.07.2026.
//

struct ServiceSnapshot: Sendable, Codable {
    let id: String
    let name: String
    let type: CheckerType
    let interval: Double
    let config: [String: String]
    
    init(from service: ServiceConfig) {
        self.id = service.id
        self.name = service.name
        self.type = service.type
        self.interval = service.interval
        self.config = service.config
    }
}
