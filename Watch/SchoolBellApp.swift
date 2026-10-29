import SwiftUI
import WatchKit
import UserNotifications

@main
struct SchoolBellApp: App {
    @WKApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

final class AppDelegate: NSObject, WKApplicationDelegate, UNUserNotificationCenterDelegate {

    func applicationDidFinishLaunching() {
        UNUserNotificationCenter.current().delegate = self
        AlertScheduler.shared.requestPermissionAndSchedule()
        AlertScheduler.shared.scheduleBackgroundRefresh()
    }

    func applicationDidBecomeActive() {
        // Every time the app opens, refresh the upcoming alerts.
        AlertScheduler.shared.reschedule(completion: nil)
    }

    // Runs in the background a few times a day so alerts keep getting topped up
    // even if the app isn't opened.
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            if let refresh = task as? WKApplicationRefreshBackgroundTask {
                AlertScheduler.shared.reschedule {
                    AlertScheduler.shared.scheduleBackgroundRefresh()
                    refresh.setTaskCompletedWithSnapshot(false)
                }
            } else {
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

    // Show the alert even if the app is open on the watch.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
