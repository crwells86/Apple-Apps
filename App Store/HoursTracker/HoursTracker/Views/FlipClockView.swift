import SwiftUI

struct FlipClockView: View {
    @Binding var value: Int
    let size: CGSize
    let fontSize: CGFloat
    let cornerRadius: CGFloat
    let foregroundColor: Color
    let backgroundColor: Color
    let animationDuration: CGFloat = 0.8
    
    @State private var nextValue = 0
    @State private var currentValue = 0
    @State private var rotation: CGFloat = 0
    
    var body: some View {
        let halfHeight = size.height * 0.5
        
        ZStack {
            UnevenRoundedRectangle(topLeadingRadius: cornerRadius, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: cornerRadius, style: .continuous)
                .fill(backgroundColor.shadow(.inner(radius: 1)))
                .frame(height: halfHeight)
                .overlay(alignment: .top) {
                    TextView(nextValue)
                        .frame(width: size.width, height: size.height)
                        .drawingGroup()
                }
                .clipped()
                .frame(maxHeight: .infinity, alignment: .top)
            
            UnevenRoundedRectangle(topLeadingRadius: cornerRadius, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: cornerRadius, style: .continuous)
                .fill(backgroundColor.shadow(.inner(radius: 1)))
                .frame(height: halfHeight)
                .modifier(RotationModifier(rotation: rotation,
                                           nextValue: nextValue,
                                           currentValue: currentValue,
                                           fontSize: fontSize,
                                           foregroundColor: foregroundColor,
                                           size: size))
                .clipped()
                .rotation3DEffect(.init(degrees: rotation),
                                  axis: (x: 1.0, y: 0.0, z: 0.0),
                                  anchor: .bottom,
                                  perspective: 0.4)
                .frame(maxHeight: .infinity, alignment: .top)
                .zIndex(10)
            
            UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: cornerRadius, bottomTrailingRadius: cornerRadius, topTrailingRadius: 0, style: .continuous)
                .fill(backgroundColor.shadow(.inner(radius: 0)))
                .frame(height: halfHeight)
                .overlay(alignment: .bottom) {
                    TextView(currentValue)
                        .frame(width: size.width, height: size.height)
                        .drawingGroup()
                }
                .clipped()
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(width: size.width, height: size.height)
        .onChange(of: value, initial: true) { oldValue, newValue in
            currentValue = oldValue
            nextValue = newValue
            
            guard rotation == 0 else {
                currentValue = value
                return
            }
            
            guard oldValue != newValue else { return }
            
            withAnimation(.easeInOut(duration: animationDuration), completionCriteria: .logicallyComplete) {
                rotation = -180
            } completion: {
                rotation = 0
                currentValue = newValue
            }
        }
    }
    
    @ViewBuilder
    func TextView(_ value: Int) -> some View {
        Text("\(value)")
            .font(.system(size: fontSize))
            .fontWeight(.bold)
            .foregroundStyle(foregroundColor)
            .lineLimit(1)
    }
}

fileprivate struct RotationModifier: ViewModifier, Animatable {
    var rotation: CGFloat
    var nextValue: Int
    var currentValue: Int
    var fontSize: CGFloat
    var foregroundColor: Color
    var size: CGSize
    
    var animatableData: CGFloat {
        get { rotation }
        set { rotation = newValue }
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                Group {
                    if -rotation > 90 {
                        Text("\(nextValue)")
                            .font(.system(size: fontSize))
                            .fontWeight(.bold)
                            .foregroundStyle(foregroundColor)
                            .scaleEffect(x: 1, y: -1)
                            .transition(.identity)
                            .lineLimit(1)
                    } else {
                        Text("\(currentValue)")
                            .font(.system(size: fontSize))
                            .fontWeight(.bold)
                            .foregroundStyle(foregroundColor)
                            .transition(.identity)
                            .lineLimit(1)
                    }
                }
                .frame(width: size.width, height: size.height)
                .drawingGroup()
            }
    }
}
