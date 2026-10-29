import SwiftUI

// MARK: - One block of the school day (a class, recess, or lunch)

struct Period: Codable, Identifiable, Equatable {
    enum Kind: String, Codable, CaseIterable {
        case classPeriod, recess, lunch

        var label: String {
            switch self {
            case .classPeriod: return "Class"
            case .recess: return "Recess"
            case .lunch: return "Lunch"
            }
        }

        var color: Color {
            switch self {
            case .classPeriod: return .blue
            case .recess: return .green
            case .lunch: return .orange
            }
        }
    }

    var id = UUID()
    var name: String
    var room: String
    var startMinutes: Int   // minutes after midnight, 8:15 AM = 495
    var endMinutes: Int
    var kind: Kind

    /// Only classes get the 20 / 10 / 5-minute alerts.
    var getsAlerts: Bool { kind == .classPeriod }

    func startDate(on day: Date) -> Date { Schedule.date(minutes: startMinutes, on: day) }
    func endDate(on day: Date) -> Date { Schedule.date(minutes: endMinutes, on: day) }
}

// MARK: - Saved schedule (editable in Settings)

final class ScheduleStore: ObservableObject {
    static let shared = ScheduleStore()
    private static let key = "periods.v1"

    @Published private(set) var periods: [Period]

    private init() {
        periods = ScheduleStore.load()
    }

    /// Thread-safe read straight from storage (used by the alert scheduler).
    static func load() -> [Period] {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([Period].self, from: data),
           !saved.isEmpty {
            return saved.sorted { $0.startMinutes < $1.startMinutes }
        }
        return Schedule.defaultPeriods
    }

    func save(_ period: Period) {
        if let i = periods.firstIndex(where: { $0.id == period.id }) {
            periods[i] = period
        } else {
            periods.append(period)
        }
        commit()
    }

    func delete(_ period: Period) {
        periods.removeAll { $0.id == period.id }
        commit()
    }

    func resetToDefault() {
        periods = Schedule.defaultPeriods
        commit()
    }

    private func commit() {
        periods.sort { $0.startMinutes < $1.startMinutes }
        if let data = try? JSONEncoder().encode(periods) {
            UserDefaults.standard.set(data, forKey: ScheduleStore.key)
        }
        AlertScheduler.shared.reschedule(completion: nil)
    }
}

// MARK: - Schedule math

enum Schedule {
    /// The schedule from the school portal. "Reset" in Settings brings this back.
    static let defaultPeriods: [Period] = [
        Period(name: "Math",           room: "Room 102",  startMinutes: m(8, 15),  endMinutes: m(9, 15),  kind: .classPeriod),
        Period(name: "Band",           room: "Room FA12", startMinutes: m(9, 15),  endMinutes: m(10, 14), kind: .classPeriod),
        Period(name: "Social Studies", room: "Room 110",  startMinutes: m(10, 14), endMinutes: m(11, 13), kind: .classPeriod),
        Period(name: "Science",        room: "Room 101",  startMinutes: m(11, 13), endMinutes: m(12, 15), kind: .classPeriod),
        Period(name: "Recess",         room: "",          startMinutes: m(12, 15), endMinutes: m(12, 45), kind: .recess),
        Period(name: "Lunch",          room: "",          startMinutes: m(12, 45), endMinutes: m(13, 7),  kind: .lunch),
        Period(name: "STM",            room: "Room 103",  startMinutes: m(13, 7),  endMinutes: m(14, 6),  kind: .classPeriod),
        Period(name: "ELA",            room: "Room 107",  startMinutes: m(14, 6),  endMinutes: m(15, 15), kind: .classPeriod),
    ]

    static func m(_ hour: Int, _ minute: Int) -> Int { hour * 60 + minute }

    static func date(minutes: Int, on day: Date) -> Date {
        Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: day) ?? day
    }

    /// "8:15 AM"
    static func label(_ minutes: Int) -> String {
        let h = minutes / 60
        let h12 = h % 12 == 0 ? 12 : h % 12
        return String(format: "%d:%02d %@", h12, minutes % 60, h < 12 ? "AM" : "PM")
    }

    /// Monday through Friday. (Calendar weekdays: Sunday = 1 ... Saturday = 7)
    static func isSchoolDay(_ date: Date) -> Bool {
        (2...6).contains(Calendar.current.component(.weekday, from: date))
    }

    /// "2026-10-29" style key used for the "No school today" switch.
    static func dayKey(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func status(at now: Date, periods: [Period], dayOff: Bool) -> DayStatus {
        if !isSchoolDay(now) { return .noSchool("No school today") }
        if dayOff { return .noSchool("Day off · alerts paused") }
        guard let first = periods.first, let last = periods.last else { return .noSchool("No periods set") }

        if now < first.startDate(on: now) { return .beforeSchool(first: first) }
        if now >= last.endDate(on: now) { return .afterSchool }

        for (i, p) in periods.enumerated() where now >= p.startDate(on: now) && now < p.endDate(on: now) {
            let next = i + 1 < periods.count ? periods[i + 1] : nil
            return .inPeriod(p, next: next)
        }
        if let next = periods.first(where: { $0.startDate(on: now) > now }) {
            return .between(next: next)
        }
        return .afterSchool
    }
}

enum DayStatus {
    case noSchool(String)
    case beforeSchool(first: Period)
    case inPeriod(Period, next: Period?)
    case between(next: Period)
    case afterSchool
}
