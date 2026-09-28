//
//  RemindersSettingsView.swift
//  MacroPal
//

import SwiftUI
import SwiftData
import UserNotifications

/// Profile → Reminders: a switch and a time for each daily reminder (see `Reminder`). Turning
/// one on asks for notification permission; any change reschedules them.
struct RemindersSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    @State private var notificationsDenied = false

    var body: some View {
        Form {
            Section {
                row(.steps)
                row(.weight)
            } header: {
                Text("Steps & Weight")
            }

            Section {
                row(.breakfast)
                row(.lunch)
                row(.dinner)
            } header: {
                Text("Food")
            } footer: {
                Text("A reminder is skipped on days you've already logged it. Food reminders start at the end of each meal's time frame.")
            }

            if notificationsDenied {
                Section {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                            openURL(url)
                        }
                    }
                } footer: {
                    Text("Notifications are off for MacroPal, so reminders can't be shown. Turn them on in Settings.")
                }
            }
        }
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
            notificationsDenied = status == .denied && Reminder.allCases.contains { $0.isEnabled(in: .standard) }
        }
    }

    private func row(_ reminder: Reminder) -> some View {
        ReminderRow(reminder: reminder, onTurnOn: requestPermission, onChange: reschedule)
    }

    /// Asks the first time a reminder is turned on; afterwards the system just answers with the
    /// stored choice.
    private func requestPermission() async -> Bool {
        let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
        notificationsDenied = !granted
        return granted
    }

    private func reschedule() {
        Task {
            await ReminderScheduler.reschedule(in: modelContext)
        }
    }
}

/// One reminder's switch, and its time once it's on.
private struct ReminderRow: View {
    let reminder: Reminder
    let onTurnOn: () async -> Bool
    let onChange: () -> Void

    @AppStorage private var isOn: Bool
    @AppStorage private var minute: Int

    init(reminder: Reminder, onTurnOn: @escaping () async -> Bool, onChange: @escaping () -> Void) {
        self.reminder = reminder
        self.onTurnOn = onTurnOn
        self.onChange = onChange
        _isOn = AppStorage(wrappedValue: false, reminder.enabledKey)
        _minute = AppStorage(wrappedValue: reminder.defaultMinute, reminder.minuteKey)
    }

    /// The stored minutes after midnight, as a time today for the picker.
    private var time: Binding<Date> {
        Binding(
            get: { Calendar.current.date(byAdding: .minute, value: minute, to: Calendar.current.startOfDay(for: .now)) ?? .now },
            set: { date in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                minute = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
            }
        )
    }

    var body: some View {
        Toggle(isOn: $isOn) {
            Label(reminder.title, systemImage: reminder.systemImage)
        }
        .onChange(of: isOn) { _, newValue in
            guard newValue else { return onChange() }
            Task {
                if await onTurnOn() {
                    onChange()
                } else {
                    isOn = false
                }
            }
        }
        if isOn {
            DatePicker("Time", selection: time, displayedComponents: .hourAndMinute)
                .padding(.leading, 36)
                .onChange(of: minute) { onChange() }
        }
    }
}

#Preview {
    NavigationStack {
        RemindersSettingsView()
    }
    .modelContainer(for: AppSchema.models, inMemory: true)
}
