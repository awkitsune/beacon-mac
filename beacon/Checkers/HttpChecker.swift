//
//  HttpChecker.swift
//  beacon
//
//  Created by Vladimir Kosickij on 07.07.2026.
//

import Foundation

struct HttpChecker: ServiceChecker {
    func check(_ service: ServiceSnapshot) async -> CheckStatus {
        guard let urlString = service.config["url"],
            let url = URL(string: urlString)
        else {
            return CheckStatus(
                state: .unknown,
                message: "missing or invalid url"
            )
        }

        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse else {
                return CheckStatus(
                    state: .unknown,
                    message: "non-HTTP response",
                    lastChecked: Date()
                )
            }
            let state: HealthState =
                (200..<300).contains(http.statusCode) ? .up : .down
            return CheckStatus(
                state: state,
                message: "HTTP \(http.statusCode)",
                lastChecked: Date()
            )
        } catch {
            return CheckStatus(
                state: .down,
                message: error.localizedDescription,
                lastChecked: Date()
            )
        }

    }
}
