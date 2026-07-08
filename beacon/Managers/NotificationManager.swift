//
//  NotificationManager.swift
//  beacon
//
//  Created by Vladimir Kosickij on 08.07.2026.
//

import UserNotifications

enum NotificationManager {
    static func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [
            .alert, .sound,
        ]) { granted, error in
            if let error {
                print("Notification authorization error: \(error)")
            }
        }
    }

    static func notifyDown(serviceNames: [String]) {
        let content = UNMutableNotificationContent()
        content.sound = .default

        if serviceNames.count == 1 {
            content.title = "\(serviceNames[0]) is down"
        } else {
            content.title = "\(serviceNames.count) services are down"
            content.body = serviceNames.joined(separator: ", ")
        }

        let request = UNNotificationRequest(
            identifier: "beacon-down-alert",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
