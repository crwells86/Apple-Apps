import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Choose your plan")
                .font(.title)
                .fontWeight(.bold)
                .padding()
                .padding(.top)
            
            Text("One subsription, unlimited recipes")
                .fontWeight(.semibold)
                .underline()
                .foregroundStyle(.indigo)
            
            Spacer()
            
            VStack(spacing: -44) {
                HStack {
                    ForEach(0 ..< 5) { _ in
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                    }
                }
                
                TabView {
                    ForEach(0 ..< 3) { _ in
                        Text("Great app for discovering new recipes!")
                            .overlay(alignment: .bottomTrailing) {
                                Text("Steve")
                                    .offset(y: 28)
                            }
                    }
                }
                .tabViewStyle(.page)
                .frame(height: 144)
            }
            
            Spacer()
            
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Yearly")
                            .font(.title2)
                            .fontWeight(.black)
                        
                        ZStack {
                            Capsule()
                                .foregroundStyle(.indigo)
                            
                            Text("Save 87%")
                                .font(.caption2)
                        }
                        .frame(width: 72, height: 16)
                    }
                    
                    Text("12 mo · $20.00")
                }
                
                Spacer()
                
                Text("$1.66/week")
            }
            .padding()
            .background(UnevenRoundedRectangle(topLeadingRadius: 0,
                                               bottomLeadingRadius: 12,
                                               bottomTrailingRadius: 12,
                                               topTrailingRadius: 0,
                                               style: .continuous).stroke(.indigo,lineWidth: 4))
            .overlay(alignment: .top) {
                ZStack {
                    UnevenRoundedRectangle(topLeadingRadius: 12,
                                                       bottomLeadingRadius: 0,
                                                       bottomTrailingRadius: 0,
                                                       topTrailingRadius: 12,
                                                       style: .continuous)
                    .stroke(.indigo,lineWidth: 4)
                    .frame(height: 33)
                    
                    Text("MOST POPULAR")
                        .frame(maxWidth: .infinity)
                        .frame(height: 33)
                        .background(UnevenRoundedRectangle(topLeadingRadius: 12,
                                                           bottomLeadingRadius: 0,
                                                           bottomTrailingRadius: 0,
                                                           topTrailingRadius: 12,
                                                           style: .continuous).fill(.indigo))
                }
                .offset(y: -33)
            }
            .padding(.vertical)
            
            HStack {
                Text("Weekly")
                    .font(.title2)
                    .fontWeight(.black)
                Spacer()
                
                Text("$3.00/week")
            }
            .padding()
            .background(UnevenRoundedRectangle(topLeadingRadius: 12,
                                               bottomLeadingRadius: 12,
                                               bottomTrailingRadius: 12,
                                               topTrailingRadius: 12,
                                               style: .continuous).stroke(.indigo,lineWidth: 4))
            .padding(.top)
        }
        .padding()
        
        Button {
            //
        } label: {
            ZStack {
                Capsule()
                    .fill(.indigo)
                    .frame(height: 44)
                
                Text("Start your 7-day free trial")
                    .foregroundStyle(.white)
            }
        }
        .padding()
        
        Text("No payent due today")
    }
}

#Preview {
    ContentView()
}
