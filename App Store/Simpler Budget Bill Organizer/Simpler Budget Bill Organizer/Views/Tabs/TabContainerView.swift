import SwiftUI

struct TabContainerView: View {
    @State private var tabSelection = 1
    @State private var isShowingSheet = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $tabSelection) {
                Tab("Summary", systemImage: "dollarsign.gauge.chart.leftthird.topthird.rightthird", value: 1) {
                    NavigationStack { Text("Summary").navigationTitle("Summary") }
                }
                
                Tab("Transactions", systemImage: "list.bullet.rectangle", value: 2) {
                    NavigationStack { AddTransactionView() }
                }
                
                Tab("Assistant", systemImage: "sparkles", value: 4) {
                    NavigationStack { Text("Assistant").navigationTitle("Assistant") }
                }
                
                Tab("Plans", systemImage: "pencil.and.list.clipboard", value: 5) {
                    NavigationStack { PlansView() }
                }
            }
            
            if tabSelection != 4 {
                FloatingActionButton {
                    isShowingSheet = true
                }
            }
        }
        .sheet(isPresented: $isShowingSheet) {
            Text("Sheet content here")
                .presentationDetents([.medium, .large])
        }
    }
}

#Preview {
    TabContainerView()
}
