import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

typealias InfoTile     = StatCard
typealias SummaryBlock = StatCard
typealias ValueCard    = StatCard
typealias DataPanel    = StatCard
typealias HighlightBox = StatCard
typealias KPIView      = StatCard
