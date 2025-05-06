import SwiftUI

struct ContentView: View {
    @State private var isSheetShowing = true
    @State private var timeRemaining = 5
    
    let timer = Timer.publish(every: 1, on: .main, in: .common)
        .autoconnect()
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .fullScreenCover(isPresented: $isSheetShowing) {
            Button {
                isSheetShowing.toggle()
            } label: {
                ZStack {
                    Capsule()
                        .foregroundStyle(.red)
                        .frame(height: 55)
                        .padding()
                    
                    Text("Complete Delivery")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
                .overlay(alignment: .trailing) {
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 4)
                            .foregroundStyle(.gray)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(timeRemaining) / 5)
                            .stroke(lineWidth: 4)
                            .foregroundStyle(.white)
                        
                        Text("\(timeRemaining)")
                            .foregroundStyle(.white)
                    }
                    .frame(height: 44)
                    .padding(.trailing, 8)
                    .padding(.trailing)
                }
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .onReceive(timer) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                isSheetShowing.toggle()
            }
        }
    }
}

#Preview {
    ContentView()
}
