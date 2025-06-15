import SwiftUI
import SwiftData

// MARK: - SwiftData Model
@Model class MoodEntry {
    @Attribute(.unique)
    var date: Date
    var mood: MoodType
    var notes: String?
    var tags: [String]
    
    init(date: Date, mood: MoodType, notes: String? = nil, tags: [String] = []) {
        self.date = Calendar.current.startOfDay(for: date)
        self.mood = mood
        self.notes = notes
        self.tags = tags
    }
}

enum MoodType: Int, CaseIterable, Identifiable, Codable {
    case verySad, sad, neutral, happy, veryHappy
    var id: Int { rawValue }
    var emoji: String {
        switch self {
        case .verySad: return "😫"
        case .sad: return "☹️"
        case .neutral: return "😐"
        case .happy: return "🙂"
        case .veryHappy: return "😍"
        }
    }
}

// MARK: - Views
struct ContentView: View {
    @Environment(SubscriptionController.self) var sub
    
    var body: some View {
        TabView {
            MoodCalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
            
            Group {
                if !sub.isSubscribed {
                    StatsView()
                } else {
                    PaywallView()
                }
            }
            .tabItem { Label("Stats", systemImage: "chart.bar") }
            
            Group {
                if !sub.isSubscribed {
                    GoalsView()
                } else {
                    PaywallView()
                }
            }
            .tabItem { Label("Goals", systemImage: "flag") }
        }
    }
}

#Preview {
    ContentView()
}



struct MoodCalendarView: View {
    @Environment(\.modelContext) private var context
    @State private var displayDate: Date = Date()
    @State private var entries: [Date: MoodEntry] = [:]
    @State private var showingDetail = false
    @State private var detailEntry: MoodEntry?
    @State private var tappedDate: Date?
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                header
                
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(daysInGrid(), id: \.self) { date in
                        let dayStart = calendar.startOfDay(for: date)
                        let isFuture = dayStart > calendar.startOfDay(for: Date())
                        let isInMonth = calendar.isDate(date, equalTo: displayDate, toGranularity: .month)
                        let mood = entries[dayStart]?.mood
                        
                        DayCell(
                            date: date,
                            mood: mood,
                            isInMonth: isInMonth
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard isInMonth && !isFuture else { return }
                            tappedDate = dayStart
                            if let entry = entries[dayStart] {
                                detailEntry = entry
                            } else {
                                detailEntry = MoodEntry(date: dayStart, mood: .neutral)
                                showingDetail = true
                            }
                        }
                    }
                }
                .padding(.top)
                
                if let tappedDate, let entry = entries[tappedDate] {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mood for \(tappedDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.headline)
                        HStack {
                            Text(entry.mood.emoji)
                                .font(.largeTitle)
                            if let notes = entry.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(.body)
                            }
                        }
                        if !entry.tags.isEmpty {
                            Text("Tags: \(entry.tags.joined(separator: ", "))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top)
                    .transition(.opacity)
                }
            }
            .padding()
            .onAppear {
                loadEntries()
                tappedDate = calendar.startOfDay(for: Date()) // <- Default to today
            }
            .sheet(isPresented: $showingDetail) {
                if let entry = detailEntry {
                    MoodDetailView(entry: entry) { newEntry in
                        save(entry: newEntry)
                        showingDetail = false
                        tappedDate = newEntry.date
                    }
                }
            }
        }
    }
    
    private var header: some View {
        HStack {
            Button { changeMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(monthTitle)
                .font(.headline)
            Spacer()
            Button { changeMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
            }
        }
    }
    
    private var monthTitle: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "LLLL yyyy"
        return fmt.string(from: displayDate)
    }
    
    private func daysInGrid() -> [Date] {
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: displayDate))!
        let weekdayOffset = calendar.component(.weekday, from: start) - calendar.firstWeekday
        let offset = (weekdayOffset + 7) % 7
        let range = calendar.range(of: .day, in: .month, for: start)!
        var dates: [Date] = []
        for idx in 0..<(offset + range.count) {
            if idx < offset {
                dates.append(Date.distantPast)
            } else {
                dates.append(calendar.date(byAdding: .day, value: idx - offset, to: start)!)
            }
        }
        while dates.count % 7 != 0 { dates.append(Date.distantFuture) }
        return dates
    }
    
    private func loadEntries() {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayDate))!
        var comp = DateComponents(); comp.month = 1; comp.day = -1
        let endOfMonth = calendar.date(byAdding: comp, to: startOfMonth)!
        let descriptor = FetchDescriptor<MoodEntry>(
            predicate: #Predicate<MoodEntry> { entry in
                entry.date >= startOfMonth && entry.date <= endOfMonth
            }
        )
        
        do {
            let results = try context.fetch(descriptor)
            entries = Dictionary(uniqueKeysWithValues: results.map { ($0.date, $0) })
        } catch {
            print("Fetch error: \(error)")
        }
    }
    
    private func changeMonth(by offset: Int) {
        if let newDate = calendar.date(byAdding: .month, value: offset, to: displayDate) {
            displayDate = newDate
            tappedDate = calendar.startOfDay(for: Date()) // Reset to today when changing month
            loadEntries()
        }
    }
    
    private func save(entry: MoodEntry) {
        if context.insertedModelsArray.contains(where: { ($0 as? MoodEntry)?.date == entry.date }) == false {
            context.insert(entry)
        }
        do { try context.save() } catch { print("Save error: \(error)") }
        entries[entry.date] = entry
    }
}


