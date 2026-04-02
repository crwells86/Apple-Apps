import SwiftUI

struct CategoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State var fullCategory: [Category]
    @State private var isAddCategorySheetPresented = false
    
    
    @State private var name: String = ""
    @State private var selectedIcon: String = ""
    @State private var categoryMode: CategoryViewMode = .select
//    @Query(sort: \Category.name) private var categories: [Category]
    @State private var showingEmojiPicker = false
    
    @State private var limit: Decimal?
    @State private var enableReminders: Bool = false
    @FocusState var isInputActive: Bool
    
    @State private var editingCategory: Category?
    @State private var isEditingCategory: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                Text("Spending by Category")
                    .font(.title)
                    .fontWeight(.heavy)
                
                Spacer()
                
                Button {
                    isAddCategorySheetPresented.toggle()
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding([.horizontal, .top])
//            .sheet(isPresented: $isAddCategorySheetPresented) {
//                AddCategorySheet { newCategory in
//                    fullCategory.append(newCategory)
//                    isAddCategorySheetPresented = false
//                }
//            }
            .sheet(isPresented: $isAddCategorySheetPresented) {
                AddCategorySheet { updatedCategory in
                    if let index = fullCategory.firstIndex(where: { $0.id == updatedCategory.id }) {
                        fullCategory[index] = updatedCategory
                    } else {
                        fullCategory.append(updatedCategory)
                    }

                    // Reset editing state
                    editingCategory = nil
                    isAddCategorySheetPresented = false
                }
            }

            
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
//                            .swipeActions {
//                                Button {
//                                    isEditingCategory.toggle()
//                                } label: {
//                                    Label("Edit", systemImage: "square.and.pencil")
//                                }
//                                .tint(.green)
//                            }
//                            .sheet(isPresented: $isEditingCategory) {
//                                EditCategorySheet(category: category) { _ in
//                                    if let index = fullCategory.firstIndex(where: { $0.id == category.id }) {
//                                        fullCategory[index] = category
//                                    }
//                                }
//                            }
                    }
                }
            }
        }
    }
    
    private var filteredCategories: [Category] {
        fullCategory.filter { $0.limit != nil }
    }
}
