import SwiftUI

struct HomeView: View {
    @Bindable var model: LifeModel
    @State private var newGoalTitle = ""
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("You have \(model.yearsLeft) years left")
                    .font(.title)
                    .bold()
                    .padding(.horizontal)
                
                ProgressView(value: Double(model.age) / Double(model.lifeExpectancy)) {
                    Text("\(model.age) of \(model.lifeExpectancy) years lived")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .progressViewStyle(.linear)
                .padding(.horizontal)
                
                Divider()
                
                Text("Your Goals")
                    .font(.headline)
                    .padding(.horizontal)
                
                List {
                    ForEach(model.goals) { goal in
                        HStack {
                            Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(goal.isCompleted ? .green : .primary)
                                .onTapGesture {
                                    goal.isCompleted.toggle()
                                }
                            
                            Text(goal.title)
                                .foregroundStyle(goal.isCompleted ? .secondary : .primary)
                                .strikethrough(goal.isCompleted, color: .secondary)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            _ = model.goals[index]
                            model.goals.remove(at: index)
                        }
                    }
                }
                
                HStack {
                    TextField("New goal", text: $newGoalTitle)
                        .textFieldStyle(.roundedBorder)
                    Button("Add") {
                        guard !newGoalTitle.isEmpty else { return }
                        let newGoal = Goal(title: newGoalTitle)
                        model.goals.append(newGoal)
                        newGoalTitle = ""
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("ETD")
        }
    }
}

#Preview {
    HomeView(model: LifeModel(age: 38, goals: [Goal]()))
}
