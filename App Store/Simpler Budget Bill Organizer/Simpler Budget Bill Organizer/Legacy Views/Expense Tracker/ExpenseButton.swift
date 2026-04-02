//import SwiftUI
//import SwiftData

//import SwiftUI
//import SwiftData
//import FoundationModels
//
//// Helper view for pulsing recording glow effect
//private struct PulsingCircle: View {
//    @State private var animate = false
//    var body: some View {
//        Circle()
//            .fill(Color.red.opacity(0.3))
//            .scaleEffect(animate ? 1.5 : 1)
//            .animation(
//                Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true),
//                value: animate
//            )
//            .onAppear { animate = true }
//    }
//}
//
//// MARK: - Entry Mode
//
//enum ExpenseEntryMode: String, CaseIterable {
//    case manual, voice
//}
//
//// MARK: - ExpenseButton
//
//struct ExpenseButton: View {
//    @Environment(SubscriptionController.self) var subscriptionController
//    @Environment(\.modelContext) private var context
//
//    @Binding var isRecording: Bool
//    @Binding var showingPaywall: Bool
//    @Binding var speechRecognizer: SpeechRecognizer
//
//    let allExpenses: [Expense]
//
//    @Query(sort: \Category.name) private var categories: [Category]
//
//    @State private var showManualSheet = false
//    @State private var preferredMode: ExpenseEntryMode? = UserDefaults.standard
//        .string(forKey: "PreferredExpenseEntryMode")
//        .flatMap(ExpenseEntryMode.init)
//    @State private var expanded = false
//
//    // Shared parser injected so the session persists across taps
//    @State private var parser = ExpenseParser()
//
//    var body: some View {
//        ZStack {
//            // Mini manual button
//            if expanded {
//                Button {
//                    withAnimation(.spring()) {
//                        preferredMode = .manual
//                        UserDefaults.standard.set(
//                            ExpenseEntryMode.manual.rawValue,
//                            forKey: "PreferredExpenseEntryMode"
//                        )
//                        expanded = false
//                        showManualSheet = true
//                    }
//                } label: {
//                    Image(systemName: "plus")
//                        .padding(12)
//                        .background(.regularMaterial, in: Circle())
//                        .foregroundStyle(.primary)
//                        .shadow(radius: 2)
//                }
//                .offset(y: -80)
//                .transition(.scale.combined(with: .opacity))
//            }
//
//            // Mini voice button
//            if expanded {
//                Button {
//                    withAnimation(.spring()) {
////                        if subscriptionController.isSubscribed {
//                            preferredMode = .voice
//                            UserDefaults.standard.set(
//                                ExpenseEntryMode.voice.rawValue,
//                                forKey: "PreferredExpenseEntryMode"
//                            )
//                            expanded = false
//                            handleTap()
////                        } else {
////                            showingPaywall = true
////                            expanded = false
////                        }
//                    }
//                } label: {
//                    Image(systemName: "mic.fill")
//                        .padding(12)
//                        .background(.regularMaterial, in: Circle())
//                        .foregroundStyle(.primary)
//                        .shadow(radius: 2)
//                }
//                .offset(x: -80)
//                .transition(.scale.combined(with: .opacity))
//            }
//
//            // Main Button
//            Button {
//                if !expanded { handleTap() }
//            } label: {
//                Image(systemName: preferredModeIcon)
//                    .font(.system(size: 24, weight: .bold))
//                    .foregroundStyle(.white)
//                    .padding(24)
//                    .background(
//                        Circle().fill(isRecording ? Color.red : Color.accentColor)
//                    )
//                    .shadow(radius: 5)
//            }
//            .simultaneousGesture(
//                LongPressGesture(minimumDuration: 0.4)
//                    .onEnded { _ in
//                        withAnimation(.spring()) { expanded.toggle() }
//                    }
//            )
//
//            if isRecording {
//                PulsingCircle()
//                    .frame(width: 110, height: 110)
//                    .zIndex(-1)
//                    .offset(y: 2)
//                VStack {
//                    Spacer().frame(height: 78)
//                    Text("Listening...")
//                        .font(.subheadline.bold())
//                        .foregroundStyle(.red)
//                    if !speechRecognizer.recognizedText.isEmpty {
//                        Text(speechRecognizer.recognizedText)
//                            .font(.caption)
//                            .foregroundStyle(.secondary)
//                            .lineLimit(2)
//                            .truncationMode(.tail)
//                            .multilineTextAlignment(.center)
//                            .padding(.horizontal, 8)
//                    }
//                }
//            }
//        }
//        .sheet(isPresented: $showManualSheet) {
//            ManualEntryView(parser: parser) { expense in
//                save(expense, parsedCategoryString: nil, categories: categories)
//                showManualSheet = false
//            }
//        }
//    }
//
//    // MARK: - Helpers
//
//    private func handleTap() {
//        guard let mode = preferredMode else {
//            withAnimation(.spring()) { expanded = true }
//            return
//        }
//
//        switch mode {
//        case .manual:
//            showManualSheet = true
//
//        case .voice:
//            if isRecording {
//                print("[ExpenseButton] Stop recording.")
//                speechRecognizer.stopRecording()
//                isRecording = false
//
//                // Give the recognition task a moment to finalise
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                    let transcript = speechRecognizer.recognizedText
//                    print("[ExpenseButton] Recognized transcript: '", transcript, "'")
//                    guard !transcript.isEmpty else { return }
//
//                    Task {
//                        if let expense = try? await parser.parse(transcript: transcript) {
//                            // Extract category string from parser result if possible, else nil
//                            // FoundationModels may have a property or method for this;
//                            // since Expense.category might be nil, try get from parser directly:
//                            let parsedCategoryName = try? await parser.suggestCategory(for: transcript)
//                            print("[ExpenseButton] Parsed expense: ", expense)
//                            await MainActor.run {
//                                save(expense, parsedCategoryString: parsedCategoryName, categories: categories)
//                            }
//                        }
//                    }
//                }
//            } else {
//                print("[ExpenseButton] Start recording…")
//                speechRecognizer.requestPermissions { granted in
//                    guard granted else {
//                        print("[ExpenseButton] Permission denied.")
//                        return
//                    }
//                    speechRecognizer.recognizedText = ""
//                    try? speechRecognizer.startRecording()
//                    isRecording = true
//                }
//            }
//        }
//    }
//
//    private func save(_ parsedExpense: Expense, parsedCategoryString: String?, categories: [Category]) {
//        if allExpenses.count >= 14 && !subscriptionController.isSubscribed {
//            showingPaywall = true
//            return
//        }
//        // Ensure vendor
//        let vendor = parsedExpense.vendor.trimmingCharacters(in: .whitespacesAndNewlines)
//        let finalVendor = vendor.isEmpty ? "Unknown" : vendor
//        if vendor.isEmpty { print("[ExpenseButton] Missing vendor, using 'Unknown'") }
//
//        // Ensure category
//        let categoryName = parsedCategoryString?.trimmingCharacters(in: .whitespacesAndNewlines)
//        let matchedCategory = categories.first {
//            $0.name.compare(categoryName ?? "", options: .caseInsensitive) == .orderedSame
//        }
//        var finalCategory: Category? = matchedCategory
//        if finalCategory == nil {
//            // Fallback: find or create "Other" category
//            if let other = categories.first(where: { $0.name.caseInsensitiveCompare("Other") == .orderedSame }) {
//                print("[ExpenseButton] Category not found, using 'Other'")
//                finalCategory = other
//            } else {
//                // Insert a new 'Other' category
//                let newOther = Category(name: "Other", icon: "questionmark.circle")
//                context.insert(newOther)
//                do {
//                    try context.save()
//                } catch {
//                    print("[ExpenseButton] Error saving fallback category: ", error)
//                }
//                print("[ExpenseButton] Created fallback category 'Other'")
//                finalCategory = newOther
//            }
//        }
//
//        let newExpense = Expense(
//            amount: parsedExpense.amount,
//            vendor: finalVendor,
//            date: parsedExpense.date,
//            category: finalCategory
//        )
//        print("[ExpenseButton] Inserting expense: amount=\(newExpense.amount), vendor=\(newExpense.vendor), date=\(newExpense.date), category=\(String(describing: newExpense.category?.name))")
//        context.insert(newExpense)
//        do {
//            try context.save()
//        } catch {
//            print("[ExpenseButton] Error saving context:", error)
//        }
//    }
//
//    private var preferredModeIcon: String {
//        switch preferredMode {
//        case .manual: "plus"
//        case .voice:  isRecording ? "mic.slash.fill" : "mic.fill"
//        case .none:   "ellipsis.circle"
//        }
//    }
//}
//
//// MARK: - ModePickerView
//
//struct ModePickerView: View {
//    @Binding var preferredMode: ExpenseEntryMode?
//    @Environment(\.dismiss) private var dismiss
//
//    var body: some View {
//        NavigationStack {
//            List {
//                ForEach(ExpenseEntryMode.allCases, id: \.self) { mode in
//                    Button {
//                        preferredMode = mode
//                        UserDefaults.standard.set(mode.rawValue, forKey: "PreferredExpenseEntryMode")
//                        dismiss()
//                    } label: {
//                        HStack {
//                            Text(mode == .manual ? "Manual entry" : "Voice entry")
//                                .foregroundStyle(.primary)
//                            Spacer()
//                            if preferredMode == mode {
//                                Image(systemName: "checkmark")
//                                    .foregroundStyle(.accent)
//                            }
//                        }
//                    }
//                }
//            }
//            .navigationTitle("Default entry mode")
//            .navigationBarTitleDisplayMode(.inline)
//        }
//    }
//}
//
//// MARK: - ManualEntryView
//
//struct ManualEntryView: View {
//    let parser: ExpenseParser
//    var onSave: (Expense) -> Void
//
//    @Environment(\.dismiss) private var dismiss
//    @Environment(\.modelContext) private var context
//    @Environment(BudgetController.self) private var budget: BudgetController
//
//    @State private var amount = ""
//    @State private var vendor = ""
//    @State private var date = Date()
//
//    @Query(sort: \Category.name) private var categories: [Category]
//    @State private var selectedCategory: Category?
//
//    // Foundation Models: suggest a category as the user types a vendor name
//    @State private var suggestedCategoryName: String?
//    @State private var suggestionTask: Task<Void, Never>?
//
//    @FocusState private var isInputActive: Bool
//
//    var body: some View {
//        NavigationStack {
//            Form {
//                Section {
//                    TextField("Amount", text: $amount)
//                        .keyboardType(.decimalPad)
//                        .focused($isInputActive)
//
//                    TextField("Vendor", text: $vendor)
//                        .onChange(of: vendor, scheduleCategorySuggestion)
//                }
//
//                Section {
//                    DatePicker("Date", selection: $date, displayedComponents: [.date])
//                }
//
//                Section {
//                    Picker(selection: $selectedCategory) {
//                        Text("None").tag(Optional<Category>.none)
//                        ForEach(categories) { category in
//                            Label {
//                                Text(category.name)
//                            } icon: {
//                                IconView(icon: category.icon)
//                            }
//                            .tag(Optional(category))
//                        }
//                    } label: {
//                        if let selectedCategory {
//                            Label {
//                                Text(selectedCategory.name)
//                            } icon: {
//                                IconView(icon: selectedCategory.icon)
//                            }
//                        } else {
//                            HStack {
//                                Text("Category")
//                                if let suggestion = suggestedCategoryName, selectedCategory == nil {
//                                    Spacer()
//                                    Text("Suggested: \(suggestion)")
//                                        .font(.caption)
//                                        .foregroundStyle(.secondary)
//                                }
//                            }
//                        }
//                    }
//                    .pickerStyle(.navigationLink)
//                }
//            }
//            .navigationTitle("New expense")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .confirmationAction) {
//                    Button("Save") {
//                        let decimalAmount = Decimal(string: amount) ?? 0
//                        let expense = Expense(
//                            amount: decimalAmount,
//                            vendor: vendor,
//                            date: date,
//                            category: selectedCategory
//                        )
//                        budget.checkCategorySpending(categories)
//                        onSave(expense)
//                    }
//                }
//                ToolbarItem(placement: .cancellationAction) {
//                    Button("Cancel") { dismiss() }
//                }
//                ToolbarItem(placement: .keyboard) {
//                    HStack {
//                        Spacer()
//                        Button("Done") { isInputActive = false }
//                    }
//                }
//            }
//        }
//    }
//
//    // Debounce category suggestions so we don't spam the model on every keystroke
//    private func scheduleCategorySuggestion(oldValue: String, newValue: String) {
//        suggestionTask?.cancel()
//        guard newValue.count >= 3 else {
//            suggestedCategoryName = nil
//            return
//        }
//        suggestionTask = Task {
//            try? await Task.sleep(for: .milliseconds(400))
//            guard !Task.isCancelled else { return }
//            let suggestion = try? await parser.suggestCategory(for: newValue)
//            await MainActor.run { suggestedCategoryName = suggestion }
//
//            // Auto-select if the user hasn't chosen one yet and there's a match
//            if let suggestion, selectedCategory == nil {
//                await MainActor.run {
//                    selectedCategory = categories.first { $0.name == suggestion }
//                }
//            }
//        }
//    }
//}

