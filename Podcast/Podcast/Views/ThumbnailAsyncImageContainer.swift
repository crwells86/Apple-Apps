import SwiftUI

struct ThumbnailAsyncImageContainer: View {
    let uiImage: UIImage?
    let dominantColor: Color
    let height: CGFloat
    
    var body: some View {
        ZStack(alignment: .top) {
            dominantColor
            if let img = uiImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(height: height)
                    .cornerRadius(8)
                    .padding()
            } else {
                ProgressView()
                    .frame(height: height)
            }
        }
        .cornerRadius(12)
    }
}
