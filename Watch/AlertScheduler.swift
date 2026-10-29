import Foundation
import UserNotifications
import WatchKit

/// Schedules the 20 / 10 / 5-minute "time left" alerts on the watch itself,
/// so they fire with no iPhone nearby and no internet.
///
/// Apple caps pending alerts at 64 per app, so this schedules the next few
/// school days and tops up every time the app opens or refreshes in the background.
final class AlertScheduler {
    static let shared = AlertScheduler()

    private let center = UNUserNotificationCenter.current()
    private let alertMinutes = [20, 10, 5]
    private let maxPending = 60

    func requestPermissionAndSchedule() {
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            if granted {
                self.reschedule(completion: nil)
            }
        }
    }

    func reschedule(completion: (() -> Void)?) {
        center.removeAllPendingNotificationRequests()

        let cal = Calendar.current
        let now = Date()
        let today = cal.startOfDay(for: now)
        let dayOff = UserDefaults.standard.string(forKey: "dayOff") ?? ""

        var count = 0
        var lastFire: Date?

        dayLoop: for offset in 0..<14 {
            guard let day = cal.date(byAdding: .day, value: offset, to: today) else { continue }
            if !Schedule.isSchoolDay(day) { continue }
            if Schedule.dayKey(day) == dayOff { continue }

            for block in Schedule.blocks where block.getsAlerts {
                let end = block.end.date(on: day)
                let next = Schedule.block(after: block)

                for minutes in alertMinutes {
                    let fire = end.addingTimeInterval(-Double(minutes * 60))
                    if fire <= now { continue }
                    if count >= maxPending { break dayLoop }

                    let content = UNMutableNotificationContent()
                    content.title = "\(block.name): \(minutes) min left"
                    if let next = next {
                        if let room = next.room {
                            content.body = "Next: \(next.name) · \(room)"
                        } else {
                            content.body = "Next: \(next.name)"
                        }
                    } else {
                        content.body = "Then school's out"
                    }
                    content.sound = .default

                    let parts = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
                    let id = "bell-\(Schedule.dayKey(day))-\(block.name)-\(minutes)"
                    center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))

                    count += 1
                    lastFire = fire
                }
            }
        }

        let through = lastFire?.timeIntervalSince1970 ?? 0
        DispatchQueue.main.async {
            UserDefaults.standard.set(through, forKey: "alertsThrough")
            completion?()
        }
    }

    /// Ask watchOS to wake the app in the background (about every 6 hours)
    /// to top up alerts. watchOS decides the exact timing.
    func scheduleBackgroundRefresh() {
        let date = Date().addingTimeInterval(6 * 60 * 60)
        WKApplication.shared().scheduleBackgroundRefresh(withPreferredDate: date, userInfo: nil) { _ in }
    }
}