struct DayCell: View {
    let date: Date
    let mood: MoodType?
    let isInMonth: Bool
    
    var body: some View {
        ZStack {
            if let mood = mood {
                Text(mood.emoji)
                    .font(.title3)
                    .opacity(isInMonth ? 1 : 0.25)
            } else if isInMonth && date != Date.distantPast && date != Date.distantFuture {
                Text("\(Calendar.current.component(.day, from: date))")
                    .foregroundColor(.primary)
            }
        }
        .frame(height: 40)
    }
}


struct MoodDetailView: View {
    @State private var entry: MoodEntry
    var onSave: (MoodEntry) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var showAllTags = false
    
    init(entry: MoodEntry, onSave: @escaping (MoodEntry) -> Void) {
        _entry = State(initialValue: entry)
        self.onSave = onSave
    }
    
    private let allTags = MoodTags.all // ← Defined below
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Date") {
                    Text(entry.date, format: .dateTime.year().month().day())
                }
                
                Section("Mood") {
                    Picker("Mood", selection: $entry.mood) {
                        ForEach(MoodType.allCases) { mood in
                            Text(mood.emoji).tag(mood)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Tags") {
                    FlowLayout(tags: Array(entry.tags.prefix(10)), allTags: allTags, entry: $entry)
                    
                    Button("View All Tags") {
                        showAllTags = true
                    }
                    .sheet(isPresented: $showAllTags) {
                        TagSelectionView(entry: $entry, allTags: allTags)
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: Binding(
                        get: { entry.notes ?? "" },
                        set: { entry.notes = $0 }
                    ))
                    .frame(minHeight: 100)
                }
            }
            .navigationTitle("Mood")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(entry)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct FlowLayout: View {
    let tags: [String]
    let allTags: [String]
    @Binding var entry: MoodEntry
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Button(action: {
                    if entry.tags.contains(tag) {
                        entry.tags.removeAll { $0 == tag }
                    } else {
                        entry.tags.append(tag)
                    }
                }) {
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(entry.tags.contains(tag) ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct TagSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var entry: MoodEntry
    let allTags: [String]
    
    @State private var searchText = ""
    
    var filteredTags: [String] {
        if searchText.isEmpty {
            return allTags
        } else {
            return allTags.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredTags, id: \.self) { tag in
                    HStack {
                        Text(tag)
                        Spacer()
                        if entry.tags.contains(tag) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if entry.tags.contains(tag) {
                            entry.tags.removeAll { $0 == tag }
                        } else {
                            entry.tags.append(tag)
                        }
                    }
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("All Tags")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}


enum MoodTags {
    static let all: [String] = [
        "Grateful", "Stressed", "Joyful", "Anxious", "Excited", "Tired", "Focused", "Overwhelmed",
        "Creative", "Lonely", "Hopeful", "Sad", "Inspired", "Frustrated", "Calm", "Restless",
        "Energetic", "Proud", "Lazy", "Motivated", "Embarrassed", "Loved", "Bored", "Peaceful",
        "Angry", "Content", "Worried", "Playful", "Social", "Withdrawn", "Chill", "Surprised",
        "Hungover", "Confident", "Productive", "Distracted", "Heartbroken", "Fulfilled",
        "Adventurous", "Melancholy", "Awake", "Sleepy", "Cheerful", "Irritable", "Appreciated",
        "Ignored", "Silly", "Doubtful", "Clumsy", "Grounded", "Disconnected", "Connected",
        "Romantic", "Jealous", "Nostalgic", "Curious", "Fidgety", "Caffeinated", "Alone",
        "Inspired", "Burned Out", "Focused", "Confused", "On Edge", "Relaxed",
    ]
}
















import SwiftUI
import Charts

// MARK: - Enhanced Stats View
import SwiftUI

import SwiftUI

struct StatsView: View {
    @Environment(\.modelContext) private var context
    @State private var moodEntries: [MoodEntry] = []
    @State private var selectedTimeRange: TimeRange = .week
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    moodSummaryCard
                    moodChartsSection
                    detailedStatsSection
                    goalsSection
                }
                .padding()
            }
            .navigationTitle("Statistics")
            .onAppear { fetchAllMoodEntries() }
        }
    }
    
    // MARK: - Filtered Mood Entries
    private var filteredMoodEntries: [MoodEntry] {
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        
        switch selectedTimeRange {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
        
        return moodEntries.filter { $0.date >= startDate && $0.date <= now }
    }
    
    // MARK: - Mood Summary Card
    private var moodSummaryCard: some View {
        let avgMood = averageMood(from: filteredMoodEntries)
        let bestDay = bestMoodDay(from: filteredMoodEntries)
        let worstDay = worstMoodDay(from: filteredMoodEntries)
        
        return VStack(alignment: .leading, spacing: 8) {
            Text("\(selectedTimeRange.title) Mood Overview")
                .font(.title2)
                .bold()
            
            Text("Average Mood: \(MoodType(rawValue: avgMood)?.emoji ?? "–")")
                .font(.headline)
            
            HStack {
                VStack {
                    Text("Best Day")
                    Text(bestDay?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")
                    Text(moodEmoji(for: bestDay))
                }
                Spacer()
                VStack {
                    Text("Worst Day")
                    Text(worstDay?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")
                    Text(moodEmoji(for: worstDay))
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    // MARK: - Mood Charts Section
    private var moodChartsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mood Trends")
                .font(.title3)
                .bold()
            
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach([TimeRange.week, .month, .year], id: \.self) { range in
                    Text(range.title).tag(range)
                }
            }
            .pickerStyle(.segmented)
            
            MoodChartView(timeRange: selectedTimeRange, entries: filteredMoodEntries)
                .frame(minHeight: 200)
                .transition(.opacity)
        }
    }
    
    // MARK: - Detailed Stats Section
    private var detailedStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailed Statistics")
                .font(.title3)
                .bold()
            
            NavigationLink(destination: MoodBreakdownView(groupBy: .mood, entries: moodEntries)) {
                Label("Breakdown by Mood", systemImage: "face.smiling")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.green.opacity(0.15))
                    .cornerRadius(8)
                    .foregroundColor(.green)
            }
            
            NavigationLink(destination: MoodBreakdownView(groupBy: .tag, entries: moodEntries)) {
                Label("Breakdown by Activity/Tag", systemImage: "tag")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.orange.opacity(0.15))
                    .cornerRadius(8)
                    .foregroundColor(.orange)
            }
        }
    }
    
    private var goalsSection: some View {
        MoodGoalView(entries: moodEntries)
    }
    
    // MARK: - Calculations
    private func averageMood(from entries: [MoodEntry]) -> Int {
        guard !entries.isEmpty else { return MoodType.neutral.rawValue }
        let total = entries.reduce(0) { $0 + $1.mood.rawValue }
        return total / entries.count
    }
    
    private func bestMoodDay(from entries: [MoodEntry]) -> Date? {
        entries.max(by: { $0.mood.rawValue < $1.mood.rawValue })?.date
    }
    
    private func worstMoodDay(from entries: [MoodEntry]) -> Date? {
        entries.min(by: { $0.mood.rawValue < $1.mood.rawValue })?.date
    }
    
    private func moodEmoji(for date: Date?) -> String {
        guard let date else { return "–" }
        return filteredMoodEntries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })?.mood.emoji ?? "–"
    }
    
    private func fetchAllMoodEntries() {
        let descriptor = FetchDescriptor<MoodEntry>()
        do {
            moodEntries = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch mood entries: \(error)")
        }
    }
}



