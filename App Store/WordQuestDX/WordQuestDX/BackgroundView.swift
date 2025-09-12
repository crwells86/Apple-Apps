import SwiftUI
import PhotosUI
import StoreKit

struct BackgroundView: View {
    // Persisted values
    @AppStorage("backgroundType") private var storedType: String = BackgroundController.BackgroundType.color.rawValue
    @AppStorage("backgroundColor") private var storedColor: String = "#FD2746"
    @AppStorage("backgroundGradientStart") private var storedGradientStart: String = "#FD2746"
    @AppStorage("backgroundGradientEnd") private var storedGradientEnd: String = "#FA5600"
    @AppStorage("backgroundImagePath") private var storedImagePath: String = ""
    
    @State private var controller = BackgroundController()
    @State private var showPicker = false
    @State private var photoItem: PhotosPickerItem?
    @State private var showColorPicker = false
    @State private var showGradientPicker = false
    
    @Environment(StoreController.self) var storeController
    
    var body: some View {
        NavigationStack {
            ZStack {
                switch controller.type {
                case .color:
                    controller.color.ignoresSafeArea()
                case .gradient:
                    LinearGradient(colors: [controller.gradientStart, controller.gradientEnd],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                case .image:
                    if let uiImage = controller.image {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()
                    } else {
                        LinearGradient(colors: [controller.gradientStart, controller.gradientEnd],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                        .ignoresSafeArea()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack {
                        Menu {
                            Button("Set Color") { showColorPicker = true }
                            Button("Set Gradient") { showGradientPicker = true }
                            Button("Choose Image") { showPicker = true }
                        } label: {
                            Image(systemName: "paintbrush")
                        }
                        .padding(.horizontal)
                        
                        Menu {
                            Button("Restore Purchases") {
                                Task {
                                    await storeController.restorePurchases()
                                }
                            }
                            
                            Button("Rate App") {
                                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                    AppStore.requestReview(in: scene)
                                }
                            }
                            
                            Button("Send Feedback") {
                                if let url = URL(string: "mailto:calebrwells@gmail.com?subject=Word%20Quest%20Feedback") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        } label: {
                            Image(systemName: "gear")
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .sheet(isPresented: $showColorPicker) {
                VStack {
                    ColorPicker("Pick a Color", selection: $controller.color, supportsOpacity: false)
                        .padding()
                    Button("Apply") {
                        controller.type = .color
                        saveState()
                        showColorPicker = false
                    }
                }
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showGradientPicker) {
                VStack {
                    ColorPicker("Gradient Start", selection: $controller.gradientStart, supportsOpacity: false)
                        .padding()
                    ColorPicker("Gradient End", selection: $controller.gradientEnd, supportsOpacity: false)
                        .padding()
                    Button("Apply Gradient") {
                        controller.type = .gradient
                        saveState()
                        showGradientPicker = false
                    }
                }
                .presentationDetents([.medium])
            }
        }
        .photosPicker(isPresented: $showPicker, selection: $photoItem)
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    controller.setImage(data)
                    saveState()
                }
            }
        }
        .onAppear { restoreState() }
    }
    
    private func saveState() {
        storedType = controller.type.rawValue
        storedColor = controller.color.toHex()
        storedGradientStart = controller.gradientStart.toHex()
        storedGradientEnd = controller.gradientEnd.toHex()
        storedImagePath = controller.imagePath
    }
    
    private func restoreState() {
        controller.type = BackgroundController.BackgroundType(rawValue: storedType) ?? .color
        controller.color = Color(hex: storedColor) ?? .blue
        controller.gradientStart = Color(hex: storedGradientStart) ?? .blue
        controller.gradientEnd = Color(hex: storedGradientEnd) ?? .purple
        controller.imagePath = storedImagePath
    }
}

extension URL {
    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}


//MARK: - Encode/decode Color as hex
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
    
    func toHex() -> String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        let rgb: Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        return String(format:"#%06x", rgb)
    }
}

@Observable
class BackgroundController {
    enum BackgroundType: String, Codable {
        case color, gradient, image
    }
    
    var type: BackgroundType = .color
    var color: Color = .blue
    var gradientStart: Color = .blue
    var gradientEnd: Color = .purple
    var imagePath: String = ""
    
    var image: UIImage? {
        guard !imagePath.isEmpty else { return nil }
        let url = URL.documentsDirectory.appendingPathComponent(imagePath)
        return UIImage(contentsOfFile: url.path)
    }
    
    func setImage(_ data: Data) {
        let filename = "background.jpg"
        let url = URL.documentsDirectory.appendingPathComponent(filename)
        try? data.write(to: url)
        imagePath = filename
        type = .image
    }
}
