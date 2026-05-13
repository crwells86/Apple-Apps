// Requirements: iOS 26+, FoundationModels, SwiftData, UserNotifications
// Zero network calls – entirely on-device via Apple Intelligence.

import Foundation
import FoundationModels
import SwiftData
import SwiftUI
import UserNotifications
import Observation

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Structured intent types
//
// Every property the model fills in is a concrete Swift type, not a raw String.
// This is the key fix: the model does the hard NL→structured work so our Swift
// code never has to parse "every 3rd Thursday" by hand.
// ─────────────────────────────────────────────────────────────────────────────

/// The weekday a bill falls on (Calendar weekday numbering: 1 = Sunday).
@available(iOS 26.0, *)
@Generable
enum BillWeekday: Int {
    case sunday    = 1
    case monday    = 2
    case tuesday   = 3
    case wednesday = 4
    case thursday  = 5
    case friday    = 6
    case saturday  = 7
}

/// How a due date is expressed.
@available(iOS 26.0, *)
@Generable
enum DueRule {
    /// A fixed calendar day each period, e.g. "the 19th".
    case dayOfMonth(DayOfMonthRule)
    /// An Nth weekday of the month, e.g. "3rd Thursday".
    case nthWeekday(NthWeekdayRule)
    /// No specific date – just use today as a placeholder.
    case unspecified
}

@available(iOS 26.0, *)
@Generable
struct DayOfMonthRule {
    @Guide(description: "Day of the month (1–31)")
    let day: Int
}

@available(iOS 26.0, *)
@Generable
struct NthWeekdayRule {
    @Guide(description: "Which occurrence in the month: 1=first, 2=second, 3=third, 4=fourth, 5=last")
    let weekOfMonth: Int
    
    @Guide(description: "The weekday: 1=Sunday, 2=Monday, 3=Tuesday, 4=Wednesday, 5=Thursday, 6=Friday, 7=Saturday")
    let weekday: BillWeekday
}

@available(iOS 26.0, *)
/// Strongly-typed frequency – mirrors BillFrequency.rawValue exactly.
@Generable
enum IntentFrequency: String {
    case oneTime
    case daily
    case weekly
    case biweekly
    case semiMonthly
    case monthly
    case biMonthly
    case quarterly
    case semiAnnual
    case yearly
    
    var billFrequency: BillFrequency {
        BillFrequency(rawValue: self.rawValue) ?? .monthly
    }
}

@available(iOS 26.0, *)
/// Income frequency – mirrors Frequency.rawValue.
@Generable
enum IntentIncomeFrequency: String {
    case weekly
    case biweekly
    case monthly
    case variable
    
