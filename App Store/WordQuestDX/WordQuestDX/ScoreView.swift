import SwiftUI

struct ScoreView: View {
    @Binding var score: Int
    
    var body: some View {
        Text("Score: \(score)")
            .font(.title2)
            .fontWeight(.semibold)
            .padding()
            .glassEffect(.clear)
            .padding(.vertical)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading)
    }
}


import SwiftUI

struct CustomPuzzleSheet: View {
    @Binding var newTheme: String
    @Binding var selectedDifficulty: Difficulty
    @Environment(\.dismiss) private var dismiss
    
    let onGenerate: (String, Difficulty) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Enter a prompt for your own custom puzzle!")
                    .font(.headline)
                
                TextField("e.g. Space, Animals, Cities", text: $newTheme)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                // Difficulty picker as a segmented control
                Picker("Difficulty", selection: $selectedDifficulty) {
                    ForEach(Difficulty.allCases, id: \.self) { difficulty in
                        Text(difficulty.rawValue).tag(difficulty)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                Button("Generate") {
                    onGenerate(newTheme, selectedDifficulty)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Custom Puzzle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Dismiss") {
                        dismiss()
                    }
                }
            }
        }
    }
}
