import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var isEarningsEntryShowing = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: 0) {
                Text("Summary")
            }
            
            Tab(value: 1) {
                SettingsView()
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .overlay(alignment: .bottom) {
            BottomTabBarView(selectedTab: $selectedTab, isEarningsEntryViewShowing: $isEarningsEntryShowing)
                .padding(.horizontal)
                .offset(y: 18)
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $isEarningsEntryShowing) {
            ScrollView {
                Button {
                    isEarningsEntryShowing.toggle()
                } label: {
                    Image(systemName: "plus.circle.dashed")
                        .font(.title)
                        .rotationEffect(.degrees(45))
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding()
                
                // add more fun stuff
            }
        }
    }
}

#Preview {
    ContentView()
}

struct SettingsView: View {
    @State private var text = ""
    
    var body: some View {
        TextField("Text field", text: $text)
            .textFieldStyle(.roundedBorder)
            .padding()
    }
}
