import SwiftUI

struct ContentView: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(0..<100) { number in
                    LinearGradient(gradient: Gradient(colors: [.red, .blue]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .frame(height: 220)
                        .containerRelativeFrame(.horizontal)
                        .overlay {
                            Text("\(number)")
                                .font(.largeTitle)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                        }
                        .scrollTransition { effect, phase in
                            effect
                                .opacity(phase.isIdentity ? 1 : 0.5)
                                .scaleEffect(phase.isIdentity ? 1 : 0.8)
                        }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .contentMargins(16)
    }
}

#Preview {
    ContentView()
}
