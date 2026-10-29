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
    private let queue = DispatchQueue(label: "SchoolBell.alerts")   // one reschedule at a time
    private let alertMinutes = [20, 10, 5]
    private let maxPending = 60

    func requestPermissionAndSchedule() {
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in
            self.reschedule(completion: nil)
        }
    }

    func reschedule(completion: (() -> Void)?) {
        queue.async {
            let scheduledThrough = self.rebuildAlerts()
            DispatchQueue.main.async {
                UserDefaults.standard.set(scheduledThrough, forKey: "alertsThrough")
                completion?()
            }
        }
    }

    /// Runs on the private queue. Returns the time of the last alert (0 = none).
    private func rebuildAlerts() -> Double {
        // Skip if notifications aren't allowed.
        let check = DispatchSemaphore(value: 0)
        var allowed = false
        center.getNotificationSettings { settings in
            allowed = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
            check.signal()
        }
        check.wait()

        center.removeAllPendingNotificationRequests()
        guard allowed else { return 0 }

        let periods = ScheduleStore.load()
        let cal = Calendar.current
        let now = Date()
        let today = cal.startOfDay(for: now)
        let dayOff = UserDefaults.standard.string(forKey: "dayOff") ?? ""

        let group = DispatchGroup()
        var count = 0
        var lastFire: Date?

        dayLoop: for offset in 0..<14 {
            guard let day = cal.date(byAdding: .day, value: offset, to: today) else { continue }
            if !Schedule.isSchoolDay(day) || Schedule.dayKey(day) == dayOff { continue }

            for (i, period) in periods.enumerated() where period.getsAlerts {
                let end = period.endDate(on: day)
                let next = i + 1 < periods.count ? periods[i + 1] : nil

                for minutes in alertMinutes {
                    let fire = end.addingTimeInterval(-Double(minutes * 60))
                    // Skip past times, and alerts that would land before the period starts (short periods).
                    if fire <= now || fire < period.startDate(on: day) { continue }
                    if count >= maxPending { break dayLoop }

                    let content = UNMutableNotificationContent()
                    content.title = "\(period.name): \(minutes) min left"
                    if let next = next {
                        content.body = next.room.isEmpty ? "Next: \(next.name)" : "Next: \(next.name) · \(next.room)"
                    } else {
                        content.body = "Then school's out"
                    }
                    content.sound = .default

                    let parts = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
                    let id = "bell-\(Schedule.dayKey(day))-\(period.id.uuidString)-\(minutes)"

                    group.enter()
                    center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger)) { _ in
                        group.leave()
                    }
                    count += 1
                    lastFire = fire
                }
            }
        }

        group.wait()
        return lastFire?.timeIntervalSince1970 ?? 0
    }

    /// Ask watchOS to wake the app in the background (about every 6 hours)
    /// to top up alerts. watchOS decides the exact timing.
    func scheduleBackgroundRefresh() {
        let date = Date().addingTimeInterval(6 * 60 * 60)
        WKApplication.shared().scheduleBackgroundRefresh(withPreferredDate: date, userInfo: nil) { _ in }
    }
}
