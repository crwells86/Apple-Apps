import SwiftUI

struct WaveView: View {
    var height: CGFloat = 33
    
    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                let t = CGFloat(timeline.date.timeIntervalSinceReferenceDate)
                
                // Slow drifting baseline for natural current
                let current = CGFloat(sin(Double(t * 0.12))) * 0.04
                let shear = CGFloat(sin(Double(t * 0.08))) * 0.6
                
                ZStack {
                    ZStack {
                        // Background wave
                        WaveShape(
                            phase: t * 0.22,
                            amplitude: geo.size.height * 0.14,
                            frequency: 0.4,
                            baseline: 0.38 + current,
                            shear: shear * 0.7,
                            shearPhase: t * 0.4,
                            bottomAmplitude: geo.size.height * 0.06,
                            bottomFrequency: 0.4,
                            bottomPhaseOffset: 0.6
                        )
                        .fill(LinearGradient(colors: [Color.orange.opacity(0.10), Color.orange.opacity(0.02)],
                                             startPoint: .top,
                                             endPoint: .bottom))
                        .blur(radius: 1.5)
                        
                        // Middle wave
                        WaveShape(
                            phase: t * 0.45 + 0.3,
                            amplitude: geo.size.height * 0.12,
                            frequency: 0.53,
                            baseline: 0.42 + current * 1.3,
                            shear: shear * 0.8,
                            shearPhase: t * 0.22,
                            bottomAmplitude: geo.size.height * 0.05,
                            bottomFrequency: 1.3,
                            bottomPhaseOffset: 1.0
                        )
                        .fill(LinearGradient(colors: [Color.orange.opacity(0.14), Color.orange.opacity(0.04)],
                                             startPoint: .top,
                                             endPoint: .bottom))
                        .opacity(0.7)
                        
                        // Foreground wave
                        WaveShape(
                            phase: t * 1.55 + 1.8,
                            amplitude: geo.size.height * 0.08,
                            frequency: 1.87,
                            baseline: 0.49 + current * 1.6,
                            shear: shear * 1.2,
                            shearPhase: t * 0.3,
                            bottomAmplitude: geo.size.height * 0.04,
                            bottomFrequency: 1.87,
                            bottomPhaseOffset: -0.6
                        )
                        .fill(LinearGradient(colors: [Color.blue.opacity(0.20), Color.orange.opacity(0.06)],
                                             startPoint: .top,
                                             endPoint: .bottom))
                        .blendMode(.screen)
                    }
                    .offset(y: 27)
                    
                    ZStack {
                        // Background wave
                        WaveShape(
                            phase: t * 0.45,
                            amplitude: geo.size.height * 0.14,
                            frequency: 0.9,
                            baseline: 0.56 + current,
                            shear: shear * 0.4,
                            shearPhase: t * 0.15,
                            bottomAmplitude: geo.size.height * 0.06,
                            bottomFrequency: 0.9,
                            bottomPhaseOffset: 0.6
                        )
                        .fill(LinearGradient(colors: [Color.blue.opacity(0.10), Color.blue.opacity(0.02)],
                                             startPoint: .top,
                                             endPoint: .bottom))
                        .blur(radius: 1.5)
                        
                        // Middle wave
                        WaveShape(
                            phase: t * 0.92 + 0.6,
                            amplitude: geo.size.height * 0.12,
                            frequency: 1.3,
                            baseline: 0.52 + current * 1.3,
                            shear: shear * 0.8,
                            shearPhase: t * 0.22,
                            bottomAmplitude: geo.size.height * 0.05,
                            bottomFrequency: 1.3,
                            bottomPhaseOffset: 1.0
                        )
                        .fill(LinearGradient(colors: [Color.blue.opacity(0.14), Color.blue.opacity(0.04)],
                                             startPoint: .top,
                                             endPoint: .bottom))
                        .opacity(0.7)
                        
                        // Foreground wave
                        WaveShape(
                            phase: t * 1.55 + 1.8,
                            amplitude: geo.size.height * 0.08,
                            frequency: 1.87,
                            baseline: 0.49 + current * 1.6,
                            shear: shear * 1.2,
                            shearPhase: t * 0.3,
                            bottomAmplitude: geo.size.height * 0.04,
                            bottomFrequency: 1.87,
                            bottomPhaseOffset: -0.6
                        )
                        .fill(LinearGradient(colors: [Color.cyan.opacity(0.20), Color.blue.opacity(0.06)],
                                             startPoint: .top,
                                             endPoint: .bottom))
                        .blendMode(.screen)
                    }
                }
            }
        }
        .frame(height: height)
    }
}

#Preview {
    WaveView(height: 33)
}

struct WaveShape: Shape {
    var phase: CGFloat
    var amplitude: CGFloat
    var frequency: CGFloat
    var baseline: CGFloat
    
    // Shear controls
    var shear: CGFloat = 0.0
    var shearPhase: CGFloat = 0.0
    
    // Bottom wave controls
    var bottomAmplitude: CGFloat = 0.0
    var bottomFrequency: CGFloat = 1.0
    var bottomPhaseOffset: CGFloat = 0.0
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let baselineY = baseline * height
        
        // Top wave
        var topPoints: [CGPoint] = []
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let sine = sin(relativeX * frequency * .pi * 2 + phase)
            let yPos = baselineY + amplitude * sine
            let verticalFactor = yPos / height // top-lag factor
            let xShear = shear * sin(relativeX * .pi * 2 + shearPhase) * verticalFactor
            topPoints.append(CGPoint(x: x + xShear * 20, y: yPos))
        }
        
        // Bottom wave (mirrored, wavy)
        var bottomPoints: [CGPoint] = []
        for x in stride(from: width, through: 0, by: -1) {
            let relativeX = x / width
            let sine = sin(relativeX * bottomFrequency * .pi * 2 + phase + bottomPhaseOffset)
            let yPos = baselineY + bottomAmplitude * sine + amplitude // push below top wave
            let verticalFactor = yPos / height
            let xShear = shear * sin(relativeX * .pi * 2 + shearPhase) * verticalFactor
            bottomPoints.append(CGPoint(x: x + xShear * 20, y: yPos))
        }
        
        // Combine top and bottom points
        if let first = topPoints.first {
            path.move(to: first)
        }
        for point in topPoints {
            path.addLine(to: point)
        }
        for point in bottomPoints {
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}
