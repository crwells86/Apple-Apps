import SwiftUI
import SwiftData
import UserNotifications

struct TransactionFormView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Binding var bill: Transaction
    var onSave: () -> Void
    var onCancel: () -> Void
    
    @Query(sort: \Category.name) private var categories: [Category]
    @State private var showAddCategory = false
    @FocusState var isInputActive: Bool
    
    var body: some View {
        Form {
            Section("Details") {
                TextField("Name", text: $bill.name)
                
                TextField("Amount", value: $bill.amount, format: .currency(code: bill.currencyCode))
                    .keyboardType(.decimalPad)
                    .focused($isInputActive)
                    .toolbar {
                        ToolbarItem(placement: .keyboard) {
                            HStack {
                                Spacer()
                                
                                Button("Done") {
                                    isInputActive = false
                                }
                            }
                            .padding(.trailing)
                        }
                    }
                
                // Category Picker
                Picker(selection: $bill.category) {
                    Text("None").tag(Optional<Category>.none)
                    
                    ForEach(categories) { category in
                        Label {
                            Text(category.name)
                        } icon: {
                            IconView(icon: category.icon)
                        }
                        .tag(Optional(category))
                    }
                } label: {
                    if let selectedCategory = bill.category {
                        Label {
                            Text(selectedCategory.name)
                        } icon: {
                            IconView(icon: selectedCategory.icon)
                        }
                    } else {
                        Text("Select Category")
                    }
                }
                .pickerStyle(.navigationLink)
                
                
                Button("Add Category") {
                    showAddCategory = true
                }
                .sheet(isPresented: $showAddCategory) {
                    AddCategorySheet { newCategory in
                        bill.category = newCategory
                        showAddCategory = false
                    }
                }
                
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
                    checkCategorySpending(categories)
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
    
    func checkCategorySpending(_ categories: [Category]) {
        for category in categories where category.enableReminders {
            guard let limit = category.limit else { continue }
            let totalSpent = spending(for: category)

            let percentUsed = (NSDecimalNumber(decimal: totalSpent).doubleValue /
                               NSDecimalNumber(decimal: limit).doubleValue)

            if percentUsed >= 1.0 {
                scheduleNotification(
                    title: "\(category.name) Budget Exceeded",
                    body: "You've exceeded your budget for \(category.name)."
                )
            } else if percentUsed >= 0.9 {
                scheduleNotification(
                    title: "\(category.name) Budget Warning",
                    body: "You're close to your budget limit for \(category.name)."
                )
            }
        }
    }
    
    func spending(for category: Category) -> Decimal {
        let expenseTotal = category.expenses.reduce(0) { $0 + $1.amount }
        let transactionTotal = category.transactions.reduce(0) { $0 + $1.amount }
        return expenseTotal + Decimal(transactionTotal)
    }
    
    func scheduleNotification(title: String, body: String) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled: \(title)")
            }
        }
    }
}
