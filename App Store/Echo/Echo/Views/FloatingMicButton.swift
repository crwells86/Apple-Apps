import SwiftUI

struct FloatingMicButton: View {
    var isRecording: Bool
    var action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                Circle()
                    .fill(isRecording ? .red.opacity(0.27) : .clear)
                    .frame(width: 66, height: 66)
                
                Circle()
                    .frame(width: 66, height: 66)
                    .scaleEffect(isRecording ? 1.06 : 1.0)
                    .animation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true), value: isRecording)
                
                Image(systemName: isRecording ? "waveform" : "mic.fill")
                    .font(.title)
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .glassEffect(.clear, in: .circle)
    }
}

#Preview {
    ZStack {
        WaveView(height: 66)
        
        FloatingMicButton(isRecording: true) { }
    }
}
