import SwiftUI
import SwiftData

struct TimeLogView: View {
    @Environment(SubscriptionController.self) var subscriptionController
    @State private var showPaywall = false
    @State private var startDate: Date?
    @State private var pausedTime: TimeInterval = 0
    @State private var elapsedTime: TimeInterval = 0
    @State private var isRunning = false
    @State private var isPaused = false
    @State private var workDuration: TimeInterval?
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @Query private var jobs: [Job]
    
    @Environment(\.modelContext) private var context
    @State private var selectedJob: Job?
    
    @State private var isShowingAddJobSheet = false
    @State private var newJobTitle = ""
    @State private var hourlyRateString = ""
    @State private var newJobCompany = ""
    
    var earningsSoFar: Decimal {
        guard let job = selectedJob else { return 0 }
        let hours = elapsedTime / 3600
        return job.hourlyRate * Decimal(hours)
    }
    
    @State private var breakStartDate: Date?
    @State private var breakDuration: TimeInterval = 0
    
    @Query private var allShifts: [WorkShift]
    
    var body: some View {
        NavigationStack {
            if selectedJob != nil {
                Text("Tracking Time for \(selectedJob?.title ?? "")")
                    .font(.title2)
                    .foregroundColor(.green)
                    .padding(.top)
                
                Divider()
                    .background(Color.green.opacity(0.5))
                    .padding()
            }
            
            HStack {
                Picker("Select Job", selection: $selectedJob) {
                    ForEach(jobs) { job in
                        Text(job.title).tag(job as Job?)
                    }
                }
                .pickerStyle(.menu)
                .onAppear {
                    if selectedJob == nil {
                        selectedJob = jobs.first
                    }
                }
                
                Button(action: {
                    if jobs.count >= 1 && !subscriptionController.isSubscribed {
                        showPaywall = true
                    } else {
                        isShowingAddJobSheet = true
                    }
                }) {
                    Image(systemName: "plus.circle")
                        .imageScale(.large)
                }
                .accessibilityLabel("Add Job")
                .sheet(isPresented: $showPaywall) {
                    PaywallView()
                }
            }
            .padding(.horizontal)
            .sheet(isPresented: $isShowingAddJobSheet) {
                NavigationStack {
                    Form {
                        Section("Job Info") {
                            TextField("Title", text: $newJobTitle)
                            TextField("Company (optional)", text: $newJobCompany)
                            TextField("Hourly Rate", text: $hourlyRateString)
                                .keyboardType(.decimalPad)
                        }
                    }
                    .navigationTitle("New Job")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                guard
                                    !newJobTitle.trimmingCharacters(in: .whitespaces).isEmpty,
                                    let rate = Decimal(string: hourlyRateString)
                                else { return }
                                
                                print("Parsed rate:", rate)
                                
                                let job = Job(
                                    title: newJobTitle,
                                    company: newJobCompany.isEmpty ? nil : newJobCompany,
                                    hourlyRate: rate
                                )
                                print("💾 Creating Job:", job.title, job.company ?? "", job.hourlyRate)
                                
                                context.insert(job)
                                
                                do {
                                    try context.save()
                                    print("✅ Job saved")
                                } catch {
                                    print("❌ Failed to save job:", error)
                                }
                                
                                selectedJob = job
                                newJobTitle = ""
                                newJobCompany = ""
                                hourlyRateString = ""
                                isShowingAddJobSheet = false
                            }
                        }
                        
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                isShowingAddJobSheet = false
                            }
                        }
                    }
                }
            }
            
            VStack(spacing: 32) {
                // Flip clock: HH:MM:SS
                HStack(spacing: 4) {
                    let time = timeComponents(from: elapsedTime)
                    
                    // Hours
                    FlipClockView(value: .constant(time.hours / 10),
                                  size: CGSize(width: 60, height: 90),
                                  fontSize: 48,
                                  cornerRadius: 8,
                                  foregroundColor: .white,
                                  backgroundColor: .green)
                    
                    FlipClockView(value: .constant(time.hours % 10),
                                  size: CGSize(width: 60, height: 90),
                                  fontSize: 48,
                                  cornerRadius: 8,
                                  foregroundColor: .white,
                                  backgroundColor: .green)
                    
                    Text(":")
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                    
                    // Minutes
                    FlipClockView(value: .constant(time.minutes / 10),
                                  size: CGSize(width: 60, height: 90),
                                  fontSize: 48,
                                  cornerRadius: 8,
                                  foregroundColor: .white,
                                  backgroundColor: .green)
                    
                    FlipClockView(value: .constant(time.minutes % 10),
                                  size: CGSize(width: 60, height: 90),
                                  fontSize: 48,
                                  cornerRadius: 8,
                                  foregroundColor: .white,
                                  backgroundColor: .green)
                    
                    Text(":")
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                    
                    // Seconds
                    FlipClockView(value: .constant(time.seconds / 10),
                                  size: CGSize(width: 60, height: 90),
                                  fontSize: 48,
                                  cornerRadius: 8,
                                  foregroundColor: .white,
                                  backgroundColor: .green)
                    
                    FlipClockView(value: .constant(time.seconds % 10),
                                  size: CGSize(width: 60, height: 90),
                                  fontSize: 48,
                                  cornerRadius: 8,
                                  foregroundColor: .white,
                                  backgroundColor: .green)
                }
                
                if selectedJob != nil {
                    VStack {
                        HStack(spacing: 20) {
                            Button("Start") {
                                if allShifts.count > 14 && !subscriptionController.isSubscribed {
                                    showPaywall = true
                                } else {
                                    if !isRunning {
                                        startDate = Date()
                                        isRunning = true
                                        isPaused = false
                                    }
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isRunning && !isPaused)
                            
                            Button(isPaused ? "Resume" : "Pause") {
                                if isRunning {
                                    // Pausing
                                    pausedTime += Date().timeIntervalSince(startDate ?? Date())
                                    isPaused = true
                                    isRunning = false
                                    
                                    breakStartDate = Date() // Start tracking break
                                } else if isPaused {
                                    // Resuming
                                    startDate = Date()
                                    isPaused = false
                                    isRunning = true
                                    
                                    if let breakStart = breakStartDate {
                                        breakDuration += Date().timeIntervalSince(breakStart)
                                        breakStartDate = nil
                                    }
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(startDate == nil)
                            
                            Button("End") {
                                guard let job = selectedJob, let start = startDate else { return }
                                
                                if isRunning {
                                    elapsedTime = pausedTime + Date().timeIntervalSince(start)
                                }
                                
                                workDuration = elapsedTime
                                
                                let newShift = WorkShift(
                                    startTime: start,
                                    endTime: Date(),
                                    totalWorked: workDuration ?? 0,
                                    job: job
                                )
                                
                                context.insert(newShift)
                                
                                do {
                                    try context.save()
                                    print("✅ Shift saved for job '\(job.title)' — Duration: \(newShift.formattedTotalWorked)")
                                } catch {
                                    print("❌ Failed to save shift:", error)
                                }
                                
                                // Reset timer state
                                isRunning = false
                                isPaused = false
                                pausedTime = 0
                                elapsedTime = 0
                                startDate = nil
                                
                                breakStartDate = nil
                                breakDuration = 0
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                            .disabled(startDate == nil)
                        }
                        
                        VStack(spacing: 8) {
                            if isPaused {
                                Text("Break Duration: \(timeString(from: breakDuration))")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            }
                            
                            Text("Earnings So Far: \(earningsSoFar.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        .padding(.top)
                        .fixedSize()
                    }
                } else {
                    Text("Select a job to log work.")
                }
            }
            .padding()
            .onReceive(timer) { _ in
                if isRunning, let start = startDate {
                    elapsedTime = pausedTime + Date().timeIntervalSince(start)
                }
                
                if isPaused, let breakStart = breakStartDate {
                    breakDuration = Date().timeIntervalSince(breakStart)
                }
            }
        }
    }
    
    func timeComponents(from interval: TimeInterval) -> (hours: Int, minutes: Int, seconds: Int) {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return (hours, minutes, seconds)
    }
    
    func timeString(from interval: TimeInterval) -> String {
        let t = timeComponents(from: interval)
        return String(format: "%02d:%02d:%02d", t.hours, t.minutes, t.seconds)
    }
}


#Preview {
    TimeLogView()
}


func formattedDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

func formattedTimeRange(start: Date, end: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateStyle = .none
    return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
}
