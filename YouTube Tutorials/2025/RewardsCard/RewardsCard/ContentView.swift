import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(.purple)
            
            HStack {
                ZStack(alignment: .bottom) {
                    UnevenRoundedRectangle(topLeadingRadius: 12,
                                           bottomLeadingRadius: 4,
                                           bottomTrailingRadius: 12,
                                           topTrailingRadius: 4,
                                           style: .continuous)
                    .fill(.mint)
                    .padding(.horizontal)
                    .overlay(alignment: .top) {
                        Text("Spend $100\nor more")
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                            .padding(.vertical)
                    }
                    
                    
                    ZStack {
                        Circle()
                            .foregroundStyle(.white)
                            .frame(height: 87)
                            .overlay {
                                Circle()
                                    .stroke(.orange, lineWidth: 6)
                                    .frame(width: 66, height: 66)
                                    .padding()
                            }
                        
                        VStack(spacing: -2) {
                            Text("Collect")
                                .font(.caption2)
                            
                            Text("5x")
                                .font(.title3)
                            
                                Text("points")
                                    .font(.caption2)
                        }
                        .padding()
                    }
                    .offset(y: 18)
                }
                .frame(width: 100, height: 120)
                .padding(.leading, 42)
                
                Spacer()
                
                Image(systemName: "desktopcomputer.and.macbook")
                    .font(.system(size: 72))
                    .foregroundStyle(.white)
            }
            .padding()
        }
        .frame(height: 220)
        .overlay(alignment: .bottomLeading) {
            ZStack {
                UnevenRoundedRectangle(topLeadingRadius: 12,
                                       bottomLeadingRadius: 4,
                                       bottomTrailingRadius: 12,
                                       topTrailingRadius: 4,
                                       style: .continuous)
                .fill(.orange)
                .frame(width: 170, height: 33)
                
                Label("Everyday market!", systemImage: "storefront")
                    .font(.system(size: 14, design: .rounded))
                
            }
            .padding(.leading)
            .offset(y: 15)
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ContentView()
        .padding()
        .padding(.bottom)
}
