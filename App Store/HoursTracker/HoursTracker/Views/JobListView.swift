import SwiftUI
import SwiftData

struct JobListView: View {
    @Environment(\.modelContext) private var context
    @Query private var jobs: [Job]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(jobs) { job in
                    NavigationLink(job.title) {
                        JobDetailView(job: job)
                    }
                }
                .onDelete(perform: deleteJobs)
            }
            .navigationTitle("Jobs")
        }
    }
    
    private func deleteJobs(at offsets: IndexSet) {
        for index in offsets {
            let job = jobs[index]
            context.delete(job)
        }
        try? context.save()
    }
}
