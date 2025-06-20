import SwiftUI
import SwiftData

struct VoiceExpenseButton: View {
    @Binding var isRecording: Bool
    @Binding var showingPaywall: Bool
    @Binding var speechRecognizer: SpeechRecognizer
    
    let context: ModelContext
    let allExpenses: [Expense]
    let parseExpense: (String) -> Expense?
    let subscriptionController: SubscriptionController
    
    var body: some View {
        Button(action: {
            if isRecording {
                speechRecognizer.stopRecording()
                isRecording = false
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let recognized = speechRecognizer.recognizedText
                    if let expense = parseExpense(recognized) {
                        if allExpenses.count >= 14 && !subscriptionController.isSubscribed {
                            showingPaywall = true
                        } else {
                            context.insert(expense)
                            try? context.save()
                        }
                    }
                }
                
            } else {
                speechRecognizer.requestPermissions { granted in
                    if granted {
                        speechRecognizer.recognizedText = ""
                        try? speechRecognizer.startRecording()
                        isRecording = true
                    }
                }
            }
        }) {
            Label(isRecording ? "Stop Recording" : "Add Expense (Voice)",
                  systemImage: isRecording ? "mic.slash.fill" : "mic.fill")
            .padding()
            .frame(maxWidth: .infinity)
            .background(isRecording ? Color.red : Color.accentColor)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
    }
}
