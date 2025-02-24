import SwiftUI

struct TabBarButton: View {
    let systemImageName: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: systemImageName)
                    .font(.title)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal)
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    TabBarButton(systemImageName: "dollarsign.gauge.chart.lefthalf.righthalf", title: "Summary", action: { })
}
