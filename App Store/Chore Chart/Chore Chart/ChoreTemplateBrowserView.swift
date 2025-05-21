import SwiftUI
import SwiftData

struct ChoreTemplateBrowserView: View {
    @Environment(\.modelContext) private var context
    @Query private var allTemplates: [ChoreTemplate]
    
    @State private var selectedCategory: ChoreCategory? = nil
    @State private var showAddTemplate = false
    
    var filteredTemplates: [ChoreTemplate] {
        if let category = selectedCategory {
            return allTemplates.filter { $0.category == category }
        } else {
            return allTemplates
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        Button("All") {
                            selectedCategory = nil
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedCategory == nil ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                        .clipShape(Capsule())
                        
                        ForEach(ChoreCategory.allCases) { category in
                            Button(category.rawValue) {
                                selectedCategory = category
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedCategory == category ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal)
                }
                
                List {
                    ForEach(filteredTemplates) { template in
                        NavigationLink {
                            ChoreTemplateFormView(template: template)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(template.title)
                                    .font(.headline)
                                
                                Text(template.assignedPerson)
                                if let notes = template.notes {
                                    Text(notes)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Chore Templates")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddTemplate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddTemplate) {
                NavigationStack {
                    ChoreTemplateFormView(template: ChoreTemplate(title: "", category: .general))
                }
            }
        }
        .onAppear {
            seedDefaultChoreTemplates(context: context)
        }
    }
}

#Preview {
    ChoreTemplateBrowserView()
}


import SwiftUI
import SwiftData

struct ChoreTemplateFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var template: ChoreTemplate
    
    
    @Query(sort: \ChoreGroup.title) var allGroups: [ChoreGroup]
    
    @State private var showAddGroupSheet = false
    
    
    var body: some View {
        Form {
            // ── Details ───────────────────────
            Section("Chore Details") {
                TextField("Chore Title", text: $template.title)
                
                Picker("Category", selection: $template.category) {
                    ForEach(ChoreCategory.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                
                TextField("Notes", text: Binding(
                    get: { template.notes ?? "" },
                    set: { template.notes = $0.isEmpty ? nil : $0 }
                ))
            }
            
            // ── Assignment ────────────────────
            Section("Assignment") {
                TextField("Assigned Person", text: $template.assignedPerson)
                    .textInputAutocapitalization(.words)
            }
            
            // ── Schedule ──────────────────────
            Section("Scheduled Days") {
                ForEach(Weekday.allCases) { day in
                    Toggle(day.displayName, isOn: Binding(
                        get: { template.scheduledDays.contains(day) },
                        set: { isOn in
                            if isOn {
                                template.scheduledDays.append(day)
                            } else {
                                template.scheduledDays.removeAll { $0 == day }
                            }
                        }
                    ))
                }
            }
            
            Section("Group") {
                Picker("Group", selection: $template.group) {
                    Text("None").tag(nil as ChoreGroup?)
                    ForEach(allGroups) { group in
                        Text(group.title).tag(Optional(group))
                    }
                }
                
                Button(action: {
                    showAddGroupSheet = true
                }) {
                    Label("Add New Group", systemImage: "plus.circle")
                }
                .buttonStyle(.borderless)
            }
        }
        .sheet(isPresented: $showAddGroupSheet) {
            AddGroupView { newGroupTitle in
                let newGroup = ChoreGroup(title: newGroupTitle)
                context.insert(newGroup)
                try? context.save()
                template.group = newGroup
                showAddGroupSheet = false
            }
        }
        //    }
        .navigationTitle(template.title.isEmpty ? "New Template" : "Edit Template")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    context.delete(template)
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    guard template.title.isEmpty == false else { return }
                    context.insert(template)
                    try? context.save()
                    dismiss()
                }
            }
        }
    }
}




struct AddGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    
    var onSave: (String) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Group Title", text: $title)
            }
            .navigationTitle("New Group")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if !title.isEmpty {
                            onSave(title)
                        }
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}




import SwiftData
import Foundation

import SwiftData
import Foundation

/// Days of the week you can schedule a chore on.
enum Weekday: String, CaseIterable, Identifiable, Codable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday
    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}

