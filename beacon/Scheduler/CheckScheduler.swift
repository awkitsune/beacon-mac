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
    private var serviceNames: [String: String] = [:]
    private var tasks: [String: Task<Void, Never>] = [:]
    private var notifyDebounceTask: Task<Void, Never>?

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
            tasks[id]?.cancel()
            tasks.removeValue(forKey: id)
            statuses.removeValue(forKey: id)
            serviceNames.removeValue(forKey: id)
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
        let name = service.name
        Task {
            let result = await CheckerFactory.run(service)
            handleResult(result, id: id, name: name)
        }
    }

    func refreshAll(services: [ServiceConfig]) {
        for service in services {
            refreshNow(service)
        }
    }

    func stopAll() {
        tasks.values.forEach { $0.cancel() }
        tasks.removeAll()
    }

    private func startLoop(for service: ServiceConfig) {
        let id = service.id
        let name = service.name
        let interval = service.interval

        let task = Task {
            while !Task.isCancelled {
                let result = await CheckerFactory.run(service)
                handleResult(result, id: id, name: name)
                let interval = max(interval, 60)
                try? await Task.sleep(
                    nanoseconds: UInt64(interval * 1_000_000_000)
                )
            }
        }
        tasks[id] = task
    }
    private func handleResult(_ result: CheckStatus, id: String, name: String) {
        let previousState = statuses[id]?.state
        statuses[id] = result
        serviceNames[id] = name

        guard previousState != .down, result.state == .down else { return }
        guard UserDefaults.standard.bool(forKey: "notifyOnDown") else { return }
        scheduleDownNotification()
    }
    private func scheduleDownNotification() {
        notifyDebounceTask?.cancel()
        notifyDebounceTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            postDownNotification()
        }
    }

    private func postDownNotification() {
        let downNames =
            statuses
            .filter { $0.value.state == .down }
            .compactMap { serviceNames[$0.key] }
            .sorted()

        guard !downNames.isEmpty else { return }
        NotificationManager.notifyDown(serviceNames: downNames)
    }
}
