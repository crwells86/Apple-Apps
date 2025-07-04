import SwiftUI
import SwiftData

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
    
    @State private var amount = ""
    @State private var vendor = ""
    @State private var selectedCategory: ExpenseCategory = .miscellaneous
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
                TextField("Vendor", text: $vendor)
                Picker("Category", selection: $selectedCategory) {
                    ForEach(ExpenseCategory.allCases) { category in
                        Text(category.label)
                            .tag(category)
                    }
                }
            }
            .navigationTitle("New Expense")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let decimalAmount = Decimal(string: amount) ?? 0
                        let expense = Expense(
                            amount: decimalAmount,
                            vendor: vendor,
                            date: .now,
                            category: selectedCategory
                        )
                        onSave(expense)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
