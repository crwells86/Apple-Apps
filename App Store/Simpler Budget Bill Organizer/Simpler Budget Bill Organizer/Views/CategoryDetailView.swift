import SwiftUI

struct CategoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let fullCategory: [Category]
    
    var body: some View {
        VStack {
            HStack {
                Text("Spending by Category")
                    .font(.title)
                    .fontWeight(.heavy)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding([.horizontal, .top])
            
            List {
                if filteredCategories.isEmpty {
                    ContentUnavailableView {
                        Label("No Category Limits", systemImage: "gauge.with.dots.needle.50percent")
                    } description: {
                        Text("Create categories with limits to track your spending progress.")
                    }
                } else {
                    ForEach(filteredCategories) { category in
                        CategoryBudgetRowView(category: category)
                    }
                }
            }
        }
    }
    
    private var filteredCategories: [Category] {
        fullCategory.filter { $0.limit != nil }
    }
}
