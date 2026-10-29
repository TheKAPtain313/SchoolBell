import SwiftUI

// MARK: - List of periods

struct SettingsView: View {
    @ObservedObject private var store = ScheduleStore.shared
    @State private var confirmReset = false

    var body: some View {
        List {
            Section {
                ForEach(store.periods) { period in
                    NavigationLink {
                        PeriodEditView(period: period, isNew: false)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(period.name)
                                .font(.headline)
                                .foregroundStyle(period.kind.color)
                            Text("\(Schedule.label(period.startMinutes)) – \(Schedule.label(period.endMinutes))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Periods")
            } footer: {
                Text("Classes get alerts at 20, 10, and 5 min left. Recess and lunch don't.")
            }

            Section {
                NavigationLink {
                    PeriodEditView(period: newPeriod(), isNew: true)
                } label: {
                    Label("Add period", systemImage: "plus")
                }

                Button(role: .destructive) {
                    confirmReset = true
                } label: {
                    Label("Reset to default", systemImage: "arrow.counterclockwise")
                }
            }
        }
        .navigationTitle("Settings")
        .confirmationDialog("Reset all periods to the original schedule?", isPresented: $confirmReset) {
            Button("Reset", role: .destructive) { store.resetToDefault() }
            Button("Cancel", role: .cancel) {}
        }
    }

    /// A new period that starts when the last one ends.
    private func newPeriod() -> Period {
        let start = min(store.periods.last?.endMinutes ?? Schedule.m(8, 0), Schedule.m(23, 0))
        return Period(name: "New Class", room: "", startMinutes: start, endMinutes: min(start + 60, Schedule.m(23, 59)), kind: .classPeriod)
    }
}

// MARK: - Edit one period

struct PeriodEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Period
    private let isNew: Bool

    init(period: Period, isNew: Bool) {
        _draft = State(initialValue: period)
        self.isNew = isNew
    }

    private var isValid: Bool {
        draft.endMinutes > draft.startMinutes && !draft.name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        List {
            Section("Name") {
                TextField("Name", text: $draft.name)
                TextField("Room (optional)", text: $draft.room)
            }

            Section("Type") {
                Picker("Type", selection: $draft.kind) {
                    ForEach(Period.Kind.allCases, id: \.self) { kind in
                        Text(kind.label).tag(kind)
                    }
                }
            }

            Section("Starts · \(Schedule.label(draft.startMinutes))") {
                TimeWheel(minutes: $draft.startMinutes)
            }

            Section("Ends · \(Schedule.label(draft.endMinutes))") {
                TimeWheel(minutes: $draft.endMinutes)
            }

            Section {
                if draft.endMinutes <= draft.startMinutes {
                    Text("End time has to be after start time.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Button {
                    draft.name = draft.name.trimmingCharacters(in: .whitespaces)
                    draft.room = draft.room.trimmingCharacters(in: .whitespaces)
                    ScheduleStore.shared.save(draft)
                    dismiss()
                } label: {
                    Label("Save", systemImage: "checkmark")
                }
                .disabled(!isValid)

                if !isNew {
                    Button(role: .destructive) {
                        ScheduleStore.shared.delete(draft)
                        dismiss()
                    } label: {
                        Label("Delete period", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle(isNew ? "New period" : "Edit")
    }
}

// MARK: - Hour + minute wheels (turn with the Digital Crown)

struct TimeWheel: View {
    @Binding var minutes: Int

    private var hour: Binding<Int> {
        Binding(get: { minutes / 60 }, set: { minutes = $0 * 60 + minutes % 60 })
    }

    private var minute: Binding<Int> {
        Binding(get: { minutes % 60 }, set: { minutes = (minutes / 60) * 60 + $0 })
    }

    var body: some View {
        HStack(spacing: 4) {
            Picker("Hour", selection: hour) {
                ForEach(0..<24, id: \.self) { h in
                    Text(hourLabel(h)).tag(h)
                }
            }
            .pickerStyle(.wheel)

            Picker("Minute", selection: minute) {
                ForEach(0..<60, id: \.self) { m in
                    Text(String(format: "%02d", m)).tag(m)
                }
            }
            .pickerStyle(.wheel)
        }
        .frame(height: 70)
    }

    private func hourLabel(_ h: Int) -> String {
        let h12 = h % 12 == 0 ? 12 : h % 12
        return "\(h12) \(h < 12 ? "AM" : "PM")"
    }
}
