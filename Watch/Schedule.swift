import SwiftUI

// MARK: - Edit your schedule here
// Times are 24-hour (1:07 PM = 13:07). Only class periods get 20/10/5-minute alerts.

enum Schedule {
    static let blocks: [Block] = [
        Block(name: "Math",           room: "Room 102",  start: .init(8, 15),  end: .init(9, 15),  kind: .classPeriod),
        Block(name: "Band",           room: "Room FA12", start: .init(9, 15),  end: .init(10, 14), kind: .classPeriod),
        Block(name: "Social Studies", room: "Room 110",  start: .init(10, 14), end: .init(11, 13), kind: .classPeriod),
        Block(name: "Science",        room: "Room 101",  start: .init(11, 13), end: .init(12, 15), kind: .classPeriod),
        Block(name: "Recess",         room: nil,         start: .init(12, 15), end: .init(12, 45), kind: .recess),
        Block(name: "Lunch",          room: nil,         start: .init(12, 45), end: .init(13, 7),  kind: .lunch),
        Block(name: "STM",            room: "Room 103",  start: .init(13, 7),  end: .init(14, 6),  kind: .classPeriod),
        Block(name: "ELA",            room: "Room 107",  start: .init(14, 6),  end: .init(15, 15), kind: .classPeriod),
    ]

    // Monday through Friday. (Calendar weekdays: Sunday = 1 ... Saturday = 7)
    static func isSchoolDay(_ date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        return (2...6).contains(weekday)
    }

    // "2026-10-29" style key used for the "No school today" switch.
    static func dayKey(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func block(after block: Block) -> Block? {
        guard let i = blocks.firstIndex(where: { $0.name == block.name }), i + 1 < blocks.count else { return nil }
        return blocks[i + 1]
    }

    static func status(at now: Date, dayOff: Bool) -> DayStatus {
        if !isSchoolDay(now) { return .noSchool("No school today") }
        if dayOff { return .noSchool("Day off — alerts paused") }

        guard let first = blocks.first, let last = blocks.last else { return .afterSchool }

        if now < first.start.date(on: now) { return .beforeSchool(first: first) }
        if now >= last.end.date(on: now) { return .afterSchool }

        for block in blocks {
            let s = block.start.date(on: now)
            let e = block.end.date(on: now)
            if now >= s && now < e {
                return .inBlock(block, next: Schedule.block(after: block))
            }
        }
        // Gap between blocks (none in the current schedule, but handled anyway).
        if let next = blocks.first(where: { $0.start.date(on: now) > now }) {
            return .between(next: next)
        }
        return .afterSchool
    }
}

struct ClockTime {
    let hour: Int
    let minute: Int

    init(_ hour: Int, _ minute: Int) {
        self.hour = hour
        self.minute = minute
    }

    func date(on day: Date) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    var label: String {
        let h12 = hour % 12 == 0 ? 12 : hour % 12
        return String(format: "%d:%02d", h12, minute)
    }
}

struct Block {
    enum Kind { case classPeriod, recess, lunch }

    let name: String
    let room: String?
    let start: ClockTime
    let end: ClockTime
    let kind: Kind

    var getsAlerts: Bool { kind == .classPeriod }

    var color: Color {
        switch kind {
        case .classPeriod: return .blue
        case .recess: return .green
        case .lunch: return .orange
        }
    }
}

enum DayStatus {
    case noSchool(String)
    case beforeSchool(first: Block)
    case inBlock(Block, next: Block?)
    case between(next: Block)
    case afterSchool
}
