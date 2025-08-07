import Foundation

extension Transaction {
    var frequency: BillFrequency {
        get {
            BillFrequency(rawValue: frequencyRaw) ?? .monthly
        }
        set {
            frequencyRaw = newValue.rawValue
        }
    }
}
