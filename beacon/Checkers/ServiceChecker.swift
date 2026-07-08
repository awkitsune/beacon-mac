//
//  ServiceChecker.swift
//  beacon
//
//  Created by Vladimir Kosickij on 07.07.2026.
//

protocol ServiceChecker {
    func check(_ service: ServiceSnapshot) async -> CheckStatus
}
