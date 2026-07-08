//
//  CheckerFactory.swift
//  beacon
//
//  Created by Vladimir Kosickij on 07.07.2026.
//

import Foundation

enum CheckerFactory {
    static func run(_ service: ServiceConfig) async -> CheckStatus {
        let snapshot = ServiceSnapshot(from: service)
        let checker = makeChecker(for: service.type)
        return await checker.check(snapshot)
    }
    
    private static func makeChecker(for type: CheckerType) -> ServiceChecker {
        switch type {
        case .http: return HttpChecker()
        case .githubRunner: return GitHubRunnerChecker()
        case .tcp: return TcpChecker()
        }
    }
}
