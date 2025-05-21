
import SwiftUI
import SwiftData
import UserNotifications

// MARK: - Medication Model
@Model
class Medication {
    var name: String
    var dosage: String
    var times: [Date] // Support multiple doses per day
    var taken: [Bool] // Match times
    var person: String
    
    init(name: String, dosage: String, times: [Date], person: String) {
        self.name = name
        self.dosage = dosage
        self.times = times
        self.taken = Array(repeating: false, count: times.count)
        self.person = person
    }
}


// MARK: - Medication List View
//struct MedicationListView: View {
//    @State private var showingAddSheet = false
//    
//    @Query var medications: [Medication]
//    
//    var grouped: [String: [Medication]] {
//        Dictionary(
//            grouping: medications.sorted(by: {
//                ($0.times.first ?? Date.distantFuture) < ($1.times.first ?? Date.distantFuture)
//            }),
//            by: \.person
//        )
//    }
//    
//    
//    var body: some View {
//        NavigationStack {
//            List {
//                ForEach(grouped, id: \ .self) { person in
//                    Section(person) {
//                        ForEach(grouped[person] ?? []) { med in
//                            ForEach(Array(med.times.enumerated()), id: \ .offset) { index, time in
//                                HStack {
//                                    VStack(alignment: .leading) {
//                                        Text(med.name).font(.headline)
//                                        Text(med.dosage).font(.subheadline)
//                                        Text("Time: \(time.formatted(date: .omitted, time: .shortened))")
//                                            .font(.caption)
//                                    }
//                                    Spacer()
//                                    Button(action: {
//                                        med.taken[index].toggle()
//                                    }) {
//                                        Image(systemName: med.taken[index] ? "checkmark.circle.fill" : "circle")
//                                            .foregroundStyle(med.taken[index] ? .green : .gray)
//                                    }.buttonStyle(.plain)
//                                }
//                            }
//                        }
//                        .onDelete { offsets in
//                            for index in offsets {
//                                let med = grouped[person]![index]
//                                modelContext.delete(med)
//                            }
//                        }
//                    }
//                }
//            }
//            .navigationTitle("Medications")
//            .toolbar {
//                ToolbarItem(placement: .topBarTrailing) {
//                    Button("Add") {
//                        showingAddSheet = true
//                    }
//                }
//            }
//            .sheet(isPresented: $showingAddSheet) {
//                AddMedicationView()
//            }
//        }
//    }
//}

// MARK: - Medication List View (Main)
struct MedicationListView: View {
    @State private var showingAddSheet = false
    @Query var medications: [Medication]

    var grouped: [String: [Medication]] {
        Dictionary(
            grouping: medications.sorted(by: {
                ($0.times.first ?? Date.distantFuture) < ($1.times.first ?? Date.distantFuture)
            }),
            by: \.person
        )
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(grouped.sorted(by: { $0.key < $1.key }), id: \.key) { person, meds in
                    MedicationSectionView(person: person, medications: meds)
                }
            }
            .navigationTitle("Medications")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        showingAddSheet = true
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddMedicationView()
            }
        }
    }
}

struct MedicationSectionView: View {
    @Environment(\.modelContext) var modelContext

    let person: String
    let medications: [Medication]

    var body: some View {
        Section(person) {
            ForEach(medications) { med in
                ForEach(Array(med.times.enumerated()), id: \.offset) { index, time in
                    MedicationRowView(medication: med, time: time, index: index)
                }
            }
            .onDelete { offsets in
                for index in offsets {
                    let med = medications[index]
                    modelContext.delete(med)
                }
            }
        }
    }
}


struct MedicationRowView: View {
    @State var medication: Medication
    let time: Date
    let index: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(medication.name).font(.headline)
                Text(medication.dosage).font(.subheadline)
                Text("Time: \(time.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
            }
            Spacer()
            Button(action: {
                medication.taken[index].toggle()
            }) {
                Image(systemName: medication.taken[index] ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(medication.taken[index] ? .green : .gray)
            }
            .buttonStyle(.plain)
        }
    }
}


// MARK: - Add Medication View
struct AddMedicationView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @State private var name: String = ""
    @State private var dosage: String = ""
    @State private var person: String = ""
    @State private var times: [Date] = [Date()]
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Medication Name", text: $name)
                TextField("Dosage (e.g. 5mg)", text: $dosage)
                TextField("Person's Name", text: $person)
                
                ForEach(times.indices, id: \ .self) { index in
                    DatePicker("Time #\(index + 1)", selection: $times[index], displayedComponents: .hourAndMinute)
                }
                .onDelete(perform: deleteTime)
                
                Button("Add Another Time") {
                    times.append(Date())
                }
            }
            .navigationTitle("Add Medication")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let med = Medication(name: name, dosage: dosage, times: times, person: person)
                        modelContext.insert(med)
                        scheduleNotifications(for: med)
                        dismiss()
                    }.disabled(name.isEmpty || dosage.isEmpty || person.isEmpty)
                }
            }
        }
    }
    
    func deleteTime(at offsets: IndexSet) {
        times.remove(atOffsets: offsets)
    }
    
    func scheduleNotifications(for medication: Medication) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            for (i, time) in medication.times.enumerated() {
                let content = UNMutableNotificationContent()
                content.title = "Time to take \(medication.name)"
                content.body = "Dosage: \(medication.dosage) for \(medication.person)"
                content.sound = .default
                
                let components = Calendar.current.dateComponents([.hour, .minute], from: time)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                
                let request = UNNotificationRequest(identifier: "med_\(medication.name)_\(i)", content: content, trigger: trigger)
                center.add(request)
            }
        }
    }
}


#Preview {
    MedicationListView()
}