// MARK: - TimeRange extension for title
enum TimeRange {
    case week, month, year
}


extension TimeRange {
    var title: String {
        switch self {
        case .week: return "Weekly"
        case .month: return "Monthly"
        case .year: return "Yearly"
        }
    }
}

// MARK: - MoodChartView with color-coded lines and insights
import SwiftUI
import Charts

// MARK: - MoodChartView with color-coded lines, insights, and legend
struct MoodChartView: View {
    var timeRange: TimeRange
    var entries: [MoodEntry]
    
    @State private var showingLegend = false
    
    var body: some View {
        VStack(spacing: 12) {
            Chart {
                ForEach(groupedEntries(), id: \.0) { (date, moodValue) in
                    LineMark(
                        x: .value("Date", date),
                        y: .value("Mood", moodValue)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(color(for: moodValue))
                    
                    PointMark(
                        x: .value("Date", date),
                        y: .value("Mood", moodValue)
                    )
                    .foregroundStyle(color(for: moodValue))
                }
            }
            .chartYScale(domain: 0...4)
            .frame(height: 200)
            .padding(.horizontal)
            
            // Mood Color Legend
            HStack(spacing: 16) {
                legendItem(color: .red, label: "Very Sad")
                legendItem(color: .orange, label: "Sad")
                legendItem(color: .yellow, label: "Neutral")
                legendItem(color: .green, label: "Happy")
                legendItem(color: .mint, label: "Very Happy")
            }
            .font(.caption)
            .padding(.horizontal)
            
            Text(insightText())
                .font(.callout)
                .padding(.horizontal)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .navigationTitle("\(timeRange.title) Mood")
    }
    
    // MARK: - Helpers
    
    private func color(for moodValue: Int) -> Color {
        switch moodValue {
        case 0: return .red
        case 1: return .orange
        case 2: return .yellow
        case 3: return .green
        case 4: return .mint
        default: return .gray
        }
    }
    
    private func groupedEntries() -> [(Date, Int)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            switch timeRange {
            case .week:
                return calendar.startOfDay(for: entry.date)
            case .month:
                return calendar.dateInterval(of: .weekOfMonth, for: entry.date)?.start ?? entry.date
            case .year:
                return calendar.dateInterval(of: .month, for: entry.date)?.start ?? entry.date
            }
        }
        
        return grouped
            .mapValues { $0.map(\.mood.rawValue).reduce(0, +) / $0.count }
            .sorted(by: { $0.key < $1.key })
    }
    
    private func insightText() -> String {
        let moods = groupedEntries().map(\.1)
        guard !moods.isEmpty else { return "No data available" }
        let avg = moods.reduce(0, +) / moods.count
        
        if avg >= 3 {
            return "Your mood has been quite positive overall."
        } else if avg <= 1 {
            return "Consider ways to improve your mood this period."
        } else {
            return "Mood is moderate. Keep tracking to see trends."
        }
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
        }
    }
}


