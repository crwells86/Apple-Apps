import SwiftUI
import HealthKit
import SwiftData

// MARK: - Goal Types Enum
enum GoalType: String, Codable, CaseIterable {
    case steps = "Steps"
    case distance = "Distance"
    case activeEnergy = "Active Energy"
    case exerciseTime = "Exercise Time"
    case standHours = "Stand Hours"
    case walking = "Walking"
    case sleep = "Sleep"
    case cycling = "Cycling"
    case swimming = "Swimming"
    case running = "Running"
    case hiking = "Hiking"
    case yoga = "Yoga"
    case strengthTraining = "Strength Training"
    case dancing = "Dancing"
    case elliptical = "Elliptical"
    case rowing = "Rowing"
    case stairClimber = "Stair Climber"
    case highIntensityIntervalTraining = "HIIT"
    case pilates = "Pilates"
    case functionalStrengthTraining = "Functional Strength"
    case coreTraining = "Core Training"
    case mixedCardio = "Mixed Cardio"
    case mindfulCooldown = "Mindful Cooldown"
    case martialArts = "Martial Arts"
    case boxing = "Boxing"
    case jumpRope = "Jump Rope"
    case danceInspiredTraining = "Dance Inspired"
    case barre = "Barre"
    case flexibility = "Flexibility"
    
    var icon: String {
        switch self {
        case .steps: return "figure.walk"
        case .distance: return "figure.run"
        case .activeEnergy: return "flame.fill"
        case .exerciseTime: return "timer"
        case .standHours: return "figure.stand"
        case .walking: return "figure.walk"
        case .sleep: return "bed.double.fill"
        case .cycling: return "figure.outdoor.cycle"
        case .swimming: return "figure.pool.swim"
        case .running: return "figure.run"
        case .hiking: return "figure.hiking"
        case .yoga: return "figure.mind.and.body"
        case .strengthTraining: return "dumbbell.fill"
        case .dancing: return "figure.dance"
        case .elliptical: return "circle.grid.3x3.fill"
        case .rowing: return "water.waves"
        case .stairClimber: return "figure.stairs"
        case .highIntensityIntervalTraining: return "bolt.fill"
        case .pilates: return "figure.core.training"
        case .functionalStrengthTraining: return "dumbbell.fill"
        case .coreTraining: return "figure.core.training"
        case .mixedCardio: return "heart.fill"
        case .mindfulCooldown: return "wind"
        case .martialArts: return "figure.kickboxing"
        case .boxing: return "figure.boxing"
        case .jumpRope: return "figure.jumprope"
        case .danceInspiredTraining: return "figure.dance"
        case .barre: return "line.3.horizontal"
        case .flexibility: return "figure.cooldown"
        }
    }
    
    var unit: String {
        switch self {
        case .steps: return "steps"
        case .distance: return "km"
        case .activeEnergy: return "kcal"
        case .exerciseTime: return "min"
        case .standHours: return "hours"
        case .cycling, .swimming, .running, .yoga, .strengthTraining, .hiking, .dancing, .walking:
            return "min"
        case .sleep: return "min"
        default:
            return "min"
        }
    }
    
    var healthKitIdentifier: HKQuantityTypeIdentifier? {
        switch self {
        case .steps: return .stepCount
        case .distance: return .distanceWalkingRunning
        case .activeEnergy: return .activeEnergyBurned
        case .exerciseTime: return .appleExerciseTime
        case .standHours: return nil
        case .cycling: return .distanceCycling
        case .swimming: return .distanceSwimming
        case .running: return .distanceWalkingRunning
        case .sleep: return nil
        case .yoga, .strengthTraining, .hiking, .dancing, .walking: return nil
        default:
            return nil
        }
    }
    
    var workoutActivityType: HKWorkoutActivityType? {
        switch self {
        case .walking: return .walking
        case .running: return .running
        case .cycling: return .cycling
        case .swimming: return .swimming
        case .hiking: return .hiking
        case .yoga: return .yoga
        case .strengthTraining: return .traditionalStrengthTraining
        case .dancing: return .cardioDance
        case .elliptical: return .elliptical
        case .rowing: return .rowing
        case .stairClimber: return .stairClimbing
        case .highIntensityIntervalTraining: return .highIntensityIntervalTraining
        case .pilates: return .pilates
        case .functionalStrengthTraining: return .functionalStrengthTraining
        case .coreTraining: return .coreTraining
        case .mixedCardio: return .mixedCardio
        case .martialArts: return .martialArts
        case .boxing: return .boxing
        case .jumpRope: return .jumpRope
        case .barre: return .barre
        case .flexibility: return .flexibility
        default: return nil
        }
    }
}

