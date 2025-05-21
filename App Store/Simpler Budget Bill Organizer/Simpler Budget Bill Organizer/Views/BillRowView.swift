import SwiftUI

struct BillRowView: View {
    let bill: Transaction
    
    var body: some View {
        HStack(alignment: .top) {
            bill.category.icon
                .foregroundStyle(.accent)
            
            VStack(alignment: .leading) {
                Text(bill.name)
                    .font(.headline)
                
                Text(bill.category.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(bill.amount, format: .currency(code: "USD"))
                Group {
                    if bill.isPaid {
                        Text("Paid")
                            .font(.caption2)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(.green)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    
                    if let dueDate = bill.dueDate {
                        let days = daysUntil(dueDate)
                        Group {
                            if days < 0 && !bill.isPaid {
                                Text("Past due")
                            } else if days == 0 && !bill.isPaid  {
                                Text("Due today")
                            } else if !bill.isPaid  {
                                Text("Due in ^[\(days) day](inflect: true)")
                            }
                        }
                        .font(.caption2)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(backgroundColor(for: dueDate, isPaid: bill.isPaid))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            }
        }
        .onAppear {
            if let dueDate = bill.dueDate, Date() > dueDate {
                if isOneDayPast(bill.dueDate!) {
                    bill.dueDate = Calendar.current.date(byAdding: .month, value: 1, to: dueDate)
                }
            }
        }
    }
    
    func isOneDayPast(_ dueDate: Date) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dueDay = calendar.startOfDay(for: dueDate)
        let diff = calendar.dateComponents([.day], from: dueDay, to: today).day ?? 0
        return diff == 1
    }
    
    private func daysUntil(_ date: Date) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dueDay = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: today, to: dueDay).day ?? 0
    }
    
    private func backgroundColor(for date: Date, isPaid: Bool) -> Color {
        if isPaid {
            return .green
        }
        
        let days = daysUntil(date)
        switch days {
        case ..<1:
            return .red
        case 1...3:
            return .orange
        default:
            return .indigo
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    VStack(spacing: 16) {
        BillRowView(bill: Transaction.sample(dueInDays: 0))
        BillRowView(bill: Transaction.sample(dueInDays: 1))
        BillRowView(bill: Transaction.sample(dueInDays: 3))
        BillRowView(bill: Transaction.sample(dueInDays: 8))
        BillRowView(bill: Transaction.sample(dueInDays: 6, isPaid: true))
    }
    .padding()
}
