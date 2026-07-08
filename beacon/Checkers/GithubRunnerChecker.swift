//
//  GithubRunnerChecker.swift
//  beacon
//
//  Created by Vladimir Kosickij on 07.07.2026.
//

import Foundation

struct RunnersResponse: Codable {
    struct Runner: Codable {
        let name: String
        let status: String
        let busy: Bool
    }
    let runners: [Runner]
}

struct GitHubRunnerChecker: ServiceChecker {
    func check(_ service: ServiceSnapshot) async -> CheckStatus {
        let scope = service.config["scope"] ?? "repo"

        guard let owner = service.config["owner"],
              let runnerName = service.config["runnerName"] else {
            return CheckStatus(state: .unknown, message: "missing owner/runnerName", lastChecked: Date())
        }

        let urlString: String
        switch scope {
        case "org":
            urlString = "https://api.github.com/orgs/\(owner)/actions/runners"
        default:
            guard let repo = service.config["repo"] else {
                return CheckStatus(state: .unknown, message: "missing repo for scope=repo", lastChecked: Date())
            }
            urlString = "https://api.github.com/repos/\(owner)/\(repo)/actions/runners"
        }

        guard let url = URL(string: urlString) else {
            return CheckStatus(state: .unknown, message: "bad url", lastChecked: Date())
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        if let keychainKey = service.config["tokenKeychainKey"], let token = Keychain.read(key: keychainKey) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                return CheckStatus(state: .down, message: "GitHub API error (\(code))", lastChecked: Date())
            }

            let decoded = try JSONDecoder().decode(RunnersResponse.self, from: data)
            guard let runner = decoded.runners.first(where: { $0.name == runnerName }) else {
                return CheckStatus(state: .unknown, message: "runner not found", lastChecked: Date())
            }

            let state: HealthState = runner.status == "online" ? .up : .down
            return CheckStatus(state: state, message: runner.busy ? "\(runner.status), busy" : runner.status, lastChecked: Date())
        } catch {
            return CheckStatus(state: .down, message: error.localizedDescription, lastChecked: Date())
        }
    }
}