// MARK: - MoodBreakdownView with percentages & bars
enum BreakdownType {
    case mood, tag
}


struct MoodBreakdownView: View {
    var groupBy: BreakdownType
    var entries: [MoodEntry]
    
    var body: some View {
        List {
            ForEach(groupedStats(), id: \.0) { (label, count, percent) in
                HStack {
                    Text(label)
                    Spacer()
                    Text("\(count) (\(String(format: "%.0f", percent * 100))%)")
                        .foregroundColor(.secondary)
                }
                ProgressView(value: percent)
                    .tint(color(for: label))
            }
        }
        .navigationTitle("Breakdown by \(groupBy == .mood ? "Mood" : "Tag")")
    }
    
    private func groupedStats() -> [(String, Int, Double)] {
        let total = entries.count
        switch groupBy {
        case .mood:
            return MoodType.allCases.compactMap { mood in
                let count = entries.filter { $0.mood == mood }.count
                guard count > 0 else { return nil }
                return (mood.emoji, count, Double(count) / Double(total))
            }
            
        case .tag:
            var tagCounts: [String: Int] = [:]
            for entry in entries {
                for tag in entry.tags {
                    tagCounts[tag, default: 0] += 1
                }
            }
            let sortedTags = tagCounts.sorted { $0.value > $1.value }
            return sortedTags.map { ($0.key, $0.value, Double($0.value) / Double(total)) }
        }
    }
    
