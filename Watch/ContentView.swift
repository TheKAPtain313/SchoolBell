import SwiftUI

struct ContentView: View {
    @AppStorage("dayOff") private var dayOff: String = ""
    @AppStorage("alertsThrough") private var alertsThrough: Double = 0

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date
            let status = Schedule.status(at: now, dayOff: dayOff == Schedule.dayKey(now))

            ScrollView {
                VStack(spacing: 8) {
                    Text(now.formatted(.dateTime.hour().minute()))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .monospacedDigit()

                    StatusView(status: status, now: now)

                    Divider()

                    if Schedule.isSchoolDay(now) {
                        Toggle("No school today", isOn: Binding(
                            get: { dayOff == Schedule.dayKey(Date()) },
                            set: { isOn in
                                dayOff = isOn ? Schedule.dayKey(Date()) : ""
                                AlertScheduler.shared.reschedule(completion: nil)
                            }
                        ))
                        .font(.footnote)
                    }

                    if alertsThrough > 0 {
                        let through = Date(timeIntervalSince1970: alertsThrough)
                        Text("Alerts set through \(through.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

struct StatusView: View {
    let status: DayStatus
    let now: Date

    var body: some View {
        switch status {
        case .noSchool(let message):
            Text(message)
                .font(.headline)
                .foregroundStyle(.secondary)

        case .afterSchool:
            Text("School's out")
                .font(.headline)
                .foregroundStyle(.green)

        case .beforeSchool(let first):
            VStack(spacing: 2) {
                Text("School starts in")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(countdown(to: first.start.date(on: now)))
                    .font(.title3.bold())
                    .monospacedDigit()
                Text("\(first.name) · \(first.start.label)")
                    .font(.footnote)
                    .foregroundStyle(first.color)
            }

        case .between(let next):
            VStack(spacing: 2) {
                Text("Next: \(next.name)")
                    .font(.headline)
                    .foregroundStyle(next.color)
                Text("in \(countdown(to: next.start.date(on: now)))")
                    .font(.title3.bold())
                    .monospacedDigit()
            }

        case .inBlock(let block, let next):
            let start = block.start.date(on: now)
            let end = block.end.date(on: now)
            let total = end.timeIntervalSince(start)
            let done = min(max(now.timeIntervalSince(start) / total, 0), 1)

            VStack(spacing: 4) {
                Text(block.name)
                    .font(.headline)
                    .foregroundStyle(block.color)
                if let room = block.room {
                    Text(room)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(countdown(to: end))
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text("left · ends \(block.end.label)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ProgressView(value: done)
                    .tint(block.color)
                if let next = next {
                    Text("Next: \(next.name)")
                        .font(.footnote)
                        .foregroundStyle(next.color)
                } else {
                    Text("Last period")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func countdown(to target: Date) -> String {
        let seconds = max(Int(target.timeIntervalSince(now)), 0)
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }
}
