import SwiftUI

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
                
                Picker("Category", selection: $bill.category) {
                    ForEach(ExpenseCategory.allCases) { category in
                        HStack {
                            category.icon
                            Text(category.label)
                        }
                        .tag(category)
                    }
                }
                .pickerStyle(.menu)
                
                Picker("Frequency", selection: $bill.frequency) {
                    ForEach(BillFrequency.allCases) { freq in
                        Text(freq.label).tag(freq)
                    }
                }
                .pickerStyle(.menu)
            }
            
            Section("Timing") {
                Toggle("Remind Me", isOn: $bill.remindMe)
                
                if bill.remindMe {
                    Picker("Day of Month", selection: $bill.remindDay) {
                        ForEach(1..<32) { day in
                            Text("\(day)").tag(day as Int?)
                        }
                    }
                    .onChange(of: bill.remindDay) {
                        updateDueDate()
                    }
                    
                    DatePicker("Time of Day", selection: Binding<Date>(
                        get: {
                            let components = DateComponents(hour: bill.remindHour ?? 9, minute: bill.remindMinute ?? 0)
                            return Calendar.current.date(from: components) ?? Date()
                        },
                        set: { newDate in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                            let now = Date()
                            let calendar = Calendar.current
                            
                            bill.remindHour = components.hour
                            bill.remindMinute = components.minute
                            
                            var dateComps = DateComponents()
                            dateComps.day = bill.remindDay ?? 1
                            dateComps.month = calendar.component(.month, from: now)
                            dateComps.year = calendar.component(.year, from: now)
                            dateComps.hour = components.hour
                            dateComps.minute = components.minute
                            
                            guard let proposedDate = calendar.date(from: dateComps) else { return }
                            
                            if proposedDate < now {
                                if let nextMonthDate = calendar.date(byAdding: .month, value: 1, to: proposedDate) {
                                    bill.dueDate = nextMonthDate
                                } else {
                                    bill.dueDate = proposedDate
                                }
                            } else {
                                bill.dueDate = proposedDate
                            }
                        }
                    ), displayedComponents: .hourAndMinute)
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
    
    func updateDueDate() {
        let calendar = Calendar.current
        let now = Date()
        
        var dateComps = DateComponents()
        dateComps.day = bill.remindDay ?? 1
        dateComps.month = calendar.component(.month, from: now)
        dateComps.year = calendar.component(.year, from: now)
        dateComps.hour = bill.remindHour ?? 9
        dateComps.minute = bill.remindMinute ?? 0
        
        guard let proposedDate = calendar.date(from: dateComps) else { return }
        
        if proposedDate < now {
            if let nextMonthDate = calendar.date(byAdding: .month, value: 1, to: proposedDate) {
                bill.dueDate = nextMonthDate
            } else {
                bill.dueDate = proposedDate
            }
        } else {
            bill.dueDate = proposedDate
        }
    }
    
    func scheduleNotification(for bill: Transaction) {
        guard let day = bill.remindDay,
              let hour = bill.remindHour,
              let minute = bill.remindMinute else { return }
        
        let content = UNMutableNotificationContent()
        content.title = bill.name
        content.body = "Reminder: \(bill.name) is due today."
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        switch bill.frequency {
        case .monthly:
            dateComponents.day = day
        case .weekly:
            dateComponents.weekday = day
        default:
            return
        }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: bill.id.uuidString,
            content: content,
            trigger: trigger
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
    
    TransactionFormView(bill: $bill)  {
        // onSave logic here
    } onCancel: {
        // onCancel logic here
    }
}