    private func color(for label: String) -> Color {
        if MoodType.allCases.map(\.emoji).contains(label) {
            // Map mood emojis to colors
            switch label {
            case "😫": return .red
            case "☹️": return .orange
            case "😐": return .yellow
            case "🙂": return .green
            case "😍": return .mint
            default: return .gray
            }
        }
        // Tag color fallback
        return .blue
    }
}

// MARK: - MoodGoalView with rings and motivational text
struct MoodGoalView: View {
    var entries: [MoodEntry]
    
    @State private var dailyGoal: Int = 1
    @State private var weeklyGoal: Int = 5
    @State private var monthlyGoal: Int = 20
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Your Goals")
                .font(.title3)
                .bold()
            
            goalStepper(title: "Daily entries", value: $dailyGoal, range: 1...5)
            goalStepper(title: "Weekly entries", value: $weeklyGoal, range: 1...35)
            goalStepper(title: "Monthly entries", value: $monthlyGoal, range: 1...150)
            
            VStack(spacing: 20) {
                GoalRingProgress(title: "Today", count: todayCount(), goal: dailyGoal)
                GoalRingProgress(title: "This Week", count: weekCount(), goal: weeklyGoal)
                GoalRingProgress(title: "This Month", count: monthCount(), goal: monthlyGoal)
            }
            
            motivationalText()
        }
        .padding()
    }
    
    @ViewBuilder
    private func goalStepper(title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        Stepper("\(title): \(value.wrappedValue)", value: value, in: range)
            .padding(.horizontal)
    }
    
    private func todayCount() -> Int {
        entries.filter { Calendar.current.isDateInToday($0.date) }.count
    }
    
    private func weekCount() -> Int {
        entries.filter {
            Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear)
        }.count
    }
    
    private func monthCount() -> Int {
        entries.filter {
            Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month)
        }.count
    }
    
    @ViewBuilder
    private func motivationalText() -> some View {
        let todayPct = Float(todayCount()) / Float(dailyGoal)
        if todayPct >= 1 {
            Text("Great job! You met your daily goal 🎉")
                .foregroundColor(.green)
        } else if todayPct > 0.5 {
            Text("You're more than halfway there. Keep it up!")
                .foregroundColor(.yellow)
        } else {
            Text("Let's get started on today's goal!")
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Goal progress ring
struct GoalRingProgress: View {
    var title: String
    var count: Int
    var goal: Int
    
    var progress: CGFloat {
        min(CGFloat(count) / CGFloat(goal), 1)
    }
    
    var progressColor: Color {
        switch progress {
        case 0..<0.5: return .red
        case 0.5..<1: return .yellow
        default: return .green
        }
    }
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .stroke(lineWidth: 12)
                    .opacity(0.2)
                    .foregroundColor(progressColor)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .foregroundColor(progressColor)
                    .rotationEffect(.degrees(-90))
                
                Text("\(count)/\(goal)")
                    .bold()
            }
            .frame(width: 60, height: 60)
            
            Text(title)
                .font(.headline)
            
            Spacer()
        }
    }
}