//@Model
//class ChoreTemplate {
//    var title: String
//    var category: ChoreCategory
//    var notes: String?
//    var isFavorite: Bool
//    var assignedPerson: String
//    var scheduledDays: [Weekday]
//
//    init(
//        title: String,
//        category: ChoreCategory,
//        notes: String? = nil,
//        isFavorite: Bool = false,
//        assignedPerson: String = "",
//        scheduledDays: [Weekday] = []
//    ) {
//        self.title = title
//        self.category = category
//        self.notes = notes
//        self.isFavorite = isFavorite
//        self.assignedPerson = assignedPerson
//        self.scheduledDays = scheduledDays
//    }
//}



enum ChoreCategory: String, CaseIterable, Codable, Identifiable {
    case general = "General"
    case kitchen = "Kitchen"
    case bathroom = "Bathroom"
    case bedroom = "Bedroom"
    case livingRoom = "Living Room"
    case kidsRoom = "Kids’ Room"
    case laundry = "Laundry"
    case outdoors = "Outdoors"
    case petCare = "Pet Care"
    case seasonal = "Seasonal"
    case office = "Office"
    case personal = "Personal"
    
    var id: String { rawValue }
}



import SwiftUI
import SwiftData

@MainActor
func seedDefaultChoreTemplates(context: ModelContext) {
    let existingTemplates = (try? context.fetch(FetchDescriptor<ChoreTemplate>())) ?? []
    guard existingTemplates.isEmpty else { return }
    
    let chores: [(String, ChoreCategory)] = [
        // General
        ("Make the bed", .general),
        ("Take out trash", .general),
        ("Water plants", .general),
        ("Vacuum all floors", .general),
        ("Wipe down surfaces", .general),
        
        // Kitchen
        ("Load dishwasher", .kitchen),
        ("Unload dishwasher", .kitchen),
        ("Clean countertops", .kitchen),
        ("Clean fridge", .kitchen),
        ("Mop kitchen floor", .kitchen),
        
        // Bathroom
        ("Scrub toilet", .bathroom),
        ("Clean shower", .bathroom),
        ("Wipe mirror", .bathroom),
        ("Change towels", .bathroom),
        ("Restock toilet paper", .bathroom),
        
        // Bedroom
        ("Change sheets", .bedroom),
        ("Dust nightstand", .bedroom),
        ("Organize closet", .bedroom),
        ("Vacuum bedroom", .bedroom),
        ("Wipe windows", .bedroom),
        
        // Living Room
        ("Dust shelves", .livingRoom),
        ("Vacuum couch", .livingRoom),
        ("Fluff pillows", .livingRoom),
        ("Tidy books", .livingRoom),
        ("Wipe remote controls", .livingRoom),
        
        // Kids’ Room
        ("Put away toys", .kidsRoom),
        ("Change crib sheets", .kidsRoom),
        ("Sanitize toys", .kidsRoom),
        ("Organize books", .kidsRoom),
        ("Vacuum rug", .kidsRoom),
        
        // Laundry
        ("Wash clothes", .laundry),
        ("Fold clothes", .laundry),
        ("Iron shirts", .laundry),
        ("Sort laundry", .laundry),
        ("Clean lint trap", .laundry),
        
        // Outdoors
        ("Sweep porch", .outdoors),
        ("Water garden", .outdoors),
        ("Weed flower bed", .outdoors),
        ("Mow lawn", .outdoors),
        ("Wash windows outside", .outdoors),
        
        // Pet Care
        ("Feed pet", .petCare),
        ("Change litter box", .petCare),
        ("Walk dog", .petCare),
        ("Brush pet", .petCare),
        ("Clean pet area", .petCare),
        
        // Seasonal
        ("Spring clean baseboards", .seasonal),
        ("Declutter garage", .seasonal),
        ("Wash curtains", .seasonal),
        ("Clean gutters", .seasonal),
        ("Rotate mattresses", .seasonal),
        
        // Office
        ("Sort paperwork", .office),
        ("Clean keyboard", .office),
        ("Dust monitor", .office),
        ("Empty trash bin", .office),
        ("Vacuum office rug", .office),
        
        // Personal
        ("Plan weekly meals", .personal),
        ("Organize backpack", .personal),
        ("Schedule appointments", .personal),
        ("Refill prescriptions", .personal),
        ("Check calendar", .personal)
    ]
    
    for (title, category) in chores {
        let chore = ChoreTemplate(title: title, category: category)
        context.insert(chore)
    }
    
    try? context.save()
}
