import SwiftUI

struct ContentView: View {
    var body: some View {
        ScrollView {
            ForEach(0 ..< 3) { item in
                HStack(alignment: .top) {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .imageScale(.large)
                            .foregroundStyle(.green)
                        
                        if item != Array(0 ..< 3).last {
                            Rectangle()
                                .foregroundStyle(.green)
                                .frame(width: 4)
                        }
                    }
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Hello, world!")
                                .padding(6)
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            
                            Text("What do you remember about your first SwiftUI project?")
                        }
                        
                        Image(.image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 87)
                    }
                    .padding()
                    .background(.indigo)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(alignment: .bottomTrailing) {
                        ZStack {
                            ForEach(0 ..< 2) { item in
                                Image(.guy)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .clipShape(.circle)
                                    .frame(width: 60)
                                    .overlay {
                                        Circle().stroke(Color(.systemBackground), lineWidth: 2)
                                    }
                                    .overlay(alignment: .bottomTrailing) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    }
                                    .offset(x: CGFloat(item * -32), y: 12)
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
}

#Preview {
    ContentView()
}
