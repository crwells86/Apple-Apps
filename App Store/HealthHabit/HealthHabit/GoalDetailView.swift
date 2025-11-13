import SwiftUI

struct GoalDetailView: View {
    let goal: Goal
    let viewModel: HealthViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTimeRange: TimeRange = .week
    @State private var chartData: [DailyGoalData] = []
    @State private var isLoading = false
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case threeMonths = "3 Months"
        case year = "Year"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            case .year: return 365
            }
        }
    }
    
    var color: Color {
        Color(hex: goal.colorHex) ?? .green
    }
    
    var completionRate: Double {
        guard !chartData.isEmpty else { return 0 }
        let completed = chartData.filter { $0.goalMet }.count
        return Double(completed) / Double(chartData.count) * 100
    }
    
    var averageValue: Double {
        guard !chartData.isEmpty else { return 0 }
        let total = chartData.reduce(0.0) { $0 + $1.value }
        return total / Double(chartData.count)
    }
    
    var totalValue: Double {
        chartData.reduce(0.0) { $0 + $1.value }
    }
    
    var bestDay: DailyGoalData? {
        chartData.max { $0.value < $1.value }
    }
    
    var currentStreak: Int {
        var streak = 0
        let sortedData = chartData.sorted { $0.date > $1.date }
        for data in sortedData {
            if data.goalMet {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }
    
    var longestStreak: Int {
        var currentStreak = 0
        var maxStreak = 0
        let sortedData = chartData.sorted { $0.date < $1.date }
        
        for data in sortedData {
            if data.goalMet {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        return maxStreak
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    // Header with icon and goal info
                    HStack(alignment: .top) {
                        Image(systemName: goal.type.icon)
                            .font(.system(size: 60))
                            .foregroundStyle(.white)
                            .frame(width: 100, height: 100)
                            .background(Circle().fill(color))
                        
                        VStack(alignment: .leading) {
                            Text(goal.type.rawValue)
                                .font(.title.bold())
                            
                            Text("Goal: \(Int(goal.target)) \(goal.type.unit)")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    
                    // Time range picker
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: selectedTimeRange) { _, _ in
                        loadChartData()
                    }
                    
                    // Stats Overview
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            StatCard(
                                title: "Completion",
                                value: String(format: "%.0f%%", completionRate),
                                icon: "checkmark.circle.fill",
                                color: color
                            )
                            
                            StatCard(
                                title: "Average",
                                value: String(format: "%.0f", averageValue),
                                subtitle: goal.type.unit,
                                icon: "chart.line.uptrend.xyaxis",
                                color: color
                            )
                        }
                        
                        HStack(spacing: 16) {
                            StatCard(
                                title: "Current Streak",
                                value: "\(currentStreak)",
                                subtitle: "days",
                                icon: "flame.fill",
                                color: currentStreak > 0 ? .orange : .gray
                            )
                            
                            StatCard(
                                title: "Best Streak",
                                value: "\(longestStreak)",
                                subtitle: "days",
                                icon: "trophy.fill",
                                color: .yellow
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Progress Chart")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .frame(height: 250)
                        } else if chartData.isEmpty {
                            Text("No data available")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 250)
                        } else {
                            ProgressChartView(data: chartData, goal: goal, color: color)
                                .frame(height: 250)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6).opacity(0.3))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Detailed Stats
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Detailed Statistics")
                            .font(.headline)
                        
                        DetailStatRow(
                            label: "Total \(goal.type.unit)",
                            value: String(format: "%.0f", totalValue),
                            icon: "sum"
                        )
                        
                        if let best = bestDay {
                            DetailStatRow(
                                label: "Best Day",
                                value: String(format: "%.0f %@ on %@", best.value, goal.type.unit, formatDate(best.date)),
                                icon: "star.fill"
                            )
                        }
                        
                        DetailStatRow(
                            label: "Days Tracked",
                            value: "\(chartData.count)",
                            icon: "calendar"
                        )
                        
                        DetailStatRow(
                            label: "Goals Met",
                            value: "\(chartData.filter { $0.goalMet }.count) / \(chartData.count)",
                            icon: "target"
                        )
                    }
                    .padding()
                    .background(colorScheme == .dark ? Color(.systemGray6) : .white)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Daily breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Daily Breakdown")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(chartData.sorted { $0.date > $1.date }, id: \.date) { data in
                                DailyBreakdownRow(data: data, goal: goal, color: color)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle("Goal Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadChartData()
            }
        }
    }
    
    private func loadChartData() {
        isLoading = true
        let calendar = Calendar.current
        let today = Date()
        let startDate = calendar.date(byAdding: .day, value: -selectedTimeRange.days, to: today)!
        
        chartData = viewModel.dailyData.filter { data in
            data.goalID == goal.id &&
            data.date >= calendar.startOfDay(for: startDate) &&
            data.date <= calendar.startOfDay(for: today)
        }.sorted { $0.date < $1.date }
        
        isLoading = false
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    let icon: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.primary)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : .white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Detail Stat Row
struct DetailStatRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 30)
            
            Text(label)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Text(value)
                .foregroundStyle(.secondary)
                .bold()
        }
        .font(.subheadline)
    }
}


// MARK: - Daily Breakdown Row
struct DailyBreakdownRow: View {
    let data: DailyGoalData
    let goal: Goal
    let color: Color
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: data.date)
    }
    
    var progressPercent: Double {
        min(data.value / goal.target, 1.0)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: data.goalMet ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(data.goalMet ? color : .gray)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(dateString)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color.opacity(0.8))
                            .frame(width: geometry.size.width * progressPercent)
                    }
                }
                .frame(height: 6)
            }
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.0f", data.value))
                    .font(.subheadline.bold())
                Text(goal.type.unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(10)
    }
}

// MARK: - Progress Chart View
struct ProgressChartView: View {
    let data: [DailyGoalData]
    let goal: Goal
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var maxValue: Double {
        max(data.map { $0.value }.max() ?? goal.target, goal.target) * 1.1
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Goal line
                Path { path in
                    let y = geometry.size.height - (CGFloat(goal.target / maxValue) * geometry.size.height)
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
                .stroke(color.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                
                // Bar chart
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                        VStack {
                            Spacer()
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(item.goalMet ? color : color.opacity(0.4))
                                .frame(height: max(CGFloat(item.value / maxValue) * geometry.size.height, 2))
                        }
                    }
                }
            }
        }
        .padding(.vertical)
    }
}