// MARK: - Models
@Model
final class Goal {
    @Attribute(.unique) var id: UUID
    var type: GoalType
    var target: Double
    var daysPerWeek: Int
    var createdAt: Date
    var colorHex: String
    
    init(type: GoalType, target: Double, daysPerWeek: Int, colorHex: String = "34C759") {
        self.id = UUID()
        self.type = type
        self.target = target
        self.daysPerWeek = daysPerWeek
        self.createdAt = Date()
        self.colorHex = colorHex
    }
}

@Model
final class DailyGoalData {
    var goalID: UUID
    var date: Date
    var value: Double
    var goalMet: Bool
    
    init(goalID: UUID, date: Date, value: Double, goalMet: Bool) {
        self.goalID = goalID
        self.date = date
        self.value = value
        self.goalMet = goalMet
    }
}

// MARK: - HealthKit Manager
@Observable
class HealthKitManager {
    private let healthStore = HKHealthStore()
    var isAuthorized = false
    var authorizationError: String?
    
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            await MainActor.run {
                authorizationError = "HealthKit not available"
            }
            return
        }
        
        let allTypes: Set<HKObjectType> = Set([
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
            HKObjectType.categoryType(forIdentifier: .appleStandHour)!,
            HKObjectType.quantityType(forIdentifier: .distanceCycling)!,
            HKObjectType.quantityType(forIdentifier: .distanceSwimming)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.workoutType()
        ])
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: allTypes)
            await MainActor.run {
                isAuthorized = true
            }
        } catch {
            await MainActor.run {
                authorizationError = error.localizedDescription
            }
        }
    }
    
    func fetchQuantityData(for type: GoalType, date: Date) async -> Double {
        guard let identifier = type.healthKitIdentifier,
              let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            return await fetchWorkoutData(for: type, date: date)
        }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                guard let sum = result?.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                
                let value: Double
                switch type {
                case .steps:
                    value = sum.doubleValue(for: .count())
                case .distance:
                    value = sum.doubleValue(for: .meter()) / 1000.0
                case .activeEnergy:
                    value = sum.doubleValue(for: .kilocalorie())
                case .exerciseTime:
                    value = sum.doubleValue(for: .minute())
                case .cycling:
                    value = sum.doubleValue(for: .meter()) / 1000.0
                case .swimming:
                    value = sum.doubleValue(for: .meter()) / 1000.0
                case .running:
                    value = sum.doubleValue(for: .meter()) / 1000.0
                default:
                    value = sum.doubleValue(for: .count())
                }
                
                continuation.resume(returning: value)
            }
            self.healthStore.execute(query)
        }
    }
    
    func fetchStandHours(for date: Date) async -> Double {
        guard let standType = HKCategoryType.categoryType(forIdentifier: .appleStandHour) else { return 0 }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: standType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                let standHours = samples?.filter { sample in
                    guard let categorySample = sample as? HKCategorySample else { return false }
                    return categorySample.value == HKCategoryValueAppleStandHour.stood.rawValue
                }.count ?? 0
                continuation.resume(returning: Double(standHours))
            }
            self.healthStore.execute(query)
        }
    }
    
    func fetchSleep(for date: Date) async -> Double {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return 0 }
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                let totalSeconds = samples?.compactMap { $0 as? HKCategorySample }
                    .filter { $0.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                              $0.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                              $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                              $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) } ?? 0
                continuation.resume(returning: totalSeconds / 60.0)
            }
            self.healthStore.execute(query)
        }
    }
    
    func fetchWorkoutData(for type: GoalType, date: Date) async -> Double {
        guard let activityType = type.workoutActivityType else { return 0 }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForWorkouts(with: activityType)
        let datePredicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay)
        let compound = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, datePredicate])
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: .workoutType(), predicate: compound, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                let totalMinutes = samples?.compactMap { $0 as? HKWorkout }
                    .reduce(0.0) { $0 + $1.duration / 60.0 } ?? 0
                continuation.resume(returning: totalMinutes)
            }
            self.healthStore.execute(query)
        }
    }
    
    func fetchAllWorkouts(for date: Date) async -> Double {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                let totalMinutes = samples?.compactMap { $0 as? HKWorkout }
                    .reduce(0.0) { $0 + $1.duration / 60.0 } ?? 0
                continuation.resume(returning: totalMinutes)
            }
            self.healthStore.execute(query)
        }
    }
    
    func fetchData(for goal: Goal, date: Date) async -> Double {
        if goal.type == .sleep {
            return await fetchSleep(for: date)
        } else if goal.type == .standHours {
            return await fetchStandHours(for: date)
        } else if goal.type.workoutActivityType != nil {
            return await fetchWorkoutData(for: goal.type, date: date)
        } else {
            return await fetchQuantityData(for: goal.type, date: date)
        }
    }
}

