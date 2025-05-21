import SwiftUI

enum ExpenseCategory: String, CaseIterable, Identifiable {
    case housing
    case transportation
    case food
    case utilities
    case insurance
    case healthcare
    case entertainment
    case personalCare
    case education
    case savings
    case debt
    case gifts
    case travel
    case subscriptions
    case miscellaneous
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .housing: return "Housing"
        case .transportation: return "Transportation"
        case .food: return "Food"
        case .utilities: return "Utilities"
        case .insurance: return "Insurance"
        case .healthcare: return "Healthcare"
        case .entertainment: return "Entertainment"
        case .personalCare: return "Personal Care"
        case .education: return "Education"
        case .savings: return "Savings"
        case .debt: return "Debt"
        case .gifts: return "Gifts & Donations"
        case .travel: return "Travel"
        case .subscriptions: return "Subscriptions"
        case .miscellaneous: return "Miscellaneous"
        }
    }
    
    var symbolName: String {
        switch self {
        case .housing: return "house.fill"
        case .transportation: return "car.fill"
        case .food: return "fork.knife"
        case .utilities: return "bolt.fill"
        case .insurance: return "shield.lefthalf.filled"
        case .healthcare: return "cross.case.fill"
        case .entertainment: return "gamecontroller.fill"
        case .personalCare: return "figure.wave"
        case .education: return "book.fill"
        case .savings: return "banknote.fill"
        case .debt: return "creditcard.fill"
        case .gifts: return "gift.fill"
        case .travel: return "airplane"
        case .subscriptions: return "doc.text.fill"
        case .miscellaneous: return "ellipsis"
        }
    }
    
    var icon: Image {
        Image(systemName: symbolName)
    }
}
