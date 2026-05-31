import SwiftUI

struct PlansView: View {
    @State private var controller = PlansController()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PlansTabBar(selectedTab: $controller.selectedTab)
                        .padding(.horizontal, 16)
                    
                    tabContent
                }
                .padding(.top, 8)
            }
            .navigationTitle("Plans")
            .navigationBarTitleDisplayMode(.large)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .sheet(isPresented: $controller.isAddingBudget) {
            // Swap in your real AddBudgetView here
            Text("Add Budget")
                .presentationDetents([.medium])
        }
    }
    
    // MARK: - Tab content switcher
    
    @ViewBuilder
    private var tabContent: some View {
        switch controller.selectedTab {
        case .budgets:
            BudgetListView(controller: controller)
        case .bills:
            placeholderView(for: "Bills")
        case .goals:
            placeholderView(for: "Goals")
        case .debt:
            placeholderView(for: "Debt")
        }
    }
    
    private func placeholderView(for title: String) -> some View {
        ContentUnavailableView(
            title,
            systemImage: "clock",
            description: Text("Coming soon")
        )
        .padding(.top, 60)
    }
}

#Preview {
    NavigationStack {
        PlansView()
    }
}
















import SwiftUI
import SwiftData
import Observation

/// Drives the entire Plans screen.
/// Views query this object — they never own logic themselves.
@Observable
final class PlansController {
    
    // MARK: - Tab state
    
    enum Tab: String, CaseIterable {
        case budgets = "Budgets"
        case bills   = "Bills"
        case goals   = "Goals"
        case debt    = "Debt"
    }
    
    var selectedTab: Tab = .budgets
    
    // MARK: - Budget data
    
    /// The items shown in the Budgets list.
    /// In production, populate this by querying SwiftData and summing `Expense` amounts per `Category`.
    var budgetItems: [BudgetItem] = BudgetItem.preview
    
    var isAddingBudget = false
    
    // MARK: - Intent handlers
    
    func addBudgetTapped() {
        isAddingBudget = true
    }
    
    func deleteBudgets(at offsets: IndexSet) {
        budgetItems.remove(atOffsets: offsets)
    }
    
    /// Call this after you've created or saved a new budget in your sheet/modal.
    func budgetAdded(_ item: BudgetItem) {
        budgetItems.append(item)
        isAddingBudget = false
    }
}

// MARK: - Preview data

extension BudgetItem {
    static let preview: [BudgetItem] = [
        BudgetItem(id: UUID(), name: "Dining",        icon: "fork.knife",        iconTint: .red,    spent: 425, limit: 500),
        BudgetItem(id: UUID(), name: "Groceries",     icon: "cart.fill",         iconTint: .green,  spent: 240, limit: 400),
        BudgetItem(id: UUID(), name: "Transport",     icon: "car.fill",          iconTint: .blue,   spent: 120, limit: 300),
        BudgetItem(id: UUID(), name: "Entertainment", icon: "popcorn.fill",      iconTint: .purple, spent: 40,  limit: 200),
    ]
}

















import SwiftUI

/// A pure display model for a single budget category row.
/// Bridges your SwiftData `Category` + spending totals into something views can bind to directly.
struct BudgetItem: Identifiable {
    let id: UUID
    let name: String
    let icon: String          // SF Symbol name
    let iconTint: Color
    let spent: Decimal
    let limit: Decimal
    
    /// 0.0 – 1.0
    var progress: Double {
        guard limit > 0 else { return 0 }
        return NSDecimalNumber(decimal: spent / limit).doubleValue
    }
    
    /// Semantic color that shifts from calm → urgent as spending rises.
    var progressColor: Color {
        switch progress {
        case ..<0.5:  return .purple
        case ..<0.65: return .blue
        case ..<0.80: return .green
        default:      return .red
        }
    }
    
    var percentageText: String {
        "\(Int((progress * 100).rounded()))%"
    }
    
    var spendingText: String {
        "\(spent.currencyFormatted) / \(limit.currencyFormatted)"
    }
}

// MARK: - Convenience factory from your SwiftData models

extension BudgetItem {
    /// Build a `BudgetItem` from a SwiftData `Category` + a precomputed spending total.
    init(category: Category, spent: Decimal) {
        self.id = category.id
        self.name = category.name
        self.icon = category.icon
        self.iconTint = .accentColor   // swap for per-category tint if you add one
        self.spent = spent
        self.limit = category.limit ?? 0
    }
}

