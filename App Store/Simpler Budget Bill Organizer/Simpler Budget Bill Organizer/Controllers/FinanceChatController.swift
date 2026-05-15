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

/// All multi-turn states the chat controller can be in.
/// Add new cases here rather than nesting optional flags.
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


import FoundationModels

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

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - FinanceChatController (complete, merged, no extensions required)
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
    // extractionSession is recreated on every call — it is intentionally
    // stateless so it never accumulates history and never overflows the
    // context window. Storing it would burn tokens for no benefit.
    //
    // replySession is stateful (keeps turn history for contextual replies)
    // and is rebuilt automatically when it overflows.

    private var replySession:         LanguageModelSession
    private let clarificationSession: LanguageModelSession

    // ── State machine ─────────────────────────────────────────────────────────

    private var conversationState: ConversationState = .idle

    // ── Reply session personality (shared between init and rebuild) ───────────

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
                Classify the user message into one of four intents and fill in
                the structured fields precisely.

                Intent rules:
                - addExpense: user spent money (one-time purchase or payment)
                - addIncome:  user received or earned money
                - addBill:    recurring bill, subscription, or regular payment
                - question:   user asking about their financial situation

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

                For question kind, map to: spentToday, spentThisWeek,
                spentThisMonth, neededToday, neededThisWeek,
                remainingBudget, totalIncome, or general.
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
                await appendReply(reply)
            } else {
                await appendReply("How much is your \(partial.name) bill?")
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
            await appendReply(reply)

        } catch {
            #if DEBUG
            print("[Extraction error] \(type(of: error)): \(error)")
            #endif

            // Check description for context overflow since the exact error
            // type may vary across beta builds of FoundationModels.
            let desc = "\(error)".lowercased()
            if desc.contains("context") || desc.contains("length") || desc.contains("token") {
                // Shouldn't happen with a fresh session, but handle defensively.
                await appendReply("Hit a memory limit on that one — try again.")
            } else {
                await appendReply("Couldn't parse that — could you rephrase?")
            }
        }
    }

    private func repairIntent(_ intent: FinanceIntent, originalText: String) -> FinanceIntent {
        switch intent {
        case .addBill(var input):
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
        case .addExpense(let input): return await handleAddExpense(input)
        case .addIncome(let input):  return await handleAddIncome(input)
        case .addBill(let input):    return await handleAddBill(input)
        case .question(let input):   return await handleQuestion(input, originalText: originalText)
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

    private func handleQuestion(_ input: QuestionInput, originalText: String) async -> String {
        let data = fetchCurrentData()
        let cal  = Calendar.current
        let now  = Date()

        switch input.kind {

        case .spentToday:
            let total = data.expenses
                .filter { cal.isDateInToday($0.date) }
                .reduce(Decimal(0)) { $0 + $1.amount }
            let weekStart = cal.date(from: cal.dateComponents(
                [.yearForWeekOfYear, .weekOfYear], from: now))!
            let weekSoFar = data.expenses
                .filter { $0.date >= weekStart }
                .reduce(Decimal(0)) { $0 + $1.amount }
            return await questionReply(
                answer: "Spent $\(formatDecimal(total)) today.",
                hint:   "$\(formatDecimal(weekSoFar)) so far this week."
            )

        case .spentThisWeek:
            let weekStart = cal.date(from: cal.dateComponents(
                [.yearForWeekOfYear, .weekOfYear], from: now))!
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

        case .remainingBudget:
            let activeBills = data.bills.filter { $0.isActive }
            let remaining   = budgetController.remainingBudget(
                bills:    activeBills,
                expenses: data.expenses,
                incomes:  data.incomes,
                for:      .monthly
            )
            return await questionReply(answer: "$\(formatDecimal(remaining)) remaining this month.")

        case .totalIncome:
            let total = budgetController.totalIncome(data.incomes)
            return await questionReply(answer: "Logged $\(formatDecimal(total)) income total.")

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
                return "Try asking about spending, income, or your budget."
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Reply helpers
    // ─────────────────────────────────────────────────────────────────────────

    /// Full engaging reply with insight context injection.
    /// Automatically rebuilds the reply session on context overflow and retries.
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

            let desc = "\(error)".lowercased()
            let isOverflow = desc.contains("context") || desc.contains("length") || desc.contains("token")

            if isOverflow {
                // Rebuild and retry once with a fresh session.
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
            return answer
        }
    }

    private func appendReply(_ text: String) async {
        await MainActor.run {
            messages.append(Message(text: text, isUser: false))
        }
    }

    private func appendStreamingReply(for summary: String) async {
        let placeholder = Message(text: "", isUser: false)
        messages.append(placeholder)
        guard let idx = messages.indices.last else { return }

        let prompt = Prompt { "Turn this into a single friendly reply: \(summary)" }
        do {
            for try await partial in replySession.streamResponse(to: prompt) {
                await MainActor.run {
                    guard messages.indices.contains(idx) else { return }
                    messages[idx].text = partial.content
                }
            }
        } catch {
            // On overflow during streaming, rebuild session and show the summary.
            let desc = "\(error)".lowercased()
            if desc.contains("context") || desc.contains("length") || desc.contains("token") {
                replySession = Self.makeReplySession()
            }
            #if DEBUG
            print("[Streaming error] \(error)")
            #endif
            await MainActor.run {
                guard messages.indices.contains(idx) else { return }
                messages[idx].text = summary
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Insight context builder
    // ─────────────────────────────────────────────────────────────────────────

    private func buildInsightContext(for intent: FinanceIntent, data: FinancialData) -> String {
        let cal = Calendar.current
        let now = Date()
        var lines: [String] = []

        if case .addExpense(let input) = intent {
            let weekStart  = cal.date(from: cal.dateComponents(
                [.yearForWeekOfYear, .weekOfYear], from: now))!
            let vendorHits = data.expenses.filter {
                $0.date >= weekStart &&
                $0.vendor.lowercased() == input.vendor.lowercased()
            }.count
            if vendorHits >= 2 {
                lines.append("vendor_streak: \(input.vendor) × \(vendorHits) this week")
            }

            let thisMonthStart = cal.date(from: cal.dateComponents([.year, .month], from: now))!
            let lastMonthStart = cal.date(byAdding: .month, value: -1, to: thisMonthStart)!

            let thisMonthCat = data.expenses
                .filter { $0.date >= thisMonthStart && $0.category?.name == input.category }
                .reduce(Decimal(0)) { $0 + $1.amount }
            let lastMonthCat = data.expenses
                .filter {
                    $0.date >= lastMonthStart &&
                    $0.date < thisMonthStart &&
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

        let activeBills = data.bills.filter { $0.isActive }
        let next7days   = cal.date(byAdding: .day, value: 7, to: now)!
        let upcoming    = budgetController.upcomingPayments(
            bills: activeBills, from: now, to: next7days)
        if !upcoming.isEmpty {
            let names = upcoming.prefix(2).map { $0.name }.joined(separator: ", ")
            lines.append("upcoming_bills_7d: \(names)")
        }

        if case .addBill = intent {
            let subCount = data.bills.filter { $0.isActive && $0.frequency == .monthly }.count
            lines.append("active_subscriptions: \(subCount)")
        }

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
        let weekStart  = cal.date(from: cal.dateComponents(
            [.yearForWeekOfYear, .weekOfYear], from: now))!
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
        let upcoming = budgetController.upcomingPayments(
            bills: activeBills, from: now,
            to:    cal.date(byAdding: .day, value: 30, to: now)!
        )
        let upcomingLines = upcoming.prefix(5).map { bill -> String in
            let due = budgetController.nextDueDate(for: bill)
                .map { formatDate($0) } ?? "unknown"
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

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Category helpers
    // ─────────────────────────────────────────────────────────────────────────

    private func findOrCreateCategory(named rawName: String) -> Category {
        let normalised = normaliseCategory(rawName)
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { $0.name == normalised }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let all = (try? modelContext.fetch(FetchDescriptor<Category>())) ?? []
        if let match = all.first(where: {
            $0.name.lowercased() == normalised.lowercased()
        }) { return match }

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
        guard let reminderDate = cal.date(
            byAdding: .day, value: -3, to: dueDate
        ) else { return }

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
                        if manager.messages.isEmpty { emptyStateView }
                        ForEach(manager.messages) { message in
                            messageBubble(message).id(message.id)
                        }
                        if manager.isLoading {
                            // Only show the loading bubble if the last message
                            // is from the user — streaming messages have their
                            // own live bubble so we don't double-up.
                            if manager.messages.last?.isUser == true {
                                loadingBubble.id("loading")
                            }
                        }
                    } else {
                        ProgressView("Initialising…").padding()
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
        }
    }

    // ── Bubble (now animates text changes for streaming) ──────────────────────

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
                // Animate text changes so streaming tokens feel smooth
                .animation(.default, value: message.text)
            if !message.isUser { Spacer(minLength: 60) }
        }
    }

    // ── Input bar, empty state, loading bubble, send — unchanged from v1 ──────
    // (keep your existing implementations here)

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

    private var loadingBubble: some View {
        HStack {
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle().fill(Color.secondary.opacity(0.5)).frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            Spacer(minLength: 60)
        }
    }

    private func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let manager, !manager.isLoading else { return }
        inputText = ""
        Task { await manager.sendMessage(text) }
    }
}
