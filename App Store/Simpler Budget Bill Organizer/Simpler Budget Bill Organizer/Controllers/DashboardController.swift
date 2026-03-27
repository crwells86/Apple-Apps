import SwiftUI
import Foundation

@Observable
class DashboardController {
    var totalBalance: Decimal = 25000.40
    var incomeTotal: Decimal = 20000
    var outcomeTotal: Decimal = 17000
    
    var earnings: [(initial: String, source: String, amount: Decimal, color: Color)] = [
        ("U", "Upwork", 3000, .orange),
        ("F", "Freepik", 3000, .pink),
        ("W", "Envato", 2000, .blue)
    ]
    
    var savings: [(title: String, amount: Decimal, progress: Double, color: Color)] = [
        ("Iphone 13 Mini", 699, 0.2, .red),
        ("Macbook Pro M1", 1499, 0.45, .pink),
        ("Car", 20000, 0.6, .yellow),
        ("House", 30500, 0.8, .blue)
    ]
    
    var transactions: [Transaction] = [
        Transaction(name: "Adobe Illustrator",
                    amount: -32.0,
                    frequency: .monthly,
                    dueDate: nil,
                    isAutoPaid: false,
                    isPaid: true,
                    notes: "Subscription fee",
                    vendor: "Adobe",
                    isActive: true)
    ]
}