// MARK: - Decimal formatting helper

private extension Decimal {
    var currencyFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: self as NSDecimalNumber) ?? "$0"
    }
}














import SwiftUI

/// Segmented tab selector for the Plans screen.
/// Pure display — owns no logic; selection state lives in `PlansController`.
struct PlansTabBar: View {
    
    @Binding var selectedTab: PlansController.Tab
    @Namespace private var ns
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(PlansController.Tab.allCases, id: \.self) { tab in
                tabPill(for: tab)
            }
        }
        .padding(4)
        .background(.quaternary, in: Capsule())
    }
    
    @ViewBuilder
    private func tabPill(for tab: PlansController.Tab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            Text(tab.rawValue)
                .font(.subheadline.weight(selectedTab == tab ? .semibold : .regular))
                .foregroundStyle(selectedTab == tab ? .white : .secondary)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background {
                    if selectedTab == tab {
                        Capsule()
                            .fill(Color.accentColor)
                            .matchedGeometryEffect(id: "pill", in: ns)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var tab = PlansController.Tab.budgets
    PlansTabBar(selectedTab: $tab)
        .padding()
}









import SwiftUI

/// Renders the scrollable list of budget rows and the "+ New Budget" button.
/// Displays data — delegates all mutations to `PlansController`.
struct BudgetListView: View {
    
    @Bindable var controller: PlansController
    
    var body: some View {
        VStack(spacing: 0) {
            budgetList
            Spacer(minLength: 0)
            addButton
                .padding(.bottom, 24)
        }
    }
    
    // MARK: - Sub-views
    
    private var budgetList: some View {
        LazyVStack(spacing: 0) {
            ForEach(controller.budgetItems) { item in
                BudgetRowView(item: item)
                
                if item.id != controller.budgetItems.last?.id {
                    Divider()
                        .padding(.leading, 78)
                }
            }
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
    }
    
    private var addButton: some View {
        Button {
            controller.addBudgetTapped()
        } label: {
            Label("New Budget", systemImage: "plus")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .padding(.vertical, 14)
                .padding(.horizontal, 32)
                .background(.background, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    BudgetListView(controller: PlansController())
        .background(Color(.systemGroupedBackground))
}










import SwiftUI

/// Displays a single budget category row: icon, name, spending, progress bar, percentage.
/// Purely display — receives a `BudgetItem` value.
struct BudgetRowView: View {
    
    let item: BudgetItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 14) {
                CategoryIconView(symbol: item.icon, tint: item.iconTint)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(item.spendingText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(item.percentageText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            
            BudgetProgressBar(progress: item.progress, color: item.progressColor)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
    }
}

#Preview {
    BudgetRowView(item: BudgetItem.preview[0])
        .background(.background)
}












import SwiftUI

/// A colored progress bar that fills from leading to trailing.
/// Purely display — zero logic.
struct BudgetProgressBar: View {
    
    let progress: Double   // 0.0 – 1.0
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(color.opacity(0.2))
                
                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * max(0, min(1, progress)))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
            }
        }
        .frame(height: 6)
    }
}

#Preview {
    VStack(spacing: 12) {
        BudgetProgressBar(progress: 0.85, color: .red)
        BudgetProgressBar(progress: 0.60, color: .green)
        BudgetProgressBar(progress: 0.40, color: .blue)
        BudgetProgressBar(progress: 0.20, color: .purple)
    }
    .padding()
}














import SwiftUI

/// A tinted SF Symbol inside a soft circular background.
/// Purely display — pass in symbol name and tint color.
struct CategoryIconView: View {
    
    let symbol: String
    let tint: Color
    var size: CGFloat = 48
    
    var body: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.15))
                .frame(width: size, height: size)
            
            Image(systemName: symbol)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(tint)
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        CategoryIconView(symbol: "fork.knife",   tint: .red)
        CategoryIconView(symbol: "cart.fill",    tint: .green)
        CategoryIconView(symbol: "car.fill",     tint: .blue)
        CategoryIconView(symbol: "popcorn.fill", tint: .purple)
    }
    .padding()
}
