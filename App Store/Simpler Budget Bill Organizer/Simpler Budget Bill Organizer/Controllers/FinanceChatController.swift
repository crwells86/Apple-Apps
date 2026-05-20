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

/// Strongly-typed frequency – mirrors BillFrequency.rawValue exactly.
@available(iOS 26.0, *)
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

/// Income frequency – mirrors Frequency.rawValue.
@available(iOS 26.0, *)
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

/// Input for marking a specific bill as paid.
@available(iOS 26.0, *)
@Generable
struct BillNameInput {
    @Guide(description: "Name of the bill or subscription the user is referring to")
    let name: String
    
    @Guide(description: "Amount paid, if explicitly mentioned. 0 if not specified.")
    let amount: Double
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Question types
// ─────────────────────────────────────────────────────────────────────────────

@available(iOS 26.0, *)
@Generable
enum QuestionKind {
    /// How much was spent today.
    case spentToday
    /// How much was spent this week (Mon–today).
    case spentThisWeek
    /// How much was spent this month.
    case spentThisMonth
    /// Spending broken down by category this month.
    case categoryBreakdown
    /// How much income is needed today to cover upcoming bills.
    case neededToday
    /// How much income is needed this week to cover upcoming bills.
    case neededThisWeek
    /// Remaining monthly budget.
    case remainingBudget
    /// Total income logged.
    case totalIncome
    /// List all active bills.
    case listBills
    /// List only recurring subscriptions (monthly bills).
    case listSubscriptions
    /// List bills due within the next 7 days.
    case listUpcomingBills
    /// Detail about one specific bill by name.
    case billDetail
    /// A general question the model should answer with the data summary.
    case general
}

@available(iOS 26.0, *)
@Generable
struct QuestionInput {
    let kind: QuestionKind
    
    @Guide(description: "The specific bill, subscription, or category name being asked about. Empty string if not applicable.")
    let subjectName: String
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
    /// User is marking an existing bill as paid.
    case markBillPaid(BillNameInput)
    /// User asked a financial question.
    case question(QuestionInput)
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Supporting types
// ─────────────────────────────────────────────────────────────────────────────

@available(iOS 26.0, *)
@Generable
struct FinanceQuestion {
    @Guide(description: "User's financial question")
    let query: String
}

/// Intermediate bill state for multi-turn capture.
@available(iOS 26.0, *)
struct PartialBillInput {
    var name: String
    var amount: Double?
    var frequency: IntentFrequency
    var dueRule: DueRule
    var vendor: String
}

/// All multi-turn states the chat controller can be in.
@available(iOS 26.0, *)
private enum ConversationState {
    /// Normal: ready for a new user message.
    case idle
    /// Bill was extracted but we don't know the amount yet.
    case awaitingBillAmount(partialBill: PartialBillInput)
    /// Bill is fully parsed; waiting for yes/no on reminder.
    case awaitingReminderConfirmation(bill: Transaction)
    /// User said "edit my rent"; waiting to know which field to change.
    case awaitingEditField(bill: Transaction)
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - FinanceChatController
// ─────────────────────────────────────────────────────────────────────────────

@available(iOS 26.0, *)
@Observable
@MainActor
final class FinanceChatController {
    
    // ── Message model ─────────────────────────────────────────────────────────
    
    struct Message: Identifiable {
        let id = UUID()
        var text: String
        let isUser: Bool
    }
    
    // ── Internal data snapshot ────────────────────────────────────────────────
    
    struct FinancialData {
        let expenses: [Expense]
        let incomes:  [Income]
        let bills:    [Transaction]
    }
    
    // ── Published state ───────────────────────────────────────────────────────
    
    var messages: [Message] = []
    var isLoading            = false
    
    // ── Dependencies ──────────────────────────────────────────────────────────
    
    private let modelContext:     ModelContext
    private let budgetController: BudgetController
    
    // ── Sessions ──────────────────────────────────────────────────────────────
    //
    // makeExtractionSession() is called fresh on every extraction — intentionally
    // stateless so it never accumulates history or overflows the context window.
    //
    // replySession is stateful (keeps turn history) and rebuilt automatically
    // when it overflows.
    
    private var replySession:         LanguageModelSession
    private let clarificationSession: LanguageModelSession
    
    // ── State machine ─────────────────────────────────────────────────────────
    
    private var conversationState: ConversationState = .idle
    
    // ── Reply session personality ─────────────────────────────────────────────
    
    private static let replyInstructionsText = """
        You are a sharp, low-key personal finance assistant. Your job is to
        make people feel good about tracking their money — not lectured, not
        coddled.
        
        VOICE
        ─────
        • Dry wit over cheerfulness. Never say "Great job!", "Awesome!", or "Nice!".
          A good reply sounds like a smart friend glancing at your phone, not
          an app notification.
        • Short is almost always better. One sentence for routine logs.
          Two sentences max unless you're surfacing a real insight.
        • Never use bullet points or lists in replies. Plain prose only.
        • Match the user's energy. If they type "ugh rent again" — acknowledge
          the ugh. If they're matter-of-fact, be matter-of-fact.
        • No moralising. Never say "you might want to consider cutting back on…"
          unless the user explicitly asked. Your job is awareness, not advice.
        
        FRAMING (critical)
        ──────────────────
        • Always frame around what remains, not what was spent.
          BAD:  "You've spent $340 on food this month."
          GOOD: "Food's at $340 — $160 left in that bucket."
        • Progress framing for bills:
          BAD:  "You still owe $800 on your car payment."
          GOOD: "Car payment: $800 down, done."
        • Never use the word "only" to minimise a number.
        
        UNSOLICITED INSIGHT (use sparingly — 1 in 3 replies at most)
        ─────────────────────────────────────────────────────────────
        When the background context contains something genuinely interesting,
        append one sentence the user didn't ask for:
          "That's your third Uber Eats this week, by the way."
          "Netflix just ticked over — that's 4 subscriptions now."
          "Rent logged. You're clear of bills until the 19th."
        Only do this if the insight is concrete and specific. Never generic.
        
        MOMENTUM (1 in 4 replies)
        ─────────────────────────
        End roughly 1 in 4 replies with one low-pressure thread to keep the
        conversation alive — never a question barrage:
          "Want me to check where food sits this month?"
          "Heads up: water bill's coming up on the 19th."
        If there's nothing natural to offer, end clean.
        
        WHAT YOU NEVER DO
        ─────────────────
        • Never start a reply with "I".
        • Never say "Of course!", "Certainly!", "Absolutely!", "Sure thing!"
        • Never explain what you just did. Just confirm and move forward.
        • Never ask more than one question at a time.
        • Never be sycophantic about the user doing their finances.
          They're an adult. Treat them like one.
        """
    
    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Session factories
    // ─────────────────────────────────────────────────────────────────────────
    
