import SwiftUI
import SwiftData

// MARK: - SwiftData Models
typealias Expense = BudgetSchemaV2.Expense
typealias Transaction = BudgetSchemaV2.Transaction

@main
struct Simpler_Budget_Bill_OrganizerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var subscriptionController = SubscriptionController()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [Transaction.self, Expense.self, Income.self, Category.self])
                .environment(subscriptionController)
        }
    }
}

enum BudgetMigrationPlan: SchemaMigrationPlan {
    static var schemas: [VersionedSchema.Type] {
        [
            BudgetSchemaV1.self,
            BudgetSchemaV2.self
        ]
    }
    
    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }
    
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: BudgetSchemaV1.self,
        toVersion: BudgetSchemaV2.self,
        willMigrate: { _ in
            // ?
        },
        didMigrate: { context in
            // 1) build your categoryCache as above
            var categoryCache: [String: Category] = [:]
            
            for expenseCategory in ExpenseCategory.allCases {
                let category = Category(
                    name: expenseCategory.label,
                    icon: expenseCategory.symbolName,
                    isDefault: true
                )
                context.insert(category)
                
                // Cache by both normalized rawValue and label.lowercased()
                let rawKey = expenseCategory.rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                categoryCache[rawKey] = category
                
                let labelKey = expenseCategory.label.lowercased()
                categoryCache[labelKey] = category
            }
            
            try? context.save()
            
            // Resolve function using ExpenseCategory safely
            func resolveCategory(from raw: String) -> Category {
                let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                
                if let cached = categoryCache[normalized] {
                    return cached
                } else {
                    let fallback = Category(name: raw.capitalized, icon: "questionmark.circle", isDefault: false)
                    context.insert(fallback)
                    categoryCache[normalized] = fallback
                    return fallback
                }
            }
            
            // Migrate Expenses
            let oldExpenses = try context.fetch(FetchDescriptor<BudgetSchemaV1.Expense>())
            for oldExpense in oldExpenses {
                let category = resolveCategory(from: oldExpense.categoryRaw)
                let newExpense = BudgetSchemaV2.Expense(
                    amount: oldExpense.amount,
                    vendor: oldExpense.vendor,
                    date: oldExpense.date,
                    category: category
                )
                context.insert(newExpense)
            }
            
            // Migrate Transactions
            let oldTransactions = try context.fetch(FetchDescriptor<BudgetSchemaV1.Transaction>())
            for oldTransaction in oldTransactions {
                let category = resolveCategory(from: oldTransaction.categoryRaw)
                let newTransaction = BudgetSchemaV2.Transaction(
                    name: oldTransaction.name,
                    amount: oldTransaction.amount,
                    frequency: BillFrequency(rawValue: oldTransaction.frequencyRaw) ?? .monthly,
                    category: category,
                    dueDate: oldTransaction.dueDate,
                    isAutoPaid: oldTransaction.isAutoPaid,
                    isPaid: oldTransaction.isPaid,
                    notes: oldTransaction.notes,
                    startDate: oldTransaction.startDate,
                    endDate: oldTransaction.endDate,
                    vendor: oldTransaction.vendor,
                    isActive: oldTransaction.isActive,
                    currencyCode: oldTransaction.currencyCode,
                    remindMe: oldTransaction.remindMe,
                    remindDay: oldTransaction.remindDay,
                    remindHour: oldTransaction.remindHour,
                    remindMinute: oldTransaction.remindMinute
                )
                context.insert(newTransaction)
            }
        }
    )
}


class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            print("Notification permission granted: \(granted)")
        }
        return true
    }

    // Foreground handling
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
