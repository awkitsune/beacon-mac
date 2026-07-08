//
//  TcpChecker.swift
//  beacon
//
//  Created by Vladimir Kosickij on 07.07.2026.
//

import Foundation
import Network
import os

struct TcpChecker: ServiceChecker {
    func check(_ service: ServiceSnapshot) async -> CheckStatus {
        guard let host = service.config["host"],
            let portString = service.config["port"],
            let port = UInt16(portString)
        else {
            return CheckStatus(
                state: .unknown,
                message: "missing host/port",
                lastChecked: Date()
            )
        }

        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            return CheckStatus(
                state: .unknown,
                message: "invalid port",
                lastChecked: Date()
            )
        }

        return await withCheckedContinuation { continuation in
            let connection = NWConnection(
                host: NWEndpoint.Host(host),
                port: nwPort,
                using: .tcp
            )

            let didResume = OSAllocatedUnfairLock(initialState: false)

            @Sendable func resume(_ status: CheckStatus) {
                let shouldResume = didResume.withLock { resumed in
                    guard !resumed else { return false }
                    resumed = true
                    return true
                }
                guard shouldResume else { return }
                connection.cancel()
                continuation.resume(returning: status)
            }

            connection.stateUpdateHandler = { newState in
                switch newState {
                case .ready:
                    resume(
                        CheckStatus(
                            state: .up,
                            message: "port open",
                            lastChecked: Date()
                        )
                    )
                case .failed(let error):
                    resume(
                        CheckStatus(
                            state: .down,
                            message: error.localizedDescription,
                            lastChecked: Date()
                        )
                    )
                default:
                    break
                }
            }

            connection.start(queue: .global())

            DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                resume(
                    CheckStatus(
                        state: .down,
                        message: "timeout",
                        lastChecked: Date()
                    )
                )
            }
        }
    }
}