enum ExpenseEntryMode: String, CaseIterable {
    case manual, voice
}

import SwiftUI
import SwiftData

struct ExpenseButton: View {
    @Environment(SubscriptionController.self) var subscriptionController
    @Environment(\.modelContext) private var context
    
    @Binding var isRecording: Bool
    @Binding var showingPaywall: Bool
    @Binding var speechRecognizer: SpeechRecognizer
    
    let allExpenses: [Expense]
    let parseExpense: (String) -> Expense?
    
    @State private var showManualSheet = false
    @State private var preferredMode: ExpenseEntryMode? = UserDefaults.standard.string(forKey: "PreferredExpenseEntryMode").flatMap(ExpenseEntryMode.init)
    @State private var expanded = false
    
    var body: some View {
        ZStack {
            // Mini manual button
            if expanded {
                Button {
                    withAnimation {
                        preferredMode = .manual
                        UserDefaults.standard.set(ExpenseEntryMode.manual.rawValue, forKey: "PreferredExpenseEntryMode")
                        expanded = false
                        showManualSheet = true
                    }
                } label: {
                    Image(systemName: "plus")
                        .padding(12)
                        .background(Circle().fill(Color.accentColor))
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                }
                .offset(y: -80)
                .transition(.scale.combined(with: .opacity))
            }
            
            // Mini voice button
            if expanded {
                Button {
                    withAnimation {
                        if subscriptionController.isSubscribed {
                            preferredMode = .voice
                            UserDefaults.standard.set(ExpenseEntryMode.voice.rawValue, forKey: "PreferredExpenseEntryMode")
                            expanded = false
                            handleTap()
                        } else {
                            showingPaywall = true
                            expanded = false
                        }
                        
                    }
                } label: {
                    Image(systemName: "mic.fill")
                        .padding(12)
                        .background(Circle().fill(Color.accentColor))
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                }
                .offset(x: -80)
                .transition(.scale.combined(with: .opacity))
            }
            
            // Main Button
            Button(action: {
                if !expanded {
                    handleTap()
                }
            }) {
                Image(systemName: preferredModeIcon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding(24)
                    .background(Circle().fill(isRecording ? Color.red : Color.accentColor))
                    .shadow(radius: 5)
            }
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.4)
                    .onEnded { _ in
                        withAnimation(.spring()) {
                            expanded.toggle()
                        }
                    }
            )
        }
        .sheet(isPresented: $showManualSheet) {
            ManualEntryView { expense in
                if allExpenses.count >= 14 && !subscriptionController.isSubscribed {
                    showingPaywall = true
                } else {
                    context.insert(expense)
                    try? context.save()
                }
                showManualSheet = false
            }
        }
    }
    
    private func handleTap() {
        guard let mode = preferredMode else {
            expanded = true
            return
        }
        
        switch mode {
        case .manual:
            showManualSheet = true
        case .voice:
            if isRecording {
                speechRecognizer.stopRecording()
                isRecording = false
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let recognized = speechRecognizer.recognizedText
                    if let expense = parseExpense(recognized) {
                        if allExpenses.count >= 14 && !subscriptionController.isSubscribed {
                            showingPaywall = true
                        } else {
                            context.insert(expense)
                            try? context.save()
                        }
                    }
                }
            } else {
                speechRecognizer.requestPermissions { granted in
                    if granted {
                        speechRecognizer.recognizedText = ""
                        try? speechRecognizer.startRecording()
                        isRecording = true
                    }
                }
            }
        }
    }
    
    private var preferredModeIcon: String {
        switch preferredMode {
        case .manual: return "plus"
        case .voice: return isRecording ? "mic.slash.fill" : "mic.fill"
        case .none: return "ellipsis.circle"
        }
    }
}




