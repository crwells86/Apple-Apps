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
                            iconView(for: category.icon)
                        }
                        .tag(Optional(category))
                    }
                } label: {
                    if let selectedCategory = bill.category {
                        Label {
                            Text(selectedCategory.name)
                        } icon: {
                            iconView(for: selectedCategory.icon)
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
    
    @ViewBuilder
    func iconView(for icon: String) -> some View {
        if UIImage(systemName: icon) != nil {
            Image(systemName: icon)
        } else {
            Text(icon)
        }
    }
}




import SwiftUI
import SwiftData

enum CategoryViewMode: String, CaseIterable {
    case select = "Select"
    case manage = "Manage"
}

struct AddCategorySheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var selectedIcon: String = ""
    @State private var categoryMode: CategoryViewMode = .select
    @Query(sort: \Category.name) private var categories: [Category]
    @State private var showingEmojiPicker = false
    
    @State private var limit: Decimal?
    @State private var enableReminders: Bool = false
    @FocusState var isInputActive: Bool
    
    var onAdd: (Category) -> Void
    
    private let iconOptions: [String] = [
        "house", "car", "bus", "airplane", "tram", "bicycle", "fuelpump", "ev.charger", "bag", "cart", "creditcard", "wallet.pass", "gift", "heart", "star", "person", "person.3", "figure.walk", "figure.run", "figure.stand", "figure.wave", "globe", "location", "map", "mappin", "flag", "calendar", "alarm", "envelope", "phone", "message", "camera", "video", "mic", "music.note", "headphones", "tv", "display", "laptopcomputer", "ipad", "iphone", "applewatch", "gamecontroller", "keyboard", "printer", "externaldrive", "folder", "doc.text", "doc.richtext", "book", "books.vertical", "newspaper", "highlighter", "scissors", "paintbrush", "hammer", "wrench", "screwdriver", "shippingbox", "building.2", "banknote", "dollarsign", "bitcoinsign.circle", "sterlingsign.circle", "eurosign.circle", "yensign.circle", "indianrupeesign.circle", "flame", "leaf", "moon", "cloud.sun", "cloud.rain", "bolt", "thermometer", "eyeglasses", "cross.case", "bandage", "pills", "cross", "lungs", "heart.text.square", "tree"
    ]

    
    var body: some View {
        NavigationStack {
            Form {
                Picker("Mode", selection: $categoryMode) {
                    ForEach(CategoryViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                
                switch categoryMode {
                case .select:
                    addCategoryForm
                case .manage:
                    manageCategoriesList
                }
            }
            .padding(.top)
            .navigationTitle(categoryMode == .select ? "New Category" : "Manage Categories")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }
                if categoryMode == .select {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add", action: addCategory)
                            .disabled(name.isEmpty || selectedIcon.isEmpty)
                    }
                }
            }
        }
    }
    
    // MARK: - Add Mode View
    
    private var addCategoryForm: some View {
        Group {
            Section {
                TextField("Category Name", text: $name)
            }
            
            Section("Budget Limit") {
                TextField("Enter Limit", value: $limit, format: .number)
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

                Toggle("Enable Reminders", isOn: $enableReminders)
            }

            Section("Icon") {
                HStack {
                    Text("Emoji Icon")
                    Spacer()
                    Button {
                        showingEmojiPicker = true
                    } label: {
                        if selectedIcon.isEmpty {
                            Text("Pick")
                                .foregroundStyle(.blue)
                        } else {
                            Text(selectedIcon)
                                .font(.title2)
                        }
                    }
                }
                .sheet(isPresented: $showingEmojiPicker) {
                    EmojiPickerView(selectedEmoji: $selectedIcon)
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6)) {
                    ForEach(iconOptions, id: \.self) { icon in
                        IconButton(icon: icon, isSelected: icon == selectedIcon) {
                            selectedIcon = icon
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Manage Mode View
    private func filterToSingleEmoji(_ input: String) -> String {
        let scalars = input.unicodeScalars
        if input.count <= 2, scalars.allSatisfy({ $0.properties.isEmoji }) {
            return input
        } else {
            return String(input.prefix(1).filter { $0.isEmoji })
        }
    }

    
    private var manageCategoriesList: some View {
        List {
            ForEach(categories) { category in
                HStack {
                    iconView(for: category.icon)
                    VStack(alignment: .leading) {
                        Text(category.name)
                        if let limit = category.limit {
                            Text("Limit: \(limit.formatted(.currency(code: "USD")))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
//                    Button {
//                        showEditCategory(category)
//                    } label: {
//                        Image(systemName: "pencil")
//                    }
//                    .buttonStyle(.borderless)
                }
            }
            .onDelete(perform: deleteCategory)
        }
    }
    
    // MARK: - Helpers
    private func addCategory() {
        let newCategory = Category(name: name, icon: selectedIcon, limit: limit)
        newCategory.isDefault = false
        newCategory.enableReminders = enableReminders
        modelContext.insert(newCategory)
        onAdd(newCategory)
    }
    
    private func deleteCategory(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(categories[index])
        }
    }
    
    private func showEditCategory(_ category: Category) {
        // TODO: Present edit UI
    }
    
    @ViewBuilder
    private func iconView(for icon: String) -> some View {
        if UIImage(systemName: icon) != nil {
            Image(systemName: icon)
        } else {
            Text(icon)
        }
    }
    
    //MARK: - Notifications/Reminders
    // ?

    // ?

    // ?
}

import UserNotifications

struct IconButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                }
                
                Group {
                    if icon.allSatisfy({ $0.isEmoji }) {
                        Text(icon)
                            .font(.title)
                    } else {
                        Image(systemName: icon)
                            .font(.title2)
                    }
                }
            }
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
    }
}


struct EmojiPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedEmoji: String

    // A simplified emoji list (you can expand this)
    private let allEmojis: [String] = {
        // Unicode emoji ranges (simplified)
        let ranges: [ClosedRange<Int>] = [
            0x1F600...0x1F64F, // Emoticons
            0x1F300...0x1F5FF, // Misc symbols and pictographs
            0x1F680...0x1F6FF, // Transport and map symbols
            0x2600...0x26FF,   // Misc symbols
            0x2700...0x27BF    // Dingbats
        ]

        return ranges.flatMap { range in
            range.compactMap {
                guard let scalar = UnicodeScalar($0), scalar.properties.isEmoji else { return nil }
                return String(scalar)
            }
        }
    }()

    private let columns = Array(repeating: GridItem(.flexible()), count: 6)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(allEmojis, id: \.self) { emoji in
                        Button {
                            selectedEmoji = emoji
                            dismiss()
                        } label: {
                            Text(emoji)
                                .font(.largeTitle)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Pick an Emoji")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}


extension Character {
    var isEmoji: Bool {
        unicodeScalars.first?.properties.isEmojiPresentation == true ||
        unicodeScalars.contains(where: { $0.properties.isEmoji })
    }
}

