import SwiftUI

struct TimeframePickerView: View {
    @Binding var selectedTimeframe: Timeframe
    
    var body: some View {
        Picker("Timeframe", selection: $selectedTimeframe) {
            ForEach(Timeframe.allCases) { timeframe in
                Text(timeframe.rawValue).tag(timeframe)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
}

#Preview {
    TimeframePickerView(selectedTimeframe: .constant(Timeframe.day))
}