    /// Returns a fresh, stateless extraction session.
    /// Called on every extraction — never stored between calls.
    private func makeExtractionSession() -> LanguageModelSession {
        LanguageModelSession(
            instructions: Instructions {
                """
                You are a financial data extraction engine.
                Classify the user message into one of five intents and fill in
                the structured fields precisely.
                
                Intent rules:
                - addExpense:    user spent money (one-time purchase or payment)
                - addIncome:     user received or earned money
                - addBill:       recurring bill, subscription, or regular payment
                - markBillPaid:  user says they paid a specific existing bill
                                 (e.g. "paid rent", "I paid my Netflix", "rent is paid")
                - question:      user asking about their financial situation
                
                IMPORTANT — markBillPaid vs addExpense:
                  If the user mentions a known bill name + "paid", use markBillPaid.
                  If they mention a store or one-off purchase, use addExpense.
                  "I paid rent" → markBillPaid  |  "I spent $40 at Target" → addExpense
                
                For addBill frequency:
                  "every other month" / "bi-monthly"  → biMonthly
                  "every month" / "monthly"            → monthly
                  "every week" / "weekly"              → weekly
                  "every two weeks" / "biweekly"       → biweekly
                  "twice a month" / "semi-monthly"     → semiMonthly
                  "every 3 months" / "quarterly"       → quarterly
                  "every 6 months" / "semi-annual"     → semiAnnual
                  "once a year" / "yearly" / "annual"  → yearly
                  "one time" / "one-off"               → oneTime
                
                For addBill dueRule:
                  "on the 19th"        → dayOfMonth(day: 19)
                  "every 3rd Thursday" → nthWeekday(weekOfMonth: 3, weekday: .thursday)
                  "every Thursday"     → nthWeekday(weekOfMonth: 1, weekday: .thursday)
                  no date mentioned    → unspecified
                
                For question kind:
                  "what did I spend today" / "today's spending"          → spentToday
                  "this week's spending" / "spent this week"             → spentThisWeek
                  "this month" / "monthly spending"                      → spentThisMonth
                  "by category" / "category breakdown" / "where am I spending" → categoryBreakdown
                  "how much do I need today"                             → neededToday
                  "how much do I need this week"                         → neededThisWeek
                  "remaining budget" / "how much left"                   → remainingBudget
                  "total income" / "how much have I earned"              → totalIncome
                  "list my bills" / "what bills do I have" / "all bills" → listBills
                  "subscriptions" / "list subscriptions"                 → listSubscriptions
                  "what's due soon" / "upcoming bills" / "due this week" → listUpcomingBills
                  "how much is my [name]" / "what does [name] cost"     → billDetail (set subjectName)
                  anything else                                          → general
                
                For billDetail and categoryBreakdown, set subjectName to the
                specific bill/subscription/category name mentioned.
                For all other kinds, set subjectName to empty string.
                """
            }
        )
    }
    