// MARK: - View Model
@Observable
class HealthViewModel {
    let healthKit = HealthKitManager()
    var goals: [Goal] = []
    var dailyData: [DailyGoalData] = []
    var isLoading = false
    var selectedWeekStart: Date
    
    private var modelContext: ModelContext?
    
    init() {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysToSubtract = weekday - 1
        selectedWeekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: today) ?? today
        selectedWeekStart = calendar.startOfDay(for: selectedWeekStart)
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadData()
    }
    
    func loadData() {
        guard let context = modelContext else { return }
        
        let goalDescriptor = FetchDescriptor<Goal>(sortBy: [SortDescriptor(\.createdAt)])
        goals = (try? context.fetch(goalDescriptor)) ?? []
        
        let dataDescriptor = FetchDescriptor<DailyGoalData>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        dailyData = (try? context.fetch(dataDescriptor)) ?? []
    }
    
    func addGoal(_ goal: Goal) {
        guard let context = modelContext else { return }
        context.insert(goal)
        do {
            try context.save()
            loadData()
            
            Task {
                await refreshGoalData(goal)
            }
        } catch {
            print("Error saving goal: \(error)")
        }
    }
    
    func deleteGoal(_ goal: Goal) {
        guard let context = modelContext else { return }
        
        let goalID = goal.id
        let predicate = #Predicate<DailyGoalData> { $0.goalID == goalID }
        let descriptor = FetchDescriptor(predicate: predicate)
        if let dataToDelete = try? context.fetch(descriptor) {
            dataToDelete.forEach { context.delete($0) }
        }
        
        context.delete(goal)
        try? context.save()
        loadData()
    }
    
    func updateGoal(_ goal: Goal, target: Double, daysPerWeek: Int) {
        guard let context = modelContext else { return }
        goal.target = target
        goal.daysPerWeek = daysPerWeek
        try? context.save()
        loadData()
    }
    
    func refreshGoalData(_ goal: Goal) async {
        await MainActor.run { isLoading = true }
        
        let calendar = Calendar.current
        let today = Date()
        let startDate = calendar.date(byAdding: .day, value: -120, to: today)!
        
        var dates: [Date] = []
        var currentDate = startDate
        while currentDate <= today {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        for date in dates {
            let value = await healthKit.fetchData(for: goal, date: date)
            let goalMet = value >= goal.target
            
            await MainActor.run {
                saveOrUpdateData(goalID: goal.id, date: date, value: value, goalMet: goalMet)
            }
        }
        
        await MainActor.run {
            loadData()
            isLoading = false
        }
    }
    
    func refreshAllGoals() async {
        for goal in goals {
            await refreshGoalData(goal)
        }
    }
    
    private func saveOrUpdateData(goalID: UUID, date: Date, value: Double, goalMet: Bool) {
        guard let context = modelContext else { return }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let predicate = #Predicate<DailyGoalData> { $0.goalID == goalID && $0.date == startOfDay }
        let descriptor = FetchDescriptor(predicate: predicate)
        
        if let existing = try? context.fetch(descriptor).first {
            existing.value = value
            existing.goalMet = goalMet
        } else {
            let newData = DailyGoalData(goalID: goalID, date: startOfDay, value: value, goalMet: goalMet)
            context.insert(newData)
        }
        
        try? context.save()
    }
    
    func getWeekData(for goal: Goal) -> [DailyGoalData] {
        let calendar = Calendar.current
        let weekDates = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: selectedWeekStart) }
        
        return weekDates.map { date in
            let startOfDay = calendar.startOfDay(for: date)
            return dailyData.first { $0.goalID == goal.id && calendar.isDate($0.date, inSameDayAs: startOfDay) }
            ?? DailyGoalData(goalID: goal.id, date: startOfDay, value: 0, goalMet: false)
        }
    }
    
    func getCompletedDaysInWeek(for goal: Goal) -> Int {
        getWeekData(for: goal).filter { $0.goalMet }.count
    }
    
    func getAverageValue(for goal: Goal) -> Double {
        let weekData = getWeekData(for: goal)
        let total = weekData.reduce(0.0) { $0 + $1.value }
        return weekData.isEmpty ? 0 : total / Double(weekData.count)
    }
    
    func getTotalValue(for goal: Goal) -> Double {
        getWeekData(for: goal).reduce(0.0) { $0 + $1.value }
    }
    
    func fetchData(for goal: Goal, date: Date) async -> Double {
        if goal.type == .sleep {
            return await healthKit.fetchSleep(for: date)
        } else if goal.type == .standHours {
            return await healthKit.fetchStandHours(for: date)
        } else if goal.type.workoutActivityType != nil {
            return await healthKit.fetchWorkoutData(for: goal.type, date: date)
        } else {
            return await healthKit.fetchQuantityData(for: goal.type, date: date)
        }
    }
}

