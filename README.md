<p align="center">
  <img src="docs/appicon.png" width="128" height="128" alt="beacon icon">
</p>

<h1 align="center">beacon</h1>

<p align="center">
  A lightweight macOS menu bar app that watches your services and tells you the moment one goes down. 
  <br>
  Built with SwiftUI and SwiftData.
</p>

## What it does

beacon lives in your menu bar and periodically checks the things you tell it to watch, showing an aggregate up/down count and popping a native notification when something fails. No dashboard, no server, nothing to host.

Three checker types are built in:

- **HTTP** — requests a URL, healthy on any `2xx` response
- **TCP port** — opens a socket to `host:port` (5s timeout)
- **GitHub Actions runner** — looks up a specific self-hosted runner by name, scoped to a repo or an org, and reports its online/offline status via the GitHub REST API

## Features

- Menu bar–only footprint — the app stays an accessory (no Dock icon) except while its Preferences window is open
- Per-service check interval, reorderable service list, add/remove from Preferences
- Down notifications, debounced a few seconds so a batch of simultaneous failures becomes one alert instead of many
- GitHub tokens are written straight to the macOS Keychain under a label you choose — never stored alongside the rest of beacon's config
- Export/import service configuration as JSON (tokens are deliberately excluded, so you re-enter them after importing on a new Mac)
- Optional launch-at-login
- Localized UI strings (`Localizable.xcstrings`)

## Requirements

- macOS 14.6+
- Xcode 26+ to build (the app icon uses the Icon Composer `.icon` asset format introduced in Xcode 26)

## Building

```sh
git clone https://github.com/awkitsune/beacon-mac.git
cd beacon-mac
open beacon.xcodeproj
```

## Adding a service

1. Click the beacon icon in the menu bar → **Preferences**.
2. Click **+**, choose a type (HTTP / TCP port / GitHub runner), fill in its config, and set a check interval.
3. For a GitHub runner: give it a Keychain label, paste a personal access token, and click **Save token to Keychain**. The token is read from Keychain at check time and is never persisted in the service's own config or in exported JSON.

## Project layout

```
beacon/
├── Checkers/       ServiceChecker protocol, HttpChecker, TcpChecker, GitHubRunnerChecker, CheckerFactory
├── Models/         ServiceConfig (SwiftData model), ServiceSnapshot, CheckStatus / HealthState
├── Scheduler/      CheckScheduler — one polling Task per service, status aggregation, down-notification debounce
├── Managers/       NotificationManager — local notification permission + delivery
├── Keychain/       Thin wrapper over Security/SecItem for storing GitHub tokens
└── Views/
    ├── Menubar/     MenuBarExtra scene and its dropdown content
    ├── Preferences/ Settings window — service list, general settings, per-service detail form
    └── About/       About window
```

## License

MIT — see [LICENSE](LICENSE).
