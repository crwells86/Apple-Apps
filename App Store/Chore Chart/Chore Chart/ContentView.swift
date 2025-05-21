import SwiftUI

struct ContentView: View {
    var body: some View {
        ChoreTemplateBrowserView()
    }
}

#Preview {
    ContentView()
}



import SwiftData
import Foundation

@Model
class ChoreGroup {
    var title: String
    var createdAt: Date

//    @Relationship(deleteRule: .cascade, inverse: \ChoreTemplate.group)
    var templates: [ChoreTemplate]

    init(title: String, templates: [ChoreTemplate] = []) {
        self.title = title
        self.createdAt = .now
        self.templates = templates
    }
}



@Model
class ChoreTemplate {
    var title: String
    var category: ChoreCategory
    var notes: String?
    var isFavorite: Bool
    var assignedPerson: String
    var scheduledDays: [Weekday]

    // NEW 🔗
    @Relationship(inverse: \ChoreGroup.templates)
    var group: ChoreGroup?

    init(
        title: String,
        category: ChoreCategory,
        notes: String? = nil,
        isFavorite: Bool = false,
        assignedPerson: String = "",
        scheduledDays: [Weekday] = [],
        group: ChoreGroup? = nil
    ) {
        self.title = title
        self.category = category
        self.notes = notes
        self.isFavorite = isFavorite
        self.assignedPerson = assignedPerson
        self.scheduledDays = scheduledDays
        self.group = group
    }
}


struct ChoreGroupBrowserView: View {
    @Query(sort: \ChoreGroup.createdAt) private var groups: [ChoreGroup]
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            List {
                ForEach(groups) { group in
                    NavigationLink(destination: ChoreGroupDetailView(group: group)) {
                        VStack(alignment: .leading) {
                            Text(group.title).font(.headline)
                            Text("\(group.templates.count) chores")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { indices in
                    for index in indices {
                        context.delete(groups[index])
                    }
                }
            }
            .navigationTitle("Chore Groups")
            .toolbar {
                NavigationLink("Add Group") {
                    ChoreGroupFormView()
                }
            }
        }
    }
}


struct ChoreGroupFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var title = ""

    var body: some View {
        Form {
            Section("Group Info") {
                TextField("Group Title", text: $title)
            }

            Button("Create Group") {
                let newGroup = ChoreGroup(title: title)
                context.insert(newGroup)
                try? context.save()
                dismiss()
            }
            .disabled(title.isEmpty)
        }
        .navigationTitle("New Chore Group")
    }
}


struct ChoreGroupDetailView: View {
    @Bindable var group: ChoreGroup

    var body: some View {
        List {
            ForEach(group.templates) { template in
                VStack(alignment: .leading) {
                    Text(template.title)
                    Text(template.assignedPerson)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(group.title)
    }
}