    /// Returns a fresh reply session with full personality instructions.
    /// Called once in init and again whenever the session overflows.
    private static func makeReplySession() -> LanguageModelSession {
        LanguageModelSession(
            instructions: Instructions { replyInstructionsText }
        )
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Init
    // ─────────────────────────────────────────────────────────────────────────
    
    init(context: ModelContext, budgetController: BudgetController) {
        self.modelContext     = context
        self.budgetController = budgetController
        
        replySession = Self.makeReplySession()
        
        clarificationSession = LanguageModelSession(
            instructions: Instructions {
                """
                You are a concise financial assistant. The user gave an
                incomplete command. Ask a single short clarifying question to
                get the missing information. Never ask for more than one thing.
                """
            }
        )
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Prewarm
    // ─────────────────────────────────────────────────────────────────────────
    
    func prewarm() {
        // Only prewarm the reply session — extraction is ephemeral.
        replySession.prewarm()
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Main entry point
    // ─────────────────────────────────────────────────────────────────────────
    
    func sendMessage(_ userText: String) async {
        let trimmed = userText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        messages.append(Message(text: trimmed, isUser: true))
        isLoading = true
        defer { isLoading = false }
        
        switch conversationState {
            
        case .idle:
            await extractAndHandle(trimmed)
            
        case .awaitingBillAmount(let partial):
            if let amount = extractDollarAmount(from: trimmed) {
                var filled    = partial
                filled.amount = amount
                conversationState = .idle
                let input = BillInput(
                    name:      filled.name,
                    amount:    amount,
                    frequency: filled.frequency,
                    dueRule:   filled.dueRule,
                    vendor:    filled.vendor
                )
                let reply = await handleAddBill(input)
                appendReply(reply)
            } else {
                appendReply("How much is your \(partial.name) bill?")
            }
            
        case .awaitingReminderConfirmation(let bill):
            let lower = trimmed.lowercased()
            if isAffirmative(lower) {
                conversationState = .idle
                scheduleReminder(for: bill)
                await appendStreamingReply(
                    for: "Reminder set for \(bill.name), 3 days before it's due."
                )
            } else if isNegative(lower) {
                conversationState = .idle
                await appendStreamingReply(for: "No reminder set for \(bill.name).")
            } else {
                // Not a yes/no — treat as a new message
                conversationState = .idle
                await extractAndHandle(trimmed)
            }
            
        case .awaitingEditField(let bill):
            conversationState = .idle
            await appendStreamingReply(
                for: "Editing \(bill.name) isn't fully implemented yet."
            )
        }
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Extraction + validation
    // ─────────────────────────────────────────────────────────────────────────
    
    private func extractAndHandle(_ text: String) async {
        // Fresh session every call — stateless, no context overflow possible.
        let session = makeExtractionSession()
        
        do {
            let response  = try await session.respond(
                to: text, generating: FinanceIntent.self
            )
            let validated = repairIntent(response.content, originalText: text)
            let reply     = await handle(validated, originalText: text)
            appendReply(reply)
            
        } catch {
#if DEBUG
            print("[Extraction error] \(type(of: error)): \(error)")
#endif
            
            let desc = "\(error)".lowercased()
            if desc.contains("context") || desc.contains("length") || desc.contains("token") {
                appendReply("Hit a memory limit on that one — try again.")
            } else {
                appendReply("Couldn't parse that — could you rephrase?")
            }
        }
    }
    
    private func repairIntent(_ intent: FinanceIntent, originalText: String) -> FinanceIntent {
        switch intent {
        case .addBill(var input):
            // Fix invalid nthWeekday (weekOfMonth must be ≥ 1)
            if case .nthWeekday(let rule) = input.dueRule, rule.weekOfMonth < 1 {
                let repaired = NthWeekdayRule(weekOfMonth: 1, weekday: rule.weekday)
                input = BillInput(
                    name:      input.name,
                    amount:    input.amount,
                    frequency: input.frequency,
                    dueRule:   .nthWeekday(repaired),
                    vendor:    input.vendor
                )
                return .addBill(input)
            }
            // If amount is 0 and there's no digit in the message, ask for it
            if input.amount == 0 && !originalText.contains(where: \.isNumber) {
                conversationState = .awaitingBillAmount(partialBill: PartialBillInput(
                    name:      input.name,
                    amount:    nil,
                    frequency: input.frequency,
                    dueRule:   input.dueRule,
                    vendor:    input.vendor
                ))
            }
            return .addBill(input)
        default:
            return intent
        }
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Intent dispatch
    // ─────────────────────────────────────────────────────────────────────────
    
    private func handle(_ intent: FinanceIntent, originalText: String) async -> String {
        switch intent {
        case .addExpense(let input):    return await handleAddExpense(input)
        case .addIncome(let input):     return await handleAddIncome(input)
        case .addBill(let input):       return await handleAddBill(input)
        case .markBillPaid(let input):  return await handleMarkBillPaid(input)
        case .question(let input):      return await handleQuestion(input, originalText: originalText)
        }
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Intent handlers
    // ─────────────────────────────────────────────────────────────────────────
    
    private func handleAddExpense(_ input: ExpenseInput) async -> String {
        let category = findOrCreateCategory(named: input.category)
        let expense  = Expense(
            amount:   Decimal(input.amount),
            vendor:   input.vendor,
            date:     .now,
            category: category
        )
        modelContext.insert(expense)
        try? modelContext.save()
        
        let summary = "Logged $\(String(format: "%.2f", input.amount)) at \(input.vendor) in \(input.category)."
        return await engagingReply(for: summary, intent: .addExpense(input))
    }
    
    private func handleAddIncome(_ input: IncomeInput) async -> String {
        let income = Income(
            source:    input.source,
            amount:    Decimal(input.amount),
            date:      .now,
            frequency: input.frequency.frequency
        )
        modelContext.insert(income)
        try? modelContext.save()
        
        let summary = "Logged $\(String(format: "%.2f", input.amount)) income from \(input.source)."
        return await engagingReply(for: summary, intent: .addIncome(input))
    }
    
    private func handleAddBill(_ input: BillInput) async -> String {
        let dueDate = computeDueDate(rule: input.dueRule, frequency: input.frequency)
        let bill    = Transaction(
            name:       input.name,
            amount:     input.amount,
            frequency:  input.frequency.billFrequency,
            dueDate:    dueDate,
            isAutoPaid: false,
            isPaid:     false,
            notes:      "",
            vendor:     input.vendor,
            isActive:   true,
            remindMe:   false
        )
        let cal           = Calendar.current
        bill.remindDay    = cal.component(.day,    from: dueDate)
        bill.remindHour   = 9
        bill.remindMinute = 0
        modelContext.insert(bill)
        try? modelContext.save()
        
        let due     = describeDueRule(input.dueRule, frequency: input.frequency)
        let summary = "Added \(input.name) at $\(String(format: "%.2f", input.amount)) \(input.frequency.rawValue)\(due.isEmpty ? "" : ", \(due)"). Offer to set a reminder 3 days before it's due — one short sentence."
        conversationState = .awaitingReminderConfirmation(bill: bill)
        return await engagingReply(for: summary, intent: .addBill(input))
    }
    
    /// Marks an existing bill as paid and records it as an expense.
    private func handleMarkBillPaid(_ input: BillNameInput) async -> String {
        let data      = fetchCurrentData()
        let searchKey = input.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Find the best matching active, unpaid bill
        let match = data.bills.first(where: {
            $0.isActive &&
            !$0.isPaid &&
            $0.name.lowercased().contains(searchKey)
        })
        
        guard let bill = match else {
            // Fall back: maybe it's already paid or doesn't exist
            let alreadyPaid = data.bills.first(where: {
                $0.isActive && $0.name.lowercased().contains(searchKey)
            })
            if alreadyPaid != nil {
                return await questionReply(
                    answer: "\(input.name.capitalized) is already marked paid this period."
                )
            }
            return await questionReply(
                answer: "Couldn't find an active bill called \(input.name). Check the Bills tab."
            )
        }
        
        // Use the stated amount if provided, otherwise the bill's amount
        let paidAmount = input.amount > 0 ? input.amount : bill.amount
        bill.isPaid    = true
        
        // Record as an expense so it shows up in spending history
        let expense = Expense(
            amount:   Decimal(paidAmount),
            vendor:   bill.name,
            date:     .now,
            category: bill.category
        )
        modelContext.insert(expense)
        try? modelContext.save()
        
        // Build insight context manually since we don't have a matching FinanceIntent case
        let data2        = fetchCurrentData()
        let activeBills  = data2.bills.filter { $0.isActive }
        let remaining    = budgetController.remainingBudget(
            bills:    activeBills,
            expenses: data2.expenses,
            incomes:  data2.incomes,
            for:      .monthly
        )
        let next7        = Calendar.current.date(byAdding: .day, value: 7, to: .now)!
        let upcoming     = budgetController.upcomingPayments(bills: activeBills, from: .now, to: next7)
        let upcomingNote = upcoming.isEmpty
        ? "No other bills due this week."
        : "Still due this week: \(upcoming.prefix(2).map(\.name).joined(separator: ", "))."
        
        let summary = """
            Marked \(bill.name) paid — $\(String(format: "%.2f", paidAmount)) logged. \
            Monthly cushion: $\(formatDecimal(remaining)). \(upcomingNote)
            """
        return await questionReply(answer: summary)
    }
    
    private func handleQuestion(_ input: QuestionInput, originalText: String) async -> String {
        let data = fetchCurrentData()
        let cal  = Calendar.current
        let now  = Date()
        
        switch input.kind {
            
            // ── Spending queries ──────────────────────────────────────────────────
            
        case .spentToday:
            let total = data.expenses
                .filter { cal.isDateInToday($0.date) }
                .reduce(Decimal(0)) { $0 + $1.amount }
            let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let weekSoFar = data.expenses
                .filter { $0.date >= weekStart }
                .reduce(Decimal(0)) { $0 + $1.amount }
            return await questionReply(
                answer: "Spent $\(formatDecimal(total)) today.",
                hint:   "$\(formatDecimal(weekSoFar)) so far this week."
            )
            
        case .spentThisWeek:
            let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let total     = data.expenses
                .filter { $0.date >= weekStart }
                .reduce(Decimal(0)) { $0 + $1.amount }
            let dayName   = cal.weekdaySymbols[cal.component(.weekday, from: now) - 1]
            let daysIn    = cal.component(.weekday, from: now) - 1
            return await questionReply(
                answer: "Spent $\(formatDecimal(total)) this week.",
                hint:   "It's \(dayName) — \(daysIn) days in."
            )
            
        case .spentThisMonth:
            let monthStart          = cal.date(from: cal.dateComponents([.year, .month], from: now))!
            let total               = data.expenses
                .filter { $0.date >= monthStart }
                .reduce(Decimal(0)) { $0 + $1.amount }
            let activeBills         = data.bills.filter { $0.isActive }
            let monthlyBills        = budgetController.totalBills(activeBills, for: .monthly)
            let totalIncome         = budgetController.totalIncome(data.incomes)
            let remainingAfterBills = totalIncome - monthlyBills - total
            return await questionReply(
                answer: "Spent $\(formatDecimal(total)) this month.",
                hint:   "$\(formatDecimal(remainingAfterBills)) left after bills."
            )
            
        case .categoryBreakdown:
            let monthStart  = cal.date(from: cal.dateComponents([.year, .month], from: now))!
            let thisMonth   = data.expenses.filter { $0.date >= monthStart }
            
            // If a specific category was asked about, filter to it
            let subjectLower = input.subjectName.lowercased()
            if !subjectLower.isEmpty {
                let catTotal = thisMonth
                    .filter { ($0.category?.name.lowercased() ?? "uncategorized") == subjectLower }
                    .reduce(Decimal(0)) { $0 + $1.amount }
                let catName  = input.subjectName.capitalized
                let allTotal = thisMonth.reduce(Decimal(0)) { $0 + $1.amount }
                let pct      = allTotal > 0
                ? Int(NSDecimalNumber(decimal: catTotal / allTotal * 100).doubleValue)
                : 0
                return await questionReply(
                    answer: "\(catName) is at $\(formatDecimal(catTotal)) this month — \(pct)% of total spending."
                )
            }
            
            // Full breakdown, top 5 categories by spend
            let grouped = Dictionary(grouping: thisMonth) {
                $0.category?.name ?? "Uncategorized"
            }
            let sorted = grouped
                .mapValues { $0.reduce(Decimal(0)) { $0 + $1.amount } }
                .sorted { $0.value > $1.value }
                .prefix(5)
            
            guard !sorted.isEmpty else {
                return await questionReply(answer: "No expenses logged this month yet.")
            }
            
            let lines = sorted
                .map { "\($0.key) $\(formatDecimal($0.value))" }
                .joined(separator: ", ")
            let grandTotal = sorted.reduce(Decimal(0)) { $0 + $1.value }
            return await questionReply(
                answer: "Top categories this month: \(lines).",
                hint:   "$\(formatDecimal(grandTotal)) total."
            )
            
            // ── Income needed ─────────────────────────────────────────────────────
            
        case .neededToday:
            let activeBills = data.bills.filter { $0.isActive }
            let daily       = budgetController.totalBills(activeBills, for: .daily)
            return await questionReply(
                answer: "Cover your daily bill rate with $\(formatDecimal(daily)) today."
            )
            
        case .neededThisWeek:
            let activeBills = data.bills.filter { $0.isActive }
            let weekly      = budgetController.totalBills(activeBills, for: .weekly)
            return await questionReply(
                answer: "Need $\(formatDecimal(weekly)) this week for bills."
            )
            
            // ── Budget summary ────────────────────────────────────────────────────
            
        case .remainingBudget:
            let activeBills = data.bills.filter { $0.isActive }
            let remaining   = budgetController.remainingBudget(
                bills:    activeBills,
                expenses: data.expenses,
                incomes:  data.incomes,
                for:      .monthly
            )
            let monthlyBills = budgetController.totalBills(activeBills, for: .monthly)
            return await questionReply(
                answer: "$\(formatDecimal(remaining)) remaining this month.",
                hint:   "$\(formatDecimal(monthlyBills)) committed to bills."
            )
            
        case .totalIncome:
            let total      = budgetController.totalIncome(data.incomes)
            let thisMonth  = cal.date(from: cal.dateComponents([.year, .month], from: now))!
            let monthTotal = data.incomes
                .filter { $0.date >= thisMonth }
                .reduce(Decimal(0)) { $0 + $1.amount }
            return await questionReply(
                answer: "Logged $\(formatDecimal(total)) income total.",
                hint:   "$\(formatDecimal(monthTotal)) this month."
            )
            
            // ── Bill list queries ─────────────────────────────────────────────────
            
        case .listBills:
            let active = data.bills.filter { $0.isActive }
            guard !active.isEmpty else {
                return await questionReply(answer: "No active bills on record.")
            }
            let sorted = active.sorted { $0.amount > $1.amount }
            let lines = sorted
                .map { "\($0.name) $\(String(format: "%.2f", $0.amount))/\($0.frequencyRaw)" }
                .joined(separator: ", ")
            let monthlyTotal = budgetController.totalBills(active, for: .monthly)
            return await questionReply(
                answer: "\(active.count) active bills: \(lines).",
                hint:   "$\(formatDecimal(monthlyTotal))/month total."
            )
            
        case .listSubscriptions:
            let subs = data.bills.filter {
                $0.isActive && $0.frequency == .monthly
            }.sorted { $0.amount > $1.amount }
            guard !subs.isEmpty else {
                return await questionReply(answer: "No monthly subscriptions on record.")
            }
            let lines   = subs.map { "\($0.name) $\(String(format: "%.2f", $0.amount))" }.joined(separator: ", ")
            let subTotal = subs.reduce(Decimal(0)) { $0 + Decimal($1.amount) }
            return await questionReply(
                answer: "\(subs.count) monthly subscriptions: \(lines).",
                hint:   "$\(formatDecimal(subTotal))/month."
            )
            
        case .listUpcomingBills:
            let activeBills = data.bills.filter { $0.isActive }
            let next7       = cal.date(byAdding: .day, value: 7, to: now)!
            let upcoming    = budgetController.upcomingPayments(bills: activeBills, from: now, to: next7)
            guard !upcoming.isEmpty else {
                return await questionReply(answer: "Nothing due in the next 7 days.")
            }
            let lines = upcoming.map { bill -> String in
                let due = budgetController.nextDueDate(for: bill)
                    .map { formatDate($0) } ?? "soon"
                return "\(bill.name) $\(String(format: "%.2f", bill.amount)) on \(due)"
            }.joined(separator: ", ")
            return await questionReply(
                answer: "\(upcoming.count) bill\(upcoming.count == 1 ? "" : "s") due this week: \(lines)."
            )
            
        case .billDetail:
            let searchKey = input.subjectName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            guard !searchKey.isEmpty else {
                return await questionReply(answer: "Which bill did you want details on?")
            }
            guard let bill = data.bills.first(where: {
                $0.isActive && $0.name.lowercased().contains(searchKey)
            }) else {
                return await questionReply(
                    answer: "Couldn't find an active bill matching \(input.subjectName)."
                )
            }
            let due      = budgetController.nextDueDate(for: bill).map { formatDate($0) } ?? "unknown"
            let paidNote = bill.isPaid ? "Already marked paid." : "Not yet paid."
            return await questionReply(
                answer: "\(bill.name) is $\(String(format: "%.2f", bill.amount)) \(bill.frequencyRaw), next due \(due). \(paidNote)"
            )
            
            // ── General fallback ──────────────────────────────────────────────────
            
        case .general:
            let snapshot = buildFinancialSnapshot(data: data)
            let prompt   = Prompt {
                """
                Question: \(originalText)
                Financial data: \(snapshot)
                Answer in one or two sentences. Lead with the most useful number or fact.
                """
            }
            do {
                let r = try await replySession.respond(to: prompt)
                return r.content
            } catch {
#if DEBUG
                print("[General question error] \(error)")
#endif
                return "Try asking about spending, bills, income, or your budget."
            }
        }
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Reply helpers
    // ─────────────────────────────────────────────────────────────────────────
    
    /// Full engaging reply with insight context injection.
    /// Automatically rebuilds the reply session on context overflow and retries once.
    private func engagingReply(for summary: String, intent: FinanceIntent) async -> String {
        let data    = fetchCurrentData()
        let context = buildInsightContext(for: intent, data: data)
        
        let prompt = Prompt {
            """
            Action summary: \(summary)
            
            \(context.isEmpty ? "" : "Background context (use if there's something worth mentioning):\n\(context)")
            
            Reply now. One or two sentences. No preamble.
            """
        }
        
        do {
            return try await replySession.respond(to: prompt).content
        } catch {
#if DEBUG
            print("[Reply session error] \(type(of: error)): \(error)")
#endif
            
            let desc      = "\(error)".lowercased()
            let isOverflow = desc.contains("context") || desc.contains("length") || desc.contains("token")
            
            if isOverflow {
                replySession = Self.makeReplySession()
                do {
                    return try await replySession.respond(to: prompt).content
                } catch {
#if DEBUG
                    print("[Reply retry error] \(error)")
#endif
                    return summary
                }
            }
            return summary
        }
    }
    
    private func questionReply(answer: String, hint: String = "") async -> String {
        let prompt = Prompt {
            """
            Financial answer: \(answer)
            \(hint.isEmpty ? "" : "Supporting context: \(hint)")
            
            Lead with the number or fact. One sentence, maybe two if the
            context adds something useful. No preamble.
            """
        }
        do {
            return try await replySession.respond(to: prompt).content
        } catch {
#if DEBUG
            print("[questionReply error] \(error)")
#endif
            // Rebuild on overflow and fall back to raw answer
            let desc = "\(error)".lowercased()
            if desc.contains("context") || desc.contains("length") || desc.contains("token") {
                replySession = Self.makeReplySession()
            }
            return answer
        }
    }
    
    // Since the class is @MainActor, no nested MainActor.run needed.
    private func appendReply(_ text: String) {
        messages.append(Message(text: text, isUser: false))
    }
    
    private func appendStreamingReply(for summary: String) async {
        let placeholder = Message(text: "", isUser: false)
        messages.append(placeholder)
        guard let idx = messages.indices.last else { return }
        
        let prompt = Prompt { "Turn this into a single friendly reply: \(summary)" }
        do {
            for try await partial in replySession.streamResponse(to: prompt) {
                guard messages.indices.contains(idx) else { return }
                messages[idx].text = partial.content
            }
        } catch {
            let desc = "\(error)".lowercased()
            if desc.contains("context") || desc.contains("length") || desc.contains("token") {
                replySession = Self.makeReplySession()
            }
#if DEBUG
            print("[Streaming error] \(error)")
#endif
            guard messages.indices.contains(idx) else { return }
            messages[idx].text = summary
        }
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Insight context builder
    // ─────────────────────────────────────────────────────────────────────────
    
    private func buildInsightContext(for intent: FinanceIntent, data: FinancialData) -> String {
        let cal  = Calendar.current
        let now  = Date()
        var lines: [String] = []
        
        if case .addExpense(let input) = intent {
            // Vendor streak this week
            let weekStart  = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let vendorHits = data.expenses.filter {
                $0.date >= weekStart &&
                $0.vendor.lowercased() == input.vendor.lowercased()
            }.count
            if vendorHits >= 2 {
                lines.append("vendor_streak: \(input.vendor) × \(vendorHits) this week")
            }
            
            // Category pace vs last month
            let thisMonthStart = cal.date(from: cal.dateComponents([.year, .month], from: now))!
            let lastMonthStart = cal.date(byAdding: .month, value: -1, to: thisMonthStart)!
            
            let thisMonthCat = data.expenses
                .filter { $0.date >= thisMonthStart && $0.category?.name == input.category }
                .reduce(Decimal(0)) { $0 + $1.amount }
            let lastMonthCat = data.expenses
                .filter {
                    $0.date >= lastMonthStart &&
                    $0.date <  thisMonthStart &&
                    $0.category?.name == input.category
                }
                .reduce(Decimal(0)) { $0 + $1.amount }
            
            if lastMonthCat > 0 {
                let pace = NSDecimalNumber(decimal: thisMonthCat).doubleValue
                let last = NSDecimalNumber(decimal: lastMonthCat).doubleValue
                let pct  = Int(((pace - last) / last) * 100)
                if abs(pct) >= 20 {
                    lines.append("category_pace: \(input.category) \(pct > 0 ? "up" : "down") \(abs(pct))% vs last month")
                }
            }
        }
        
        // Upcoming bills in next 7 days
        let activeBills = data.bills.filter { $0.isActive }
        let next7days   = cal.date(byAdding: .day, value: 7, to: now)!
        let upcoming    = budgetController.upcomingPayments(bills: activeBills, from: now, to: next7days)
        if !upcoming.isEmpty {
            let names = upcoming.prefix(2).map { $0.name }.joined(separator: ", ")
            lines.append("upcoming_bills_7d: \(names)")
        }
        
        // Active subscription count when adding a bill
        if case .addBill = intent {
            let subCount = activeBills.filter { $0.frequency == .monthly }.count
            lines.append("active_subscriptions: \(subCount)")
        }
        
        // Monthly cushion
        let remaining       = budgetController.remainingBudget(
            bills:    activeBills,
            expenses: data.expenses,
            incomes:  data.incomes,
            for:      .monthly
        )
        let remainingDouble = NSDecimalNumber(decimal: remaining).doubleValue
        if abs(remainingDouble) > 0 {
            lines.append("monthly_cushion: $\(String(format: "%.0f", remainingDouble))")
        }
        
        return lines.joined(separator: "\n")
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Data access
    // ─────────────────────────────────────────────────────────────────────────
    
    private func fetchCurrentData() -> FinancialData {
        let expenses = (try? modelContext.fetch(FetchDescriptor<Expense>()))     ?? []
        let incomes  = (try? modelContext.fetch(FetchDescriptor<Income>()))      ?? []
        let bills    = (try? modelContext.fetch(FetchDescriptor<Transaction>())) ?? []
        return FinancialData(expenses: expenses, incomes: incomes, bills: bills)
    }
    
    private func buildFinancialSnapshot(data: FinancialData) -> String {
        let cal        = Calendar.current
        let now        = Date()
        let weekStart  = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: now))!
        
        let todayTotal = data.expenses
            .filter { cal.isDateInToday($0.date) }
            .reduce(Decimal(0)) { $0 + $1.amount }
        let weekTotal  = data.expenses
            .filter { $0.date >= weekStart }
            .reduce(Decimal(0)) { $0 + $1.amount }
        let monthTotal = data.expenses
            .filter { $0.date >= monthStart }
            .reduce(Decimal(0)) { $0 + $1.amount }
        
        let activeBills  = data.bills.filter { $0.isActive }
        let monthlyBills = budgetController.totalBills(activeBills, for: .monthly)
        let totalIncome  = budgetController.totalIncome(data.incomes)
        let remaining    = budgetController.remainingBudget(
            bills:    activeBills,
            expenses: data.expenses,
            incomes:  data.incomes,
            for:      .monthly
        )
        
        // Category breakdown this month
        let grouped = Dictionary(grouping: data.expenses.filter { $0.date >= monthStart }) {
            $0.category?.name ?? "Uncategorized"
        }
        let categoryLines = grouped
            .mapValues { $0.reduce(Decimal(0)) { $0 + $1.amount } }
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { "  • \($0.key): $\(formatDecimal($0.value))" }
            .joined(separator: "\n")
        
        // Upcoming bills next 30 days
        let upcoming = budgetController.upcomingPayments(
            bills: activeBills, from: now,
            to:    cal.date(byAdding: .day, value: 30, to: now)!
        )
        let upcomingLines = upcoming.prefix(5).map { bill -> String in
            let due    = budgetController.nextDueDate(for: bill).map { formatDate($0) } ?? "unknown"
            let status = bill.isPaid ? " (paid)" : ""
            return "  • \(bill.name): $\(String(format: "%.2f", bill.amount)) due \(due)\(status)"
        }.joined(separator: "\n")
        
        // All active bills summary
        let allBillsLines = activeBills
            .sorted { $0.amount > $1.amount }
            .map { "  • \($0.name): $\(String(format: "%.2f", $0.amount))/\($0.frequencyRaw), paid: \($0.isPaid)" }
            .joined(separator: "\n")
        
        return """
        Date: \(formatDate(now))
        Spent today: $\(formatDecimal(todayTotal))
        Spent this week: $\(formatDecimal(weekTotal))
        Spent this month: $\(formatDecimal(monthTotal))
        Total income logged: $\(formatDecimal(totalIncome))
        Monthly bills total: $\(formatDecimal(monthlyBills))
        Remaining monthly budget: $\(formatDecimal(remaining))
        
        Spending by category this month:
        \(categoryLines.isEmpty ? "  None" : categoryLines)
        
        All active bills (\(activeBills.count)):
        \(allBillsLines.isEmpty ? "  None" : allBillsLines)
        
        Upcoming bills (next 30 days):
        \(upcomingLines.isEmpty ? "  None" : upcomingLines)
        """
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Category helpers
    // ─────────────────────────────────────────────────────────────────────────
    
    private func findOrCreateCategory(named rawName: String) -> Category {
        let normalised = normaliseCategory(rawName)
        
        // Exact match first
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { $0.name == normalised }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        
        // Case-insensitive fallback
        let all = (try? modelContext.fetch(FetchDescriptor<Category>())) ?? []
        if let match = all.first(where: {
            $0.name.lowercased() == normalised.lowercased()
        }) { return match }
        
        // Create new
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
        case "food", "groceries", "restaurant", "dining", "eating out": return "Food"
        case "rent", "housing", "mortgage":                             return "Housing"
        case "gas", "fuel", "transportation", "car", "uber", "lyft":   return "Transportation"
        case "shopping", "clothes", "clothing":                         return "Shopping"
        case "utilities", "electricity", "water", "internet":          return "Utilities"
        case "entertainment", "movies", "games":                        return "Entertainment"
        case "healthcare", "medical", "pharmacy", "health":             return "Healthcare"
        case "insurance":                                               return "Insurance"
        case "subscriptions", "subscription":                           return "Subscriptions"
        case "education", "school", "tuition":                          return "Education"
        case "savings", "saving":                                       return "Savings"
        case "debt", "loan", "credit card":                             return "Debt"
        case "gifts", "donations", "charity":                           return "Gifts & Donations"
        case "travel", "vacation", "hotel", "flights":                  return "Travel"
        case "personal care", "salon", "barber", "beauty":             return "Personal Care"
        default: return raw.isEmpty ? "Miscellaneous" : raw.capitalized
        }
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Due date computation
    // ─────────────────────────────────────────────────────────────────────────
    
    private func computeDueDate(rule: DueRule, frequency: IntentFrequency) -> Date {
        let cal  = Calendar.current
        let now  = Date()
        var comp = cal.dateComponents([.year, .month], from: now)
        
        switch rule {
        case .dayOfMonth(let r):
            comp.day = r.day
            if let candidate = cal.date(from: comp), candidate < now {
                comp.month! += (frequency == .biMonthly ? 2 : 1)
            }
            return cal.date(from: comp) ?? now
            
        case .nthWeekday(let r):
            let targetWeekday = r.weekday.rawValue
            let targetWeek    = r.weekOfMonth
            for monthOffset in 0...2 {
                var search = comp
                search.day = 1
                if monthOffset > 0 { search.month! += monthOffset }
                guard let firstOfMonth = cal.date(from: search) else { continue }
                let firstWeekday = cal.component(.weekday, from: firstOfMonth)
                let daysToFirst  = (targetWeekday - firstWeekday + 7) % 7
                let daysToAdd    = daysToFirst + (targetWeek - 1) * 7
                guard let candidate = cal.date(
                    byAdding: .day, value: daysToAdd, to: firstOfMonth
                ) else { continue }
                let sameMonth = cal.component(.month, from: candidate)
                == cal.component(.month, from: firstOfMonth)
                guard sameMonth else { continue }
                if candidate > now || monthOffset > 0 { return candidate }
            }
            return now
            
        case .unspecified:
            comp.day    = 1
            comp.month! += 1
            return cal.date(from: comp) ?? now
        }
    }
    
    private func describeDueRule(_ rule: DueRule, frequency: IntentFrequency) -> String {
        switch rule {
        case .dayOfMonth(let r): return "on the \(ordinal(r.day)) of each period"
        case .nthWeekday(let r): return "on the \(ordinal(r.weekOfMonth)) \(weekdayName(r.weekday)) of each period"
        case .unspecified:       return ""
        }
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Reminder scheduling
    // ─────────────────────────────────────────────────────────────────────────
    
    private func scheduleReminder(for bill: Transaction) {
        guard let dueDate = bill.dueDate else { return }
        let cal = Calendar.current
        guard let reminderDate = cal.date(byAdding: .day, value: -3, to: dueDate) else { return }
        
        var triggerComps    = cal.dateComponents([.year, .month, .day], from: reminderDate)
        triggerComps.hour   = bill.remindHour   ?? 9
        triggerComps.minute = bill.remindMinute ?? 0
        
        let content   = UNMutableNotificationContent()
        content.title = "Bill due soon: \(bill.name)"
        content.body  = "$\(String(format: "%.2f", bill.amount)) is due in 3 days."
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: triggerComps,
            repeats:      bill.frequency == .monthly
        )
        let request = UNNotificationRequest(
            identifier: "bill-reminder-\(bill.id.uuidString)",
            content:    content,
            trigger:    trigger
        )
        UNUserNotificationCenter.current().add(request)
        
        bill.remindMe     = true
        bill.remindDay    = triggerComps.day
        bill.remindHour   = triggerComps.hour   ?? 9
        bill.remindMinute = triggerComps.minute ?? 0
        try? modelContext.save()
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Dollar amount extraction
    // ─────────────────────────────────────────────────────────────────────────
    
    private func extractDollarAmount(from text: String) -> Double? {
        let cleaned = text
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
        let pattern = #"(\d+(?:\.\d{1,2})?)"#
        if let range = cleaned.range(of: pattern, options: .regularExpression),
           let value = Double(cleaned[range]) {
            return value
        }
        return nil
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Utilities
    // ─────────────────────────────────────────────────────────────────────────
    
    private func isAffirmative(_ s: String) -> Bool {
        ["yes", "yeah", "yep", "sure", "ok", "okay", "please",
         "yup", "absolutely", "do it", "set it", "go ahead"]
            .contains(where: { s.contains($0) })
    }
    
    private func isNegative(_ s: String) -> Bool {
        ["no", "nope", "nah", "don't", "skip", "not now", "no thanks"]
            .contains(where: { s.contains($0) })
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
        let f = NumberFormatter()
        f.numberStyle = .ordinal
        return f.string(from: NSNumber(value: n)) ?? "\(n)th"
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

import SwiftUI
import StoreKit

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Review trigger tracking (AppStorage-backed, persists across launches)
// ─────────────────────────────────────────────────────────────────────────────

/// Centralises all AppStorage keys so there's no risk of typos elsewhere.
private enum ReviewStorageKey {
    static let hasReviewed          = "finance_chat_has_reviewed"
    static let completedActionCount = "finance_chat_completed_action_count"
    static let lastReviewPromptDate = "finance_chat_last_review_prompt_date"
}

/// How many successful actions (expense logged, bill added, income logged,
/// bill marked paid) must happen before we consider showing the prompt.
private let reviewActionThreshold = 5

/// Minimum number of days between review prompt attempts (so we never pester
/// the user repeatedly even if the threshold keeps being hit).
private let reviewPromptCooldownDays = 60

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - FinanceChatView
// ─────────────────────────────────────────────────────────────────────────────

@available(iOS 26.0, *)
struct FinanceChatView: View {
    @Environment(\.modelContext)    private var modelContext
    @Environment(BudgetController.self) private var budgetController
    @Environment(\.requestReview)   private var requestReview
    
    // ── Chat manager ──────────────────────────────────────────────────────────
    
    @State private var manager: FinanceChatController?
    @State private var inputText = ""
    
    // ── Scroll anchor ─────────────────────────────────────────────────────────
    //
    // A dedicated bottom-anchor ID lets us scroll to it independently of the
    // message list length. We track both message count AND the text of the last
    // message (so streaming token updates also trigger the scroll).
    
    private let bottomAnchorID = "chat_bottom_anchor"
    
    // ── Review state (persisted via AppStorage) ───────────────────────────────
    
    @AppStorage(ReviewStorageKey.hasReviewed)
    private var hasReviewed: Bool = false
    
    @AppStorage(ReviewStorageKey.completedActionCount)
    private var completedActionCount: Int = 0
    
    /// Stored as a TimeInterval (Double) since AppStorage doesn't support Date directly.
    @AppStorage(ReviewStorageKey.lastReviewPromptDate)
    private var lastReviewPromptDateInterval: Double = 0
    
    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Body
    // ─────────────────────────────────────────────────────────────────────────
    
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
    
    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Message list
    // ─────────────────────────────────────────────────────────────────────────
    
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    if let manager {
                        if manager.messages.isEmpty {
                            emptyStateView
                        }
                        
                        ForEach(manager.messages) { message in
                            messageBubble(message).id(message.id)
                        }
                        
                        // Loading indicator — only when waiting for the first
                        // token; streaming messages get their own live bubble.
                        if manager.isLoading && manager.messages.last?.isUser == true {
                            loadingBubble
                        }
                        
                    } else {
                        ProgressView("Initialising…").padding()
                    }
                    
                    // Invisible zero-height anchor always at the very bottom.
                    Color.clear
                        .frame(height: 1)
                        .id(bottomAnchorID)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            // Scroll to bottom whenever the message count changes (new message added).
            .onChange(of: manager?.messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
                handlePostActionReviewCheck()
            }
            // Scroll to bottom while a message is being streamed (text changes).
            .onChange(of: manager?.messages.last?.text) { _, _ in
                scrollToBottom(proxy: proxy, animated: false)
            }
            // Scroll to bottom when the loading bubble appears/disappears.
            .onChange(of: manager?.isLoading) { _, _ in
                scrollToBottom(proxy: proxy)
            }
        }
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Scroll helper
    // ─────────────────────────────────────────────────────────────────────────
    
    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = true) {
        if animated {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(bottomAnchorID, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(bottomAnchorID, anchor: .bottom)
        }
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Message bubble
    // ─────────────────────────────────────────────────────────────────────────
    
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
            // Animates streaming token updates smoothly.
                .animation(.default, value: message.text)
            if !message.isUser { Spacer(minLength: 60) }
        }
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Input bar
    // ─────────────────────────────────────────────────────────────────────────
    
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
    
    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Empty state
    // ─────────────────────────────────────────────────────────────────────────
    
    private var emptyStateView: some View {
        VStack(spacing: 14) {
            Image(systemName: "sparkles").font(.system(size: 48)).foregroundStyle(.blue)
            Text("Finance Assistant").font(.headline)
            Text("Try saying:").font(.subheadline).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 6) {
                suggestionChip("Rent is $1,200 every month on the 1st")
                suggestionChip("Water bill is $85 every other month on the 19th")
                suggestionChip("I spent $42 at Trader Joe's")
                suggestionChip("I made $400 from Uber this week")
                suggestionChip("I paid my Netflix")
                suggestionChip("What bills do I have?")
                suggestionChip("What's due this week?")
                suggestionChip("Break down my spending by category")
                suggestionChip("How much have I spent today?")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
        .multilineTextAlignment(.center)
    }
    
    @ViewBuilder
    private func suggestionChip(_ text: String) -> some View {
        Button { inputText = text; send() } label: {
            Text(text)
                .font(.footnote)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Color(.secondarySystemBackground))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Loading bubble
    // ─────────────────────────────────────────────────────────────────────────
    
    private var loadingBubble: some View {
        HStack {
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { _ in
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
    
    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Send
    // ─────────────────────────────────────────────────────────────────────────
    
    private func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let manager, !manager.isLoading else { return }
        inputText = ""
        Task { await manager.sendMessage(text) }
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Review logic
    // ─────────────────────────────────────────────────────────────────────────
    
    /// Called after the message count changes — i.e. after the assistant has
    /// just finished replying to a completed action (expense logged, bill added,
    /// income logged, bill marked paid). We only ever check after an assistant
    /// reply, never mid-stream or while the user is typing.
    private func handlePostActionReviewCheck() {
        guard let manager else { return }
        
        // Only react to assistant replies (isUser == false) and only when
        // the assistant has just finished (not loading).
        guard
            manager.messages.last?.isUser == false,
            !manager.isLoading
        else { return }
        
        // Never prompt again once the user has already reviewed.
        guard !hasReviewed else { return }
        
        // Count this as a completed interaction if the reply looks like a
        // successful action confirmation (not an error or a question back).
        if looksLikeSuccessfulAction(manager.messages.last?.text ?? "") {
            completedActionCount += 1
        }
        
        // Only prompt after the threshold has been crossed.
        guard completedActionCount >= reviewActionThreshold else { return }
        
        // Enforce cooldown so we don't ask every single session.
        let lastPrompt = Date(timeIntervalSince1970: lastReviewPromptDateInterval)
        let cooldown   = Calendar.current.date(
            byAdding: .day, value: reviewPromptCooldownDays, to: lastPrompt
        ) ?? .distantPast
        
        guard Date() >= cooldown else { return }
        
        // All conditions met — request the review and record the attempt.
        // StoreKit throttles this to a maximum of 3 times per 365 days
        // regardless of how often we call it, so it's safe to call freely.
        lastReviewPromptDateInterval = Date().timeIntervalSince1970
        requestReview()
        
        // Mark as reviewed so we stop tracking entirely. StoreKit's own
        // throttle is the safety net; this prevents us wasting API calls.
        hasReviewed = true
    }
    
    /// Heuristic: the reply is a successful action confirmation if it doesn't
    /// start with an error phrase and isn't a clarifying question.
    /// This keeps review prompting tied to positive moments, not parse failures.
    private func looksLikeSuccessfulAction(_ reply: String) -> Bool {
        guard !reply.isEmpty else { return false }
        let lower = reply.lowercased()
        
        // Exclude error/fallback replies
        let errorPhrases = [
            "couldn't parse",
            "couldn't find",
            "try again",
            "rephrase",
            "not sure",
            "which bill",
            "how much is your",
        ]
        for phrase in errorPhrases {
            if lower.contains(phrase) { return false }
        }
        
        // A reply that contains a dollar amount is almost certainly a
        // successful log or query response — a good moment.
        let hasDollarAmount = lower.range(
            of: #"\$\d"#, options: .regularExpression
        ) != nil
        
        return hasDollarAmount
    }
}
