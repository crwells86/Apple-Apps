import SwiftUI
import SwiftData

struct JobDetailView: View {
    @Environment(SubscriptionController.self) var subscriptionController
    @State private var showPaywall = false
    @Bindable var job: Job
    
    @Environment(\.modelContext) private var context
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var isAddNewShiftPresented = false
    @State private var isExportPresented = false
    
    @Query private var allShifts: [WorkShift]
    
    var shiftsForSelectedJob: [WorkShift] {
        allShifts.filter { $0.job.id == job.id }
    }
    
    var totalWorkedTime: TimeInterval {
        shiftsForSelectedJob.reduce(0) { $0 + $1.totalWorked }
    }
    
    var totalEarnings: Decimal {
        let hours = totalWorkedTime / 3600
        return Decimal(hours) * job.hourlyRate
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if shiftsForSelectedJob.isEmpty {
                ContentUnavailableView("No Shifts", systemImage: "calendar.badge.clock", description: Text("Add your first shift to begin tracking time."))
            } else {
                summarySection
                List {
                    ForEach(shiftsForSelectedJob.sorted(by: { $0.startTime > $1.startTime })) { shift in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Label(formattedDate(shift.startTime), systemImage: "calendar")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Label(shift.formattedTotalWorked, systemImage: "clock")
                                    .font(.body)
                            }
                            
                            if let end = shift.endTime {
                                HStack {
                                    Label(formattedTimeRange(start: shift.startTime, end: end), systemImage: "arrow.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            HStack {
                                Label("Earnings: \(formattedCurrency(earnings(for: shift)))", systemImage: "dollarsign.circle")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteShifts)
                }
            }
        }
        .padding(.top)
        .navigationTitle(job.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if allShifts.count > 14 && !subscriptionController.isSubscribed {
                        showPaywall = true
                    } else {
                        isAddNewShiftPresented = true
                    }
                } label: {
                    Label("Add Shift", systemImage: "plus")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    if !subscriptionController.isSubscribed {
                        showPaywall = true
                    } else {
                        isExportPresented.toggle()
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $isAddNewShiftPresented) {
            addShiftSheet
        }
        .sheet(isPresented: $isExportPresented) {
            InvoiceExportView(job: job, shifts: allShifts)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
    
    // MARK: - Shift Summary View
    
    var summarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Total Time: \(timeString(from: totalWorkedTime))", systemImage: "timer")
            }
            HStack {
                Label("Total Earnings: \(formattedCurrency(totalEarnings))", systemImage: "dollarsign.circle")
            }
        }
        .font(.headline)
        .padding(.horizontal)
    }
    
    // MARK: - Add Shift Sheet
    var addShiftSheet: some View {
        NavigationStack {
            Form {
                Section("Shift Time") {
                    DatePicker("Start Time", selection: $startTime)
                    DatePicker("End Time", selection: $endTime)
                }
            }
            .navigationTitle("New Shift")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isAddNewShiftPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let duration = endTime.timeIntervalSince(startTime)
                        guard duration > 0 else { return }
                        
                        let newShift = WorkShift(
                            startTime: startTime,
                            endTime: endTime,
                            totalWorked: duration,
                            job: job
                        )
                        context.insert(newShift)
                        try? context.save()
                        
                        isAddNewShiftPresented = false
                    }
                }
            }
        }
    }
    
    func deleteShifts(at offsets: IndexSet) {
        let shiftsToDelete = offsets.map { shiftsForSelectedJob.sorted(by: { $0.startTime > $1.startTime })[$0] }
        for shift in shiftsToDelete {
            context.delete(shift)
        }
        try? context.save()
    }
    
    func earnings(for shift: WorkShift) -> Decimal {
        let hours = shift.totalWorked / 3600
        return Decimal(hours) * job.hourlyRate
    }
    
    func timeString(from interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return String(format: "%dh %02dm", hours, minutes)
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
        return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
    }
    
    func formattedCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(for: value) ?? "$0.00"
    }
}
