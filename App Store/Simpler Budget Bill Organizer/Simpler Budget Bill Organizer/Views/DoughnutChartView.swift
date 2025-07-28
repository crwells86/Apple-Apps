import SwiftUI
import SwiftData
import Charts

struct DoughnutChartView: View {
    let data: [CategorySpending]
    
    @Query(sort: \Category.name) private var allCategories: [Category]
    
    @State private var selectedCategory: CategorySpending?
    @State private var isCategoryDetailsPresented = false
    
    var body: some View {
        ZStack {
            VStack {
                Text(selectedCategory?.name ?? "Total")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                
                Text(formattedAmount)
                    .font(.title3)
                    .bold()
            }
            
            Chart(data) { item in
                let isSelected = selectedCategory?.id == item.id
                let outerRadiusRatio = isSelected ? 1.15 : 1.0
                let opacityValue = (selectedCategory == nil || isSelected) ? 1.0 : 0.5
                
                SectorMark(
                    angle: .value("Spending", item.total),
                    innerRadius: .ratio(0.6),
                    outerRadius: .ratio(outerRadiusRatio),
                    angularInset: 1
                )
                .foregroundStyle(by: .value("Category", item.name))
                .opacity(opacityValue)
            }
            .chartLegend(position: .bottom, spacing: 8)
        }
        .frame(height: 300)
        .onTapGesture {
            isCategoryDetailsPresented.toggle()
        }
        .sheet(isPresented: $isCategoryDetailsPresented) {
            CategoryDetailView(fullCategory: allCategories)
        }
    }
    
    // MARK: - Helpers
    
    private var formattedAmount: String {
        let amount = selectedCategory?.total ?? data.reduce(Decimal(0)) { $0 + $1.total }
        return formatCurrency(amount)
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: value as NSDecimalNumber) ?? "$0"
    }
    
    private func angleFrom(center: CGPoint, to point: CGPoint) -> Angle {
        let dx = point.x - center.x
        let dy = center.y - point.y // Flip Y-axis
        var radians = atan2(dy, dx)
        if radians < 0 { radians += 2 * .pi }
        return Angle(radians: radians)
    }
    
    private func distanceFrom(center: CGPoint, to point: CGPoint) -> CGFloat {
        hypot(point.x - center.x, point.y - center.y)
    }
    
    private func categoryAt(angle: Angle) -> CategorySpending? {
        let total = data.reduce(Decimal(0)) { $0 + $1.total }
        var cumulative = Decimal(0)
        
        for item in data {
            let startAngle = cumulative / total * Decimal(360)
            cumulative += item.total
            let endAngle = cumulative / total * Decimal(360)
            
            if angle.degrees >= Double(truncating: startAngle as NSNumber) &&
                angle.degrees < Double(truncating: endAngle as NSNumber) {
                return item
            }
        }
        return nil
    }
}
