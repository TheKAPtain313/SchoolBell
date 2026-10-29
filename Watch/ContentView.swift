import SwiftUI

struct ContentView: View {
    @ObservedObject private var store = ScheduleStore.shared
    @AppStorage("dayOff") private var dayOff: String = ""
    @AppStorage("alertsThrough") private var alertsThrough: Double = 0

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            ScrollView {
                VStack(spacing: 8) {
                    Text(context.date, format: .dateTime.hour().minute())
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .monospacedDigit()

                    StatusView(
                        status: Schedule.status(at: context.date,
                                                periods: store.periods,
                                                dayOff: dayOff == Schedule.dayKey(context.date)),
                        now: context.date
                    )

                    Divider()

                    if Schedule.isSchoolDay(context.date) {
                        Toggle("No school today", isOn: dayOffBinding)
                            .font(.footnote)
                    }

                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }

                    Text(alertsLine)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 4)
            }
        }
    }

    private var dayOffBinding: Binding<Bool> {
        Binding(
            get: { dayOff == Schedule.dayKey(Date()) },
            set: { isOn in
                dayOff = isOn ? Schedule.dayKey(Date()) : ""
                AlertScheduler.shared.reschedule(completion: nil)
            }
        )
    }

    private var alertsLine: String {
        if alertsThrough > 0 {
            let through = Date(timeIntervalSince1970: alertsThrough)
            return "Alerts set through \(through.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))"
        }
        return "No alerts set. Check that notifications are allowed for School Bell."
    }
}

// MARK: - Top section: what's happening right now

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
                Text(countdown(to: first.startDate(on: now), from: now))
                    .font(.title3.bold())
                    .monospacedDigit()
                Text("\(first.name) · \(Schedule.label(first.startMinutes))")
                    .font(.footnote)
                    .foregroundStyle(first.kind.color)
            }

        case .between(let next):
            VStack(spacing: 2) {
                Text("Next: \(next.name)")
                    .font(.headline)
                    .foregroundStyle(next.kind.color)
                Text("in \(countdown(to: next.startDate(on: now), from: now))")
                    .font(.title3.bold())
                    .monospacedDigit()
            }

        case .inPeriod(let period, let next):
            InPeriodView(period: period, next: next, now: now)
        }
    }
}

struct InPeriodView: View {
    let period: Period
    let next: Period?
    let now: Date

    private var progress: Double {
        let start = period.startDate(on: now)
        let total = period.endDate(on: now).timeIntervalSince(start)
        guard total > 0 else { return 1 }
        return min(max(now.timeIntervalSince(start) / total, 0), 1)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(period.name)
                .font(.headline)
                .foregroundStyle(period.kind.color)
            if !period.room.isEmpty {
                Text(period.room)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(countdown(to: period.endDate(on: now), from: now))
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .monospacedDigit()
            Text("left · ends \(Schedule.label(period.endMinutes))")
                .font(.caption2)
                .foregroundStyle(.secondary)
            ProgressView(value: progress)
                .tint(period.kind.color)
            if let next = next {
                Text("Next: \(next.name)")
                    .font(.footnote)
                    .foregroundStyle(next.kind.color)
            } else {
                Text("Last period")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// "12:34" or "1:02:03"
func countdown(to target: Date, from now: Date) -> String {
    let seconds = max(Int(target.timeIntervalSince(now)), 0)
    let h = seconds / 3600
    let m = (seconds % 3600) / 60
    let s = seconds % 60
    if h > 0 {
        return String(format: "%d:%02d:%02d", h, m, s)
    }
    return String(format: "%d:%02d", m, s)
}
