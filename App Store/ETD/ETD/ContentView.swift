import SwiftUI
import SwiftData

struct ContentView: View {
    @Query var lifeModels: [LifeModel]
    @Environment(\.modelContext) private var context
    @State private var model: LifeModel?
    
    var body: some View {
        if let model = model ?? lifeModels.first {
            HomeView(model: model)
        } else {
            OnboardingView { age in
                let newModel = LifeModel(age: age)
                context.insert(newModel)
                model = newModel
            }
        }
    }
}

#Preview {
    ContentView()
}
