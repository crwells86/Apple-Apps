import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins


struct ThumbnailAsyncImage: View {
    let url: URL
    let height: CGFloat
    
    @State private var uiImage: UIImage?
    @State private var dominantColor: Color = .clear
    
    var body: some View {
        ThumbnailAsyncImageContainer(uiImage: uiImage, dominantColor: dominantColor, height: height)
            .task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    guard let img = UIImage(data: data) else { return }
                    uiImage = img
                    if let uicolor = extractDominantColor(from: img) {
                        dominantColor = Color(uicolor)
                    }
                } catch {
                    print("Image load error:", error)
                }
            }
    }
    
    func extractDominantColor(from image: UIImage) -> UIColor? {
        guard let input = CIImage(image: image) else { return nil }
        let filter = CIFilter.areaAverage()
        filter.inputImage = input
        filter.extent = input.extent
        guard let output = filter.outputImage else { return nil }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        let ctx = CIContext(options: [.workingColorSpace: kCFNull!])
        ctx.render(output,
                   toBitmap: &bitmap,
                   rowBytes: 4,
                   bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                   format: .RGBA8,
                   colorSpace: nil)
        
        return UIColor(
            red:   CGFloat(bitmap[0]) / 255,
            green: CGFloat(bitmap[1]) / 255,
            blue:  CGFloat(bitmap[2]) / 255,
            alpha: CGFloat(bitmap[3]) / 255
        )
    }
}