// MARK: - Authorization View
struct AuthorizationView: View {
    let viewModel: HealthViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            
            Text("Health Access Required")
                .font(.title2.bold())
            
            Text("This app needs access to your health data to track your goals.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Button {
                Task {
                    await viewModel.healthKit.requestAuthorization()
                    if viewModel.healthKit.isAuthorized {
                        viewModel.loadData()
                    }
                }
            } label: {
                Text("Grant Access")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.green)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    @Binding var showingAddGoal: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.walk.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            
            Text("No Goals Yet")
                .font(.title2.bold())
            
            Text("Add your first health goal to start tracking your progress.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Button {
                showingAddGoal = true
            } label: {
                Label("Add Goal", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.green)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

struct GoalCardView: View {
    let goal: Goal
    let viewModel: HealthViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var showingEditSheet = false
    @State private var showingDetailView = false
    
    var color: Color {
        Color(hex: goal.colorHex) ?? .green
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: goal.type.icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(Circle().fill(color))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.type.rawValue)
                        .font(.title3.bold())
                    Text("Goal: \(Int(goal.target)) \(goal.type.unit)  |  \(goal.daysPerWeek) days a week")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit Goal", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        viewModel.deleteGoal(goal)
                    } label: {
                        Label("Delete Goal", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.secondary)
                        .padding(8)
                }
            }
            
            HStack(spacing: 24) {
                StatView(value: "\(viewModel.getCompletedDaysInWeek(for: goal))", label: "days\nFinished", valueColor: .primary)
                StatView(value: String(format: "%.0f", viewModel.getAverageValue(for: goal)), label: "Average", valueColor: .primary)
                StatView(value: String(format: "%.0f", viewModel.getTotalValue(for: goal)), label: "Total", valueColor: .primary)
            }
            
            WeekCalendarView(goal: goal, viewModel: viewModel, color: color)
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : .white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            showingDetailView = true
        }
        .sheet(isPresented: $showingEditSheet) {
            EditGoalView(goal: goal, viewModel: viewModel)
        }
        .sheet(isPresented: $showingDetailView) {
            GoalDetailView(goal: goal, viewModel: viewModel)
        }
    }
}

// MARK: - Week Calendar View
struct WeekCalendarView: View {
    let goal: Goal
    let viewModel: HealthViewModel
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            HStack(spacing: 8) {
                let weekData = viewModel.getWeekData(for: goal)
                ForEach(Array(weekData.enumerated()), id: \.offset) { index, data in
                    DayCell(data: data, goal: goal, color: color)
                }
            }
        }
    }
}

// MARK: - Day Cell
struct DayCell: View {
    let data: DailyGoalData
    let goal: Goal
    let color: Color
    
    var dayNumber: Int {
        Calendar.current.component(.day, from: data.date)
    }
    
    var isFuture: Bool {
        data.date > Date()
    }
    
