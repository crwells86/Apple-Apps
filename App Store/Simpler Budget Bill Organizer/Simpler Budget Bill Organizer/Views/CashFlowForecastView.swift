import SwiftUI
import SwiftData

// A single day's forecasted balance
private struct ForecastEntry: Identifiable {
    let id = UUID()
    let date: Date
    let balance: Double
}

struct CashFlowForecastView: View {
    @Environment(\.modelContext) private var context
    @Query private var transactions: [Transaction]

    // User-tunable inputs with sensible defaults and persistence
    @AppStorage("forecastStartingBalance") private var startingBalance: Double = 0
    @AppStorage("forecastDailyPaceOverride") private var dailyPaceOverride: Double = 0

    @State private var horizon: Int = 30

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    private var today: Date { Calendar.current.startOfDay(for: Date()) }

    // Compute a simple historical daily spend pace using the last 30 days of negative transactions
    // Uses `dueDate` as the transaction date proxy if present.
    private var computedDailyPace: Double {
        let cal = Calendar.current
        guard let start = cal.date(byAdding: .day, value: -30, to: today) else { return 0 }
        let windowExpenses = transactions.filter { txn in
            guard txn.amount < 0 else { return false }
            guard let d = txn.dueDate else { return false }
            return d >= start && d <= today
        }
        let total = windowExpenses.reduce(0.0) { $0 + abs($1.amount) }
        return total / 30.0
    }

    private var dailyPace: Double {
        dailyPaceOverride > 0 ? dailyPaceOverride : computedDailyPace
    }

    // Build the forecast entries day-by-day applying daily pace and scheduled transactions
    private func buildForecast() -> [ForecastEntry] {
        let cal = Calendar.current
        guard let end = cal.date(byAdding: .day, value: horizon, to: today) else { return [] }

        // Pre-group scheduled transactions by day for quick lookup
        let scheduled = transactions.compactMap { txn -> (day: Date, amount: Double)? in
            guard let d = txn.dueDate else { return nil }
            // Only consider items within the horizon window (including today)
            guard d >= today && d <= end else { return nil }
            let day = cal.startOfDay(for: d)
            return (day, txn.amount)
        }

        let groupedByDay: [Date: [Double]] = Dictionary(grouping: scheduled, by: { $0.day }).mapValues { $0.map { $0.amount } }

        var entries: [ForecastEntry] = []
        var balance = startingBalance

        for offset in 0...horizon {
            guard let date = cal.date(byAdding: .day, value: offset, to: today) else { continue }

            // Apply daily spend pace first (represents ongoing discretionary spend)
            balance -= dailyPace

            // Apply scheduled transactions occurring on this day (positive for income, negative for bills)
            if let todays = groupedByDay[cal.startOfDay(for: date)] {
                for amt in todays { balance += amt }
            }

            entries.append(ForecastEntry(date: date, balance: balance))
        }

        return entries
    }

    var body: some View {
        let forecast = buildForecast()
        let riskDays = forecast.filter { $0.balance < 0 }.count
        let lowest = forecast.min(by: { $0.balance < $1.balance })

        VStack(spacing: 16) {
            // Controls
            VStack(spacing: 12) {
                Text("Cash Flow Forecast")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)

                Picker("Horizon", selection: $horizon) {
                    Text("30 days").tag(30)
                    Text("60 days").tag(60)
                    Text("90 days").tag(90)
                }
                .pickerStyle(.segmented)

                HStack(spacing: 12) {
                    VStack(alignment: .leading) {
                        Text("Starting Balance")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("0", value: $startingBalance, format: .currency(code: currencyCode))
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading) {
                        Text("Daily Spend Pace")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Auto", value: $dailyPaceOverride, format: .currency(code: currencyCode))
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .overlay(alignment: .trailing) {
                                if dailyPaceOverride <= 0 && computedDailyPace > 0 {
                                    Text("auto \(computedDailyPace, format: .currency(code: currencyCode))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .padding(.trailing, 8)
                                }
                            }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top)

            // Summary chips
            HStack(spacing: 12) {
                Label("Risk days: \(riskDays)", systemImage: riskDays > 0 ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                    .foregroundStyle(riskDays > 0 ? .red : .green)
                    .padding(8)
                    .background((riskDays > 0 ? Color.red.opacity(0.1) : Color.green.opacity(0.1)))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                if let low = lowest {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Lowest")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(low.balance as NSNumber, formatter: currencyFormatter)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(low.balance < 0 ? .red : .primary)
                    }
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                Spacer()
            }
            .padding(.horizontal)

            // Forecast list
            List {
                Section(header: Text("Projected Balance by Day")) {
                    ForEach(forecast) { entry in
                        HStack {
                            Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                            Spacer()
                            Text("\(entry.balance as NSNumber, formatter: currencyFormatter)")
                                .foregroundStyle(entry.balance < 0 ? .red : .primary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(entry.date.formatted(date: .complete, time: .omitted)) balance \(currencyFormatter.string(from: entry.balance as NSNumber) ?? "")")
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Forecast")
    }

    // MARK: - Formatters
    private var currencyFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = currencyCode
        return f
    }
}

#Preview {
    CashFlowForecastView()
}
