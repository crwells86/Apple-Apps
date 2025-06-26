import SwiftUI
import UserNotifications

struct TransactionFormView: View {
    @Binding var bill: Transaction
    var onSave: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        Form {
            Section("Details") {
                TextField("Name", text: $bill.name)
                
                TextField("Amount", value: $bill.amount, format: .currency(code: bill.currencyCode))
                    .keyboardType(.decimalPad)
                
                // Category Picker
                Picker("Category", selection: $bill.category) {
                    ForEach(ExpenseCategory.allCases, id: \.self) { category in
                        HStack {
                            category.icon
                            Text(category.label)
                        }
                        .tag(category)
                    }
                }
                .pickerStyle(.menu)
                
                // Frequency Picker
                Picker("Frequency", selection: $bill.frequency) {
                    ForEach(BillFrequency.allCases, id: \.self) { freq in
                        Text(freq.displayName).tag(freq)
                    }
                }
                .pickerStyle(.menu)
            }
            
            Section("Timing") {
                Toggle("Remind Me", isOn: $bill.remindMe)
                
                if bill.remindMe {
                    Picker("Day of Month", selection: $bill.remindDay) {
                        ForEach(1..<32, id: \.self) { day in
                            Text("\(day)").tag(Optional(day))
                        }
                    }
                    .onChange(of: bill.remindDay) {
                        updateDueDate()
                    }
                    
                    DatePicker(
                        "Time of Day",
                        selection: Binding<Date>(
                            get: {
                                let comps = DateComponents(
                                    hour: bill.remindHour ?? 9,
                                    minute: bill.remindMinute ?? 0
                                )
                                return Calendar.current.date(from: comps) ?? Date()
                            },
                            set: { newDate in
                                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                                bill.remindHour = comps.hour
                                bill.remindMinute = comps.minute
                                updateDueDate()
                            }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                }
            }
        }
        .navigationTitle("New Bill")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: onCancel)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    scheduleNotification(for: bill)
                    onSave()
                }
            }
        }
    }
    
    private func updateDueDate() {
        let calendar = Calendar.current
        let now = Date()
        let components = DateComponents(
            year: calendar.component(.year, from: now),
            month: calendar.component(.month, from: now),
            day: bill.remindDay ?? 1,
            hour: bill.remindHour ?? 9,
            minute: bill.remindMinute ?? 0
        )
        
        guard let proposed = calendar.date(from: components) else { return }
        
        if proposed >= now {
            bill.dueDate = proposed
            return
        }
        
        // Use frequency's dateComponents to calculate next due date
        let step = bill.frequency.dateComponents
        
        // If step is empty (oneTime), just use proposed
        if step == DateComponents() {
            bill.dueDate = proposed
            return
        }
        
        // Add recurrence interval until the new due date is in the future
        var nextDueDate = proposed
        while nextDueDate < now {
            if let newDate = calendar.date(byAdding: step, to: nextDueDate) {
                nextDueDate = newDate
            } else {
                break // fallback, to avoid infinite loop
            }
        }
        
        bill.dueDate = nextDueDate
    }

    
    private func scheduleNotification(for bill: Transaction) {
        guard
            let day    = bill.remindDay,
            let hour   = bill.remindHour,
            let minute = bill.remindMinute
        else { return }
        
        let content = UNMutableNotificationContent()
        content.title = bill.name
        content.body  = "Reminder: \(bill.name) is due today."
        content.sound = .default
        
        var comps = DateComponents(hour: hour, minute: minute)
        switch bill.frequency {
        case .monthly:
            comps.day = day
        case .weekly:
            comps.weekday = day
        default:
            return
        }
        
        let trigger  = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request  = UNNotificationRequest(
            identifier: bill.id.uuidString,
            content:    content,
            trigger:    trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
}

#Preview {
    @Previewable @State var bill = Transaction(
        name: "Xfinity Internet",
        amount: 79.99,
        frequency: .monthly,
        category: .utilities,
        dueDate: Calendar.current.date(from: DateComponents(year: 2025, month: 5, day: 20)),
        isAutoPaid: true,
        notes: "Home internet plan, 800 Mbps.",
        startDate: Calendar.current.date(from: DateComponents(year: 2023, month: 2, day: 1)),
        endDate: nil,
        vendor: "Xfinity",
        isActive: true,
        tags: ["internet", "home"],
        currencyCode: "USD",
        remindMe: true,
        remindDay: 19,
        remindHour: 9,
        remindMinute: 0
    )
    
    TransactionFormView(
        bill: $bill,
        onSave:  {},
        onCancel: {}
    )
}
