//
//  CheckScheduler.swift
//  beacon
//
//  Created by Vladimir Kosickij on 07.07.2026.
//

import Foundation

@Observable
@MainActor
class CheckScheduler {
    var statuses: [String: CheckStatus] = [:]
    private var tasks: [String:Task<Void, Never>] = [:]
    
    var lastUpdated: Date? {
        statuses.values.compactMap(\.lastChecked).max()
    }
    
    var worstState: HealthState {
        statuses.values.map(\.state).max() ?? .unknown
    }
    
    var downCount: Int {
        statuses.values.filter { $0.state != .up }.count
    }

    var upCount: Int {
        statuses.values.filter { $0.state == .up }.count
    }
    
    func reconcile(services: [ServiceConfig]) {
        let currentIDs = Set(services.map(\.id))

        // stop and forget anything that no longer exists
        for id in tasks.keys where !currentIDs.contains(id) {
            stop(id: id)
        }

        // start loops for anything new
        for service in services {
            guard tasks[service.id] == nil else { continue }
            statuses[service.id] = CheckStatus()
            startLoop(for: service)
        }
    }

    func stop(id: String) {
        tasks[id]?.cancel()
        tasks.removeValue(forKey: id)
        statuses.removeValue(forKey: id)
    }
    
    func refreshNow(_ service: ServiceConfig) {
        let id = service.id
        Task {
            let result = await CheckerFactory.run(service)
            statuses[id] = result
        }
    }
    
    func refreshAll(services: [ServiceConfig]) {
        for service in services {
            refreshNow(service)
        }
    }
    
    func stopAll() {
        tasks.values.forEach{ $0.cancel() }
        tasks.removeAll()
    }
    
    private func startLoop(for service: ServiceConfig) {
        let id = service.id

        let task = Task {
            while !Task.isCancelled {
                let result = await CheckerFactory.run(service)
                guard !Task.isCancelled else { break }
                statuses[id] = result
                let interval = max(service.interval, 1)
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
        tasks[id] = task
    }
}
