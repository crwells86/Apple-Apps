import SwiftUI

struct BillRowView: View {
    let bill: Transaction
    @Environment(BudgetController.self) private var budget

    var body: some View {
        let nextDueDate = budget.nextDueDate(for: bill)
        let days = nextDueDate.map(daysUntil)

        return HStack(alignment: .top) {
            bill.category.icon
                .foregroundStyle(.accent)

            VStack(alignment: .leading) {
                Text(bill.name).font(.headline)
                Text(bill.category.rawValue).font(.subheadline).foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text(bill.amount, format: .currency(code: "USD"))

                if bill.isPaid {
                    paidTag
                } else if let next = nextDueDate, let d = days {
                    dueTag(days: d, date: next)
                }
            }
        }
    }

    private var paidTag: some View {
        Text("Paid")
            .font(.caption2)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(.green)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private func dueTag(days: Int, date: Date) -> some View {
        let label: String
        if days < 0 {
            label = "Past due"
        } else if days == 0 {
            label = "Due today"
        } else {
            label = "Due in \(days) day\(days == 1 ? "" : "s")"
        }

        return Text(label)
            .font(.caption2)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(backgroundColor(for: date, isPaid: false))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private func daysUntil(_ date: Date) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dueDay = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: today, to: dueDay).day ?? 0
    }

    private func backgroundColor(for date: Date, isPaid: Bool) -> Color {
        if isPaid { return .green }
        let days = daysUntil(date)
        switch days {
        case ..<1: return .red
        case 1...3: return .orange
        default: return .indigo
        }
    }
}


//#Preview(traits: .sizeThatFitsLayout) {
//    VStack(spacing: 16) {
//        BillRowView(bill: Transaction.sample(dueInDays: 0))
//        BillRowView(bill: Transaction.sample(dueInDays: 1))
//        BillRowView(bill: Transaction.sample(dueInDays: 3))
//        BillRowView(bill: Transaction.sample(dueInDays: 8))
//        BillRowView(bill: Transaction.sample(dueInDays: 6, isPaid: true))
//    }
//    .padding()
//}
