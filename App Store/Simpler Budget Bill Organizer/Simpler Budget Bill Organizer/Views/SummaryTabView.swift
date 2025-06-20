import SwiftUI
import SwiftData


import Charts

struct SummaryTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) var expenses: [Expense]
    @Query(sort: \Transaction.dueDate) var transactions: [Transaction]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    SectionHeader(icon: "chart.bar.fill", title: "Spending by Vendor", accent: .green)
                    
                    ChartView(data: vendorTotals)
                        .frame(height: 220)
                        .padding(.horizontal, 4)
                    
                    SectionHeader(icon: "creditcard.fill", title: "Total Spent This Month", accent: .purple)
                    
                    Text(totalThisMonth.formatted(.currency(code: "USD")))
                        .font(.largeTitle.bold())
                        .foregroundStyle(LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing))
                        .padding(.horizontal, 4)
                    
                    SectionHeader(icon: "calendar.circle.fill", title: "Upcoming Bills", accent: .pink)
                    
                    ForEach(upcomingTransactions.prefix(3)) { tx in
                        BillCard(transaction: tx)
                            .padding(.horizontal, 4)
                    }
                    
                    SectionHeader(icon: "clock.fill", title: "Recent Expenses", accent: .blue)
                    ForEach(expenses.prefix(5)) { expense in
                        ExpenseRow(expense: expense)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(.vertical, 20)
                .padding(.horizontal)
            }
            .background(.ultraThinMaterial)
        }
    }
    
    var upcomingTransactions: [Transaction] {
        transactions.filter { tx in
            tx.isActive &&
            !tx.isPaid &&
            tx.dueDate.map { due in
                let now = Date()
                return due >= now && due <= Calendar.current.date(byAdding: .day, value: 30, to: now)!
            } ?? false
        }
    }
    
    var vendorTotals: [(String, Decimal)] {
        let grouped = Dictionary(grouping: expenses) { $0.vendor }
        return grouped.mapValues { $0.reduce(0) { $0 + $1.amount } }
            .map { ($0.key, $0.value) }
            .sorted { $0.1 > $1.1 }
    }
    
    var totalThisMonth: Decimal {
        let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!
        
        // Sum of regular expenses
        let expenseSum = expenses
            .filter { $0.date >= startOfMonth }
            .reduce(Decimal.zero) { $0 + $1.amount }
        
        // Sum of paid, recurring transactions
        let recurringSum = transactions
            .filter {
                $0.isPaid &&
                ($0.frequencyRaw == "monthly" || $0.dueDate.map { $0 >= startOfMonth } ?? false)
            }
            .reduce(Decimal.zero) { $0 + Decimal($1.amount) }
        
        return expenseSum + recurringSum
    }
}

struct SectionHeader: View {
    let icon: String
    let title: String
    let accent: Color
    
    init(icon: String, title: String, accent: Color) {
        self.icon = icon
        self.title = title
        self.accent = accent
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(accent)
                .font(.title3)
            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.bottom, 8)
        .overlay(
            Rectangle()
                .fill(accent.opacity(0.3))
                .frame(height: 3)
                .cornerRadius(2),
            alignment: .bottom
        )
    }
}

struct BillCard: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                if let dueDate = transaction.dueDate {
                    Text("Due \(dueDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(transaction.amount, format: .currency(code: transaction.currencyCode))
                .font(.headline)
                .foregroundColor(.accentColor)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
        )
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ExpenseRow: View {
    let expense: Expense
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.vendor)
                    .font(.body.weight(.medium))
                    .foregroundColor(.primary)
                Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(expense.amount, format: .currency(code: "USD"))
                .font(.body.weight(.semibold))
                .foregroundColor(.accentColor)
        }
        .padding(.vertical, 6)
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct ChartView: View {
    let data: [(String, Decimal)]
    
    var body: some View {
        let entries = data.map { VendorSpending(vendor: $0.0, amount: $0.1) }
        
        Chart(entries) { item in
            BarMark(
                x: .value("Vendor", item.vendor),
                y: .value("Amount", (item.amount as NSDecimalNumber).doubleValue)
            )
            .foregroundStyle(LinearGradient(
                colors: [.green.opacity(0.8), .green.opacity(0.3)],
                startPoint: .bottom,
                endPoint: .top))
            .cornerRadius(5)
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine().foregroundStyle(.clear)
                AxisTick().foregroundStyle(.gray.opacity(0.5))
                AxisValueLabel()
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .offset(x: -5, y: 0)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .padding(.horizontal, 10)
    }
}

import Foundation

struct VendorSpending: Identifiable {
    let id = UUID()
    let vendor: String
    let amount: Decimal
}