struct ModePickerView: View {
    @Binding var preferredMode: ExpenseEntryMode?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(ExpenseEntryMode.allCases, id: \.self) { mode in
                    Button {
                        preferredMode = mode
                        UserDefaults.standard.set(mode.rawValue, forKey: "PreferredExpenseEntryMode")
                        dismiss()
                    } label: {
                        HStack {
                            Text(mode == .manual ? "Manual Entry" : "Voice Entry")
                            Spacer()
                            if preferredMode == mode {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Choose Default Entry")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}


struct ManualEntryView: View {
    var onSave: (Expense) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(BudgetController.self) private var budget: BudgetController
    
    @State private var amount = ""
    @State private var vendor = ""
    @State private var date = Date() // Default to now
    
    @Query(sort: \Category.name) private var categories: [Category]
    @State private var selectedCategory: Category? = nil
    @FocusState var isInputActive: Bool
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Amount", text: $amount)
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
                
                TextField("Vendor", text: $vendor)
                
                DatePicker("Date", selection: $date, displayedComponents: [.date])
                
                // Category Picker
                Picker(selection: $selectedCategory) {
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
                    if let selectedCategory = selectedCategory {
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
            }
            .padding(.top)
            .navigationTitle("New Expense")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let decimalAmount = Decimal(string: amount) ?? 0
                        let expense = Expense(
                            amount: decimalAmount,
                            vendor: vendor,
                            date: date, // Use selected date
                            category: selectedCategory
                        )
                        
                        budget.checkCategorySpending(categories)
                        onSave(expense)
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}