    var displayValue: String {
        if data.value >= 1000 {
            return String(format: "%.0f", data.value / 1000)
        }
        return String(format: "%.0f", data.value)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            if isFuture {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text("\(dayNumber)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.secondary)
                    )
            } else if data.goalMet {
                Circle()
                    .fill(color)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    )
            } else if data.value > 0 {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(displayValue)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(color)
                    )
            } else {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "moon.zzz")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    )
            }
            
            Text(String(format: "%.0f", data.value))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Add Goal View
struct AddGoalView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: HealthViewModel
    
    @State private var selectedType: GoalType = .steps
    @State private var target: Double = 5000
    @State private var daysPerWeek: Int = 3
    @State private var selectedColor: Color = .green
    
    let colors: [Color] = [.green, .blue, .purple, .orange, .pink, .red, .teal, .indigo]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Activity Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(GoalType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                }
                
                Section("Target") {
                    HStack {
                        TextField("Target", value: $target, format: .number)
                            .keyboardType(.numberPad)
                        Text(selectedType.unit)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Frequency") {
                    Stepper("Days per week: \(daysPerWeek)", value: $daysPerWeek, in: 1...7)
                }
                
                Section("Color") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(colors, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(color == selectedColor ? Color.primary : Color.clear, lineWidth: 3)
                                            .padding(-4)
                                    )
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Add Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let hexColor = selectedColor.toHex()
                        let goal = Goal(type: selectedType, target: target, daysPerWeek: daysPerWeek, colorHex: hexColor)
                        viewModel.addGoal(goal)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Edit Goal View
struct EditGoalView: View {
    @Environment(\.dismiss) private var dismiss
    let goal: Goal
    let viewModel: HealthViewModel
    
    @State private var target: Double
    @State private var daysPerWeek: Int
    
    init(goal: Goal, viewModel: HealthViewModel) {
        self.goal = goal
        self.viewModel = viewModel
        _target = State(initialValue: goal.target)
        _daysPerWeek = State(initialValue: goal.daysPerWeek)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Target") {
                    HStack {
                        TextField("Target", value: $target, format: .number)
                            .keyboardType(.numberPad)
                        Text(goal.type.unit)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Frequency") {
                    Stepper("Days per week: \(daysPerWeek)", value: $daysPerWeek, in: 1...7)
                }
            }
            .navigationTitle("Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.updateGoal(goal, target: target, daysPerWeek: daysPerWeek)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Stat View
struct StatView: View {
    let value: String
    let label: String
    let valueColor: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(valueColor)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Color Extensions
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
    
    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else {
            return "34C759"
        }
        
        let r = components[0]
        let g = components.count > 1 ? components[1] : components[0]
        let b = components.count > 2 ? components[2] : components[0]
        
        let rgb = (Int)(r * 255) << 16 | (Int)(g * 255) << 8 | (Int)(b * 255) << 0
        return String(format: "%06X", rgb)
    }
}

#Preview("GoalCardView - Mock") {
    // Create a mock goal
    let mockGoal = Goal(
        type: .steps,
        target: 8000,
        daysPerWeek: 5,
        colorHex: Color.green.toHex()
    )

    // Create a lightweight mock view model with stubbed week data
    let vm = HealthViewModel()

    // Inject mock model context by creating an in-memory container
    let container = try! ModelContainer(for: Goal.self, DailyGoalData.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = container.mainContext
    vm.setModelContext(context)

    // Insert the goal into the context so it has persistence identity
    context.insert(mockGoal)
    try? context.save()
    vm.loadData()

    // Seed a week of mock DailyGoalData so the card shows meaningful stats
    let calendar = Calendar.current
    let today = Date()
    let weekday = calendar.component(.weekday, from: today)
    let startOfWeek = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -(weekday - 1), to: today)!)

    for i in 0..<7 {
        let date = calendar.date(byAdding: .day, value: i, to: startOfWeek)!
        let startOfDay = calendar.startOfDay(for: date)
        // Alternate days meeting the goal; vary value a bit
        let value = i % 2 == 0 ? 9000.0 : 4500.0
        let met = value >= mockGoal.target
        let data = DailyGoalData(goalID: mockGoal.id, date: startOfDay, value: value, goalMet: met)
        context.insert(data)
    }
    try? context.save()
    vm.loadData()

    return NavigationStack {
        GoalCardView(goal: mockGoal, viewModel: vm)
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Preview")
    }
}
