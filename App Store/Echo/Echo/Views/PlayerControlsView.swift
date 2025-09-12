import SwiftUI

import SwiftUI

struct PlayerControlsView: View {
    var isPlaying: Bool
    var onPlayToggle: () -> Void
    var onBack: () -> Void
    var onForward: () -> Void
    var progress: Double
    
    var body: some View {
        HStack(spacing: 18) {
            //            Button(action: onBack) {
            //                Image(systemName: "gobackward.15")
            //                    .font(.title2)
            //            }
            //            Button(action: onPlayToggle) {
            //                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
            //                    .font(.title2)
            //                    .frame(width: 52, height: 52)
            //                    .background(.white, in: Circle())
            //                    .shadow(radius: 3)
            //            }
            
            Button {
                onPlayToggle()
            } label: {
                ZStack {
                    Circle()
                        .fill(.clear)
                        .frame(width: 66, height: 66)
                    
                    Circle()
                        .frame(width: 66, height: 66)
                        .scaleEffect(isPlaying ? 1.06 : 1.0)
                        .animation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true), value: isPlaying)
                    
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(.white)
                }
                
                //            Button(action: onForward) {
                //                Image(systemName: "goforward.15")
                //                    .font(.title2)
                //            }
            }
//            .padding()
            .buttonStyle(.plain)
            .glassEffect(.clear, in: .circle)
//            .frame(maxWidth: .infinity)
//            .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

#Preview {
    ZStack {
        WaveView(height: 66)
        
        PlayerControlsView(isPlaying: true, onPlayToggle: {}, onBack: {}, onForward: {}, progress: 0.5)
        
    }
}