// MARK: – Goals & Streaks

@Model class MoodGoal: Identifiable {
    @Attribute(.unique) var id = UUID()
    var title: String
    var targetMood: MoodType
    var startDate: Date
    var duration: Int              // in days
    var completedDates: [Date]     // stored as day‐start dates
    
    init(
        title: String,
        targetMood: MoodType,
        startDate: Date = .now,
        duration: Int = 7
    ) {
        self.title = title
        self.targetMood = targetMood
        self.startDate = startDate
        self.duration = duration
        self.completedDates = []
    }
}


/// Visualizes a horizontal streak for `duration` days of a given `targetMood`.
struct WeeklyMoodStreakView: View {
    let startDate: Date
    let duration: Int
    let targetMood: MoodType
    let completions: Set<Date>
    
    private var days: [Date] {
        let cal = Calendar.current
        return (0..<duration).compactMap { offset in
            cal.date(byAdding: .day, value: offset, to: cal.startOfDay(for: startDate))
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(days, id: \.self) { day in
                let achieved = completions.contains(day)
                VStack(spacing: 4) {
                    Text(day, format: .dateTime.weekday(.abbreviated))
                        .font(.caption2)
                    Text(achieved ? targetMood.emoji : "—")
                        .font(.title3)
                        .opacity(achieved ? 1 : 0.3)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .strokeBorder(
                                    achieved
                                    ? Color.accentColor
                                    : Color.secondary.opacity(0.3),
                                    lineWidth: 1.5
                                )
                        )
                }
            }
        }
    }
}

/// Lists all goals, shows their visual streaks, and lets you tap ✔︎ to mark today done.
struct GoalsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MoodGoal.startDate, order: .forward) private var goals: [MoodGoal]
    @State private var showingAdd = false
    
    var body: some View {
        NavigationStack {
            List {
                if goals.isEmpty {
                    Text("No goals yet—tap + to add one.")
                        .foregroundColor(.secondary)
                }
                
                ForEach(goals) { goal in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(goal.title)
                                .font(.headline)
                            Spacer()
                            Button {
                                let today = Calendar.current.startOfDay(for: .now)
                                guard !goal.completedDates.contains(today) else { return }
                                goal.completedDates.append(today)
                                do { try context.save() }
                                catch { print("Save error:", error) }
                            } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                            }
                            .buttonStyle(.borderless)
                        }
                        
                        WeeklyMoodStreakView(
                            startDate: goal.startDate,
                            duration: goal.duration,
                            targetMood: goal.targetMood,
                            completions: Set(goal.completedDates)
                        )
                    }
                    .padding(.vertical, 6)
                }
                .onDelete { offsets in
                    for idx in offsets {
                        context.delete(goals[idx])
                    }
                    try? context.save()
                }
            }
            .navigationTitle("Goals & Streaks")
            .toolbar {
                Button {
                    showingAdd = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddGoalSheet(isPresented: $showingAdd)
            }
        }
    }
}

/// A sheet for creating a new `MoodGoal`
struct AddGoalSheet: View {
    @Environment(\.modelContext) private var context
    @Binding var isPresented: Bool
    
    @State private var title: String = ""
    @State private var mood: MoodType = .veryHappy
    @State private var duration: Int = 7
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    TextField("Title", text: $title)
                    Picker("Mood", selection: $mood) {
                        ForEach(MoodType.allCases) { m in
                            Text(m.emoji).tag(m)
                        }
                    }
                    Stepper("Days: \(duration)", value: $duration, in: 1...30)
                }
            }
            .navigationTitle("New Goal")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let goal = MoodGoal(
                            title: title.trimmingCharacters(in: .whitespaces),
                            targetMood: mood,
                            duration: duration
                        )
                        context.insert(goal)
                        do { try context.save() }
                        catch { print("Save error:", error) }
                        isPresented = false
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