    var frequency: Frequency {
        Frequency(rawValue: self.rawValue) ?? .variable
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Input structs
// ─────────────────────────────────────────────────────────────────────────────
@available(iOS 26.0, *)
@Generable
struct ExpenseInput {
    @Guide(description: "Dollar amount spent, as a positive number")
    let amount: Double
    
    @Guide(description: "The store, restaurant, or service where money was spent")
    let vendor: String
    
    @Guide(description: "Category: Housing, Transportation, Food, Utilities, Insurance, Healthcare, Entertainment, Personal Care, Education, Savings, Debt, Gifts & Donations, Travel, Subscriptions, or Miscellaneous")
    let category: String
}

@available(iOS 26.0, *)
@Generable
struct BillInput {
    @Guide(description: "Name of the bill or subscription")
    let name: String
    
    @Guide(description: "Dollar amount of the bill, as a positive number")
    let amount: Double
    
    @Guide(description: "How often the bill recurs")
    let frequency: IntentFrequency
    
    @Guide(description: "When in the billing period this bill is due")
    let dueRule: DueRule
    
    @Guide(description: "Vendor or payee name, if mentioned; otherwise empty string")
    let vendor: String
}

@available(iOS 26.0, *)
@Generable
struct IncomeInput {
    @Guide(description: "Dollar amount earned, as a positive number")
    let amount: Double
    
    @Guide(description: "Where the money came from: job name, client, app, etc.")
    let source: String
    
    @Guide(description: "How often this income recurs")
    let frequency: IntentIncomeFrequency
}

@available(iOS 26.0, *)
/// The question type so we can dispatch to the right answer logic.
@Generable
enum QuestionKind {
    /// How much was spent today.
    case spentToday
    /// How much was spent this week (Mon–today).
    case spentThisWeek
    /// How much was spent this month.
    case spentThisMonth
    /// How much income is needed today to cover upcoming bills.
    case neededToday
    /// How much income is needed this week to cover upcoming bills.
    case neededThisWeek
    /// Remaining monthly budget.
    case remainingBudget
    /// Total income logged.
    case totalIncome
    /// A general question the model should answer with the data summary.
    case general
}

@available(iOS 26.0, *)
@Generable
struct QuestionInput {
    let kind: QuestionKind
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Top-level intent
// ─────────────────────────────────────────────────────────────────────────────

@available(iOS 26.0, *)
@Generable
enum FinanceIntent {
    /// User logged a one-off expense.
    case addExpense(ExpenseInput)
    /// User logged income.
    case addIncome(IncomeInput)
    /// User is adding a recurring bill or subscription.
    case addBill(BillInput)
    /// User asked a financial question.
    case question(QuestionInput)
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Pending state for multi-turn flows (e.g. reminder confirmation)
// ─────────────────────────────────────────────────────────────────────────────

private enum PendingAction {
    case awaitingReminderConfirmation(Transaction)
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - FinanceChatController
// ─────────────────────────────────────────────────────────────────────────────
@available(iOS 26.0, *)
@Observable
@MainActor
final class FinanceChatController {
    
    struct Message: Identifiable {
        let id = UUID()
        let text: String
        let isUser: Bool
    }
    
    // Published state
    var messages: [Message] = []
    var isLoading = false
    
    // Dependencies
    private let modelContext: ModelContext
    private let budgetController: BudgetController
    
    // Two sessions: one for extraction, one for friendly replies.
    // Keeping them separate prevents the extraction session's structured
    // generation from being polluted by conversational history.
    private let extractionSession: LanguageModelSession
    private let replySession: LanguageModelSession
    
    // Multi-turn state
    private var pendingAction: PendingAction?
    
    // ── Init ──────────────────────────────────────────────────────────────────
    
    init(context: ModelContext, budgetController: BudgetController) {
        self.modelContext = context
        self.budgetController = budgetController
        
        // Session 1: intent extraction only – no chat history needed
        let extractionInstructions = Instructions {
            """
            You are a financial data extraction engine.
            Your ONLY job is to classify the user message into one of four intents
            and fill in the structured fields precisely.
            
            Intent rules:
            - addExpense: user spent money on something (one-time purchase or payment)
            - addIncome:  user received or earned money
            - addBill:    user is adding a recurring bill, subscription, or regular payment
            - question:   user is asking about their financial situation
            
            For addBill frequency:
              "every other month" or "bi-monthly" → biMonthly
              "every month" / "monthly"            → monthly
              "every week" / "weekly"              → weekly
              "every two weeks" / "biweekly"       → biweekly
              "twice a month" / "semi-monthly"     → semiMonthly
              "every 3 months" / "quarterly"       → quarterly
              "every 6 months" / "semi-annual"     → semiAnnual
              "once a year" / "yearly" / "annual"  → yearly
              "one time" / "one-off"               → oneTime
            
            For addBill dueRule:
              "on the 19th"              → dayOfMonth(day: 19)
              "every 3rd Thursday"       → nthWeekday(weekOfMonth: 3, weekday: .thursday)
              "every Thursday"           → nthWeekday(weekOfMonth: 1, weekday: .thursday)
              no date mentioned          → unspecified
            
            For question kind:
              "how much did I spend today"                 → spentToday
              "how much this week" / "spent this week"     → spentThisWeek
              "how much this month"                        → spentThisMonth
              "how much do I need to make today"           → neededToday
              "how much do I need to make this week"       → neededThisWeek
              "remaining budget" / "how much left"         → remainingBudget
              "how much have I made" / "total income"      → totalIncome
              anything else                                → general
            """
        }
        
        self.extractionSession = LanguageModelSession(instructions: extractionInstructions)
        
        // Session 2: generates the human-friendly reply text
        let replyInstructions = Instructions {
            """
            You are a warm, concise personal finance assistant.
            You will be given a summary of what action was taken or what data
            was found, and you must turn it into a single friendly reply sentence
            or two. Never use bullet points. Be encouraging.
            """
        }
        self.replySession = LanguageModelSession(instructions: replyInstructions)
    }
    
    // ── Pre-warm ──────────────────────────────────────────────────────────────
    
    func prewarm() {
        extractionSession.prewarm()
    }
    
    // ── Main entry point ──────────────────────────────────────────────────────
    
    func sendMessage(_ userText: String) async {
        let trimmed = userText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        messages.append(Message(text: trimmed, isUser: true))
        isLoading = true
        defer { isLoading = false }
        
        // ── Handle pending multi-turn state ───────────────────────────────────
        if let pending = pendingAction {
            switch pending {
            case .awaitingReminderConfirmation(let bill):
                let lower = trimmed.lowercased()
                if isAffirmative(lower) {
                    pendingAction = nil
                    scheduleReminder(for: bill)
                    messages.append(Message(
                        text: "✅ Done! I'll remind you 3 days before \(bill.name) is due.",
                        isUser: false
                    ))
                } else if isNegative(lower) {
                    pendingAction = nil
                    messages.append(Message(
                        text: "No problem, no reminder set for \(bill.name).",
                        isUser: false
                    ))
                } else {
                    // Doesn't look like a yes/no – fall through to extraction
                    pendingAction = nil
                    await extractAndHandle(trimmed)
                }
                return
            }
        }
        
        await extractAndHandle(trimmed)
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Extraction + dispatch
    // ─────────────────────────────────────────────────────────────────────────
    
    private func extractAndHandle(_ text: String) async {
        do {
            let response = try await extractionSession.respond(
                to: text,
                generating: FinanceIntent.self
            )
            let reply = await handle(response.content, originalText: text)
            messages.append(Message(text: reply, isUser: false))
        } catch {
            messages.append(Message(
                text: "Sorry, I had trouble understanding that. Could you rephrase?",
                isUser: false
            ))
        }
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Intent handlers
    // ─────────────────────────────────────────────────────────────────────────
    
    private func handle(_ intent: FinanceIntent, originalText: String) async -> String {
        switch intent {
        case .addExpense(let input):
            return await handleAddExpense(input)
        case .addIncome(let input):
            return await handleAddIncome(input)
        case .addBill(let input):
            return await handleAddBill(input)
        case .question(let input):
            return await handleQuestion(input, originalText: originalText)
        }
    }
    
    // ── addExpense ────────────────────────────────────────────────────────────
    
    private func handleAddExpense(_ input: ExpenseInput) async -> String {
        let category = findOrCreateCategory(named: input.category)
        let expense = Expense(
            amount: Decimal(input.amount),
            vendor: input.vendor,
            date: .now,
            category: category
        )
        modelContext.insert(expense)
        try? modelContext.save()
        
        let summary = "Logged a $\(String(format: "%.2f", input.amount)) expense at \(input.vendor) in \(input.category)."
        return await friendlyReply(for: summary)
    }
    
    // ── addIncome ─────────────────────────────────────────────────────────────
    
    private func handleAddIncome(_ input: IncomeInput) async -> String {
        let income = Income(
            source: input.source,
            amount: Decimal(input.amount),
            date: .now,
            frequency: input.frequency.frequency
        )
        modelContext.insert(income)
        try? modelContext.save()
        
        let summary = "Logged $\(String(format: "%.2f", input.amount)) income from \(input.source)."
        return await friendlyReply(for: summary)
    }
    
    // ── addBill ───────────────────────────────────────────────────────────────
    
    private func handleAddBill(_ input: BillInput) async -> String {
        let dueDate = computeDueDate(rule: input.dueRule, frequency: input.frequency)
        
        let bill = Transaction(
            name: input.name,
            amount: input.amount,
            frequency: input.frequency.billFrequency,
            dueDate: dueDate,
            isAutoPaid: false,
            isPaid: false,
            notes: "",
            vendor: input.vendor,
            isActive: true,
            remindMe: false          // set true only if user confirms
        )
        
        // Persist the day extracted from the due date so the notification
        // system (which reads remindDay/Hour/Minute) can use it later.
        let cal = Calendar.current
        bill.remindDay    = cal.component(.day,    from: dueDate)
        bill.remindHour   = 9    // default reminder time; user can change in settings
        bill.remindMinute = 0
        
        modelContext.insert(bill)
        try? modelContext.save()
        
        let dueDateDescription = describeDueRule(input.dueRule, frequency: input.frequency)
        let summary = """
        Added '\(input.name)' bill for $\(String(format: "%.2f", input.amount)) \
        \(input.frequency.rawValue)\(dueDateDescription.isEmpty ? "" : " \(dueDateDescription)"). \
        Ask the user if they want a reminder set for 3 days before it's due.
        """
        let reply = await friendlyReply(for: summary)
        pendingAction = .awaitingReminderConfirmation(bill)
        return reply
    }
    
    // ── question ──────────────────────────────────────────────────────────────
    
    private func handleQuestion(_ input: QuestionInput, originalText: String) async -> String {
        let data = fetchCurrentData()
        let cal = Calendar.current
        let now = Date()
        
        switch input.kind {
            
        case .spentToday:
            let todayExpenses = data.expenses.filter { cal.isDateInToday($0.date) }
            let total = todayExpenses.reduce(Decimal(0)) { $0 + $1.amount }
            return await friendlyReply(for: "The user spent $\(formatDecimal(total)) today.")
            
        case .spentThisWeek:
            let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let weekExpenses = data.expenses.filter { $0.date >= weekStart }
            let total = weekExpenses.reduce(Decimal(0)) { $0 + $1.amount }
            return await friendlyReply(for: "The user spent $\(formatDecimal(total)) this week.")
            
        case .spentThisMonth:
            let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: now))!
            let monthExpenses = data.expenses.filter { $0.date >= monthStart }
            let total = monthExpenses.reduce(Decimal(0)) { $0 + $1.amount }
            return await friendlyReply(for: "The user spent $\(formatDecimal(total)) this month.")
            
        case .neededToday:
            // Sum of all bills due today, normalized to daily
            let activeBills = data.bills.filter { $0.isActive }
            let dailyTotal = budgetController.totalBills(activeBills, for: .daily)
            return await friendlyReply(for: "To cover daily bill obligations, the user needs to earn $\(formatDecimal(dailyTotal)) today.")
            
        case .neededThisWeek:
            let activeBills = data.bills.filter { $0.isActive }
            let weeklyTotal = budgetController.totalBills(activeBills, for: .weekly)
            return await friendlyReply(for: "To cover weekly bill obligations, the user needs to earn $\(formatDecimal(weeklyTotal)) this week.")
            
        case .remainingBudget:
            let activeBills = data.bills.filter { $0.isActive }
            let remaining = budgetController.remainingBudget(
                bills: activeBills,
                expenses: data.expenses,
                incomes: data.incomes,
                for: .monthly
            )
            return await friendlyReply(for: "The user's remaining monthly budget is $\(formatDecimal(remaining)).")
            
        case .totalIncome:
            let total = budgetController.totalIncome(data.incomes)
            return await friendlyReply(for: "The user's total logged income is $\(formatDecimal(total)).")
            
        case .general:
            // For open-ended questions, inject a full financial snapshot into
            // a Prompt and let the reply session answer naturally.
            let snapshot = buildFinancialSnapshot(data: data)
            let prompt = Prompt {
                "Answer this financial question: \(originalText)"
                "Here is the user's current financial data:"
                snapshot
                "Answer in one or two friendly sentences using only the data above."
            }
            do {
                let response = try await replySession.respond(to: prompt)
                return response.content
            } catch {
                return "I'm not sure – try asking about spending, income, or your budget."
            }
        }
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Friendly reply generation
    // ─────────────────────────────────────────────────────────────────────────
    
    /// Takes a plain-English summary of what happened and returns a warm reply.
    private func friendlyReply(for summary: String) async -> String {
        let prompt = Prompt {
            "Turn this into a single friendly, encouraging reply: \(summary)"
        }
        do {
            let response = try await replySession.respond(to: prompt)
            return response.content
        } catch {
            // Fall back to the raw summary if the model fails
            return summary
        }
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Due date computation
    // ─────────────────────────────────────────────────────────────────────────
    
    /// Converts a structured `DueRule` into a concrete `Date`.
    private func computeDueDate(rule: DueRule, frequency: IntentFrequency) -> Date {
        let cal = Calendar.current
        let now = Date()
        var comps = cal.dateComponents([.year, .month], from: now)
        
        switch rule {
            
        case .dayOfMonth(let r):
            // e.g. "19th of every other month"
            comps.day = r.day
            if let candidate = cal.date(from: comps), candidate < now {
                // This month's date already passed – use next occurrence
                comps.month! += frequency == .biMonthly ? 2 : 1
            }
            return cal.date(from: comps) ?? now
            
        case .nthWeekday(let r):
            // e.g. "3rd Thursday" – find the Nth occurrence of that weekday
            // in the current (or next) month.
            let targetWeekday = r.weekday.rawValue   // 1=Sun … 7=Sat
            let targetWeek    = r.weekOfMonth        // 1-based
            
            for monthOffset in 0...2 {
                var searchComps = comps
                searchComps.day = 1
                if monthOffset > 0 { searchComps.month! += monthOffset }
                guard let firstOfMonth = cal.date(from: searchComps) else { continue }
                
                let firstWeekday = cal.component(.weekday, from: firstOfMonth)
                // Days to add to reach first occurrence of targetWeekday
                let daysToFirstOccurrence = (targetWeekday - firstWeekday + 7) % 7
                let daysToAdd = daysToFirstOccurrence + (targetWeek - 1) * 7
                
                guard let candidate = cal.date(byAdding: .day, value: daysToAdd, to: firstOfMonth) else { continue }
                
                // Sanity check: candidate must still be in the same month
                let candidateMonth = cal.component(.month, from: candidate)
                let searchMonth    = cal.component(.month, from: firstOfMonth)
                guard candidateMonth == searchMonth else { continue }
                
                if candidate > now || monthOffset > 0 {
                    return candidate
                }
            }
            return now
            
        case .unspecified:
            // Default: first day of next month
            comps.day = 1
            comps.month! += 1
            return cal.date(from: comps) ?? now
        }
    }
    
    /// Human-readable description of a `DueRule` for the reply prompt.
    private func describeDueRule(_ rule: DueRule, frequency: IntentFrequency) -> String {
        switch rule {
        case .dayOfMonth(let r):
            return "on the \(ordinal(r.day)) of each period"
        case .nthWeekday(let r):
            let weekdayName = weekdayName(r.weekday)
            return "on the \(ordinal(r.weekOfMonth)) \(weekdayName) of each period"
        case .unspecified:
            return ""
        }
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Reminder scheduling
    // ─────────────────────────────────────────────────────────────────────────
    
    // ── scheduleReminder ──────────────────────────────────────────────────────
    
    private func scheduleReminder(for bill: Transaction) {
        guard let dueDate = bill.dueDate else { return }
        
        let cal = Calendar.current
        
        // Remind 3 days before at 9 AM
        guard let reminderDate = cal.date(byAdding: .day, value: -3, to: dueDate) else { return }
        
        var triggerComps        = cal.dateComponents([.year, .month, .day], from: reminderDate)
        triggerComps.hour       = bill.remindHour   ?? 9
        triggerComps.minute     = bill.remindMinute ?? 0
        
        let content        = UNMutableNotificationContent()
        content.title      = "Bill due soon: \(bill.name)"
        content.body       = "$\(String(format: "%.2f", bill.amount)) is due in 3 days."
        content.sound      = .default
        
        // Use repeats: true + the bill's frequency so it re-fires each cycle.
        // For non-monthly cadences, a one-shot trigger is safer — the app can
        // reschedule on next launch via BudgetController.scheduleReminders().
        let repeats = bill.frequency == .monthly
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComps, repeats: repeats)
        
        let request = UNNotificationRequest(
            identifier: "bill-reminder-\(bill.id.uuidString)",
            content:    content,
            trigger:    trigger
        )
        UNUserNotificationCenter.current().add(request)
        
        // Persist so BudgetController.scheduleReminders() can reschedule on relaunch
        bill.remindMe     = true
        bill.remindDay    = triggerComps.day
        bill.remindHour   = triggerComps.hour ?? 9
        bill.remindMinute = triggerComps.minute ?? 0
        try? modelContext.save()
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Data helpers
    // ─────────────────────────────────────────────────────────────────────────
    
    private struct FinancialData {
        let expenses: [Expense]
        let incomes: [Income]
        let bills: [Transaction]
    }
    
    private func fetchCurrentData() -> FinancialData {
        let expenses  = (try? modelContext.fetch(FetchDescriptor<Expense>())) ?? []
        let incomes   = (try? modelContext.fetch(FetchDescriptor<Income>())) ?? []
        let bills     = (try? modelContext.fetch(FetchDescriptor<Transaction>())) ?? []
        return FinancialData(expenses: expenses, incomes: incomes, bills: bills)
    }
    
    /// Builds a plain-text financial snapshot for the general question path.
    private func buildFinancialSnapshot(data: FinancialData) -> String {
        let cal = Calendar.current
        let now = Date()
        
        let todayTotal = data.expenses
            .filter { cal.isDateInToday($0.date) }
            .reduce(Decimal(0)) { $0 + $1.amount }
        
        let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let weekTotal = data.expenses
            .filter { $0.date >= weekStart }
            .reduce(Decimal(0)) { $0 + $1.amount }
        
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: now))!
        let monthTotal = data.expenses
            .filter { $0.date >= monthStart }
            .reduce(Decimal(0)) { $0 + $1.amount }
        
        let activeBills = data.bills.filter { $0.isActive }
        let monthlyBills = budgetController.totalBills(activeBills, for: .monthly)
        let totalIncome  = budgetController.totalIncome(data.incomes)
        let remaining    = budgetController.remainingBudget(
            bills: activeBills, expenses: data.expenses,
            incomes: data.incomes, for: .monthly
        )
        
        let upcoming = budgetController.upcomingPayments(
            bills: activeBills, from: now,
            to: cal.date(byAdding: .day, value: 30, to: now)!
        )
        let upcomingLines = upcoming.prefix(5).map { bill -> String in
            let due = budgetController.nextDueDate(for: bill)
                .map { formatDate($0) } ?? "unknown date"
            return "  • \(bill.name): $\(String(format: "%.2f", bill.amount)) due \(due)"
        }.joined(separator: "\n")
        
        return """
        Date: \(formatDate(now))
        Spent today: $\(formatDecimal(todayTotal))
        Spent this week: $\(formatDecimal(weekTotal))
        Spent this month: $\(formatDecimal(monthTotal))
        Total income logged: $\(formatDecimal(totalIncome))
        Monthly bills total: $\(formatDecimal(monthlyBills))
        Remaining monthly budget: $\(formatDecimal(remaining))
        Upcoming bills (next 30 days):
        \(upcomingLines.isEmpty ? "  None" : upcomingLines)
        """
    }
    
    private func findOrCreateCategory(named rawName: String) -> Category {
        let normalised = normaliseCategory(rawName)
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { $0.name == normalised }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        // Try case-insensitive fallback across all categories
        let all = (try? modelContext.fetch(FetchDescriptor<Category>())) ?? []
        if let match = all.first(where: { $0.name.lowercased() == normalised.lowercased() }) {
            return match
        }
        let icon = ExpenseCategory.allCases
            .first(where: { $0.label.lowercased() == normalised.lowercased() })?
            .symbolName ?? "tag.fill"
        let cat = Category(name: normalised, icon: icon, isDefault: false)
        modelContext.insert(cat)
        try? modelContext.save()
        return cat
    }
    
    private func normaliseCategory(_ raw: String) -> String {
        switch raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) {
        case "food", "groceries", "restaurant", "dining", "eating out":
            return "Food"
        case "rent", "housing", "mortgage":
            return "Housing"
        case "gas", "fuel", "transportation", "car", "uber", "lyft":
            return "Transportation"
        case "shopping", "clothes", "clothing":
            return "Shopping"
        case "utilities", "electricity", "water", "internet":
            return "Utilities"
        case "entertainment", "movies", "games":
            return "Entertainment"
        case "healthcare", "medical", "pharmacy", "health":
            return "Healthcare"
        case "insurance":
            return "Insurance"
        case "subscriptions", "subscription":
            return "Subscriptions"
        case "education", "school", "tuition":
            return "Education"
        case "savings", "saving":
            return "Savings"
        case "debt", "loan", "credit card":
            return "Debt"
        case "gifts", "donations", "charity":
            return "Gifts & Donations"
        case "travel", "vacation", "hotel", "flights":
            return "Travel"
        case "personal care", "salon", "barber", "beauty":
            return "Personal Care"
        default:
            return raw.isEmpty ? "Miscellaneous" : raw.capitalized
        }
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Utility
    // ─────────────────────────────────────────────────────────────────────────
    
    private func isAffirmative(_ s: String) -> Bool {
        ["yes", "yeah", "yep", "sure", "ok", "okay", "please",
         "yup", "absolutely", "do it", "set it", "go ahead"].contains(where: { s.contains($0) })
    }
    
    private func isNegative(_ s: String) -> Bool {
        ["no", "nope", "nah", "don't", "skip", "not now", "no thanks"].contains(where: { s.contains($0) })
    }
    
    private func formatDecimal(_ d: Decimal) -> String {
        String(format: "%.2f", NSDecimalNumber(decimal: d).doubleValue)
    }
    
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
    
    private func ordinal(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)th"
    }
    
    private func weekdayName(_ weekday: BillWeekday) -> String {
        switch weekday {
        case .sunday:    return "Sunday"
        case .monday:    return "Monday"
        case .tuesday:   return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday:  return "Thursday"
        case .friday:    return "Friday"
        case .saturday:  return "Saturday"
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - FinanceChatView
// ─────────────────────────────────────────────────────────────────────────────

@available(iOS 26.0, *)
struct FinanceChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(BudgetController.self) private var budgetController
    
    @State private var manager: FinanceChatController?
    @State private var inputText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                messageList
                Divider()
                inputBar
            }
            .navigationTitle("Finance Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                guard manager == nil else { return }
                let m = FinanceChatController(
                    context: modelContext,
                    budgetController: budgetController
                )
                m.prewarm()
                manager = m
            }
        }
    }
    
    // ── Message list ──────────────────────────────────────────────────────────
    
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    if let manager {
                        if manager.messages.isEmpty {
                            emptyStateView
                        }
                        ForEach(manager.messages) { message in
                            messageBubble(message)
                                .id(message.id)
                        }
                        if manager.isLoading {
                            loadingBubble
                                .id("loading")
                        }
                    } else {
                        ProgressView("Initialising…")
                            .padding()
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .onChange(of: manager?.messages.count) { _, _ in
                if let last = manager?.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            .onChange(of: manager?.isLoading) { _, loading in
                if loading == true {
                    withAnimation { proxy.scrollTo("loading", anchor: .bottom) }
                }
            }
        }
    }
    
    // ── Input bar ─────────────────────────────────────────────────────────────
    
    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Log something or ask a question…", text: $inputText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...5)
                .onSubmit { send() }
            
            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(canSend ? Color.blue : Color.gray.opacity(0.4))
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
    
    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        manager?.isLoading != true
    }
    
    // ── Empty state ───────────────────────────────────────────────────────────
    
    private var emptyStateView: some View {
        VStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(.blue)
            
            Text("Your Finance Assistant \(Text("Beta").fontWeight(.black).foregroundStyle(.green))")
                .font(.headline)
            
            Group {
                Text("Try saying:").font(.subheadline).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 6) {
                    suggestionChip("Rent is $1,200 every month on the 1st")
                    suggestionChip("Water bill is $85 every other month on the 19th")
                    suggestionChip("I spent $42 at Trader Joe's")
                    suggestionChip("I made $400 from Uber this week")
                    suggestionChip("How much have I spent today?")
                    suggestionChip("How much do I need to make this week?")
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
        .multilineTextAlignment(.center)
    }
    
    @ViewBuilder
    private func suggestionChip(_ text: String) -> some View {
        Button {
            inputText = text
            send()
        } label: {
            Text(text)
                .font(.footnote)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.secondarySystemBackground))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    // ── Bubbles ───────────────────────────────────────────────────────────────
    
    @ViewBuilder
    private func messageBubble(_ message: FinanceChatController.Message) -> some View {
        HStack {
            if message.isUser { Spacer(minLength: 60) }
            
            Text(message.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(message.isUser ? Color.blue : Color(.secondarySystemBackground))
                .foregroundStyle(message.isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .font(.callout)
            
            if !message.isUser { Spacer(minLength: 60) }
        }
    }
    
    private var loadingBubble: some View {
        HStack {
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.secondary.opacity(0.5))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            
            Spacer(minLength: 60)
        }
    }
    
    // ── Send ──────────────────────────────────────────────────────────────────
    
    private func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let manager, !manager.isLoading else { return }
        inputText = ""
        Task { await manager.sendMessage(text) }
    }
}

import FoundationModels

@available(iOS 26.0, *)
@Generable
struct FinanceQuestion {
    @Guide(description: "User's financial question")
    let query: String
}
