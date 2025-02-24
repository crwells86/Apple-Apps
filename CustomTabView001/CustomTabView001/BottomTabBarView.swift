import SwiftUI

struct BottomTabBarView: View {
    @Binding var selectedTab: Int
    @Binding var isEarningsEntryViewShowing: Bool
    
    var body: some View {
        ZStack {
            UnevenRoundedRectangle(topLeadingRadius: 0,
                                   bottomLeadingRadius: 42,
                                   bottomTrailingRadius: 42,
                                   topTrailingRadius: 0,
                                   style: .continuous)
            .fill(.ultraThickMaterial)
            
            HStack {
                TabBarButton(systemImageName: "dollarsign.gauge.chart.lefthalf.righthalf", title: "Summary") {
                    selectedTab = 0
                }
                
                UnevenRoundedRectangle(topLeadingRadius: 0,
                                       bottomLeadingRadius: 100,
                                       bottomTrailingRadius: 100,
                                       topTrailingRadius: 0,
                                       style: .continuous)
                .fill(Color(.systemBackground))
                .frame(width: 80)
                .padding([.leading, .trailing, .bottom])
                .padding(.bottom)
                .overlay(alignment: .top) {
                    Button {
                        isEarningsEntryViewShowing.toggle()
                    } label: {
                        Image(systemName: "plus.circle.dashed")
                            .font(.system(size: 55))
                    }
                    .offset(y: -20)
                }
                
                TabBarButton(systemImageName: "gear", title: "Settings") {
                    selectedTab = 1
                }
            }
        }
        .frame(height: 80)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    BottomTabBarView(selectedTab: .constant(0), isEarningsEntryViewShowing: .constant(false))
        .padding(40)
}
