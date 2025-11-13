import SwiftUI
import PhotosUI
import SwiftData

// MARK: - Favorite Scripture Model
@Model
final class FavoriteScripture {
    var reference: String
    var text: String
    var dateAdded: Date
    
    init(reference: String, text: String, dateAdded: Date = Date()) {
        self.reference = reference
        self.text = text
        self.dateAdded = dateAdded
    }
}

// MARK: - Control Overlay View
struct ControlOverlayView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("backgroundImageData") private var backgroundImageData: Data?
    
    @State private var showSettingsSheet = false
    @State private var showChatSheet = false
    @State private var showBookSheet = false
    @State private var showFavoritesSheet = false
    
    @State private var showPhotoOptions = false
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var photoPickerItem: PhotosPickerItem?
    
    // For passing current scripture to favorite
    var currentScripture: (reference: String, text: String)?
    var onFavoriteToggled: (() -> Void)?
    
    // Built-in preset images
    private let presetImages = ["001 Sunset", "001 Mountains", "002 Mountains", "001 Forest", "001 Clouds"]
    
    var body: some View {
        VStack {
            HStack(spacing: 20) {
                // Favorite button
                Button {
                        showFavoritesSheet.toggle()
                } label: {
                    Image(systemName: isFavorited() ? "heart.fill" : "heart")
                        .font(.system(size: 22))
                        .foregroundColor(isFavorited() ? .red : .white)
                        .padding()
                        .glassEffect()
                }
                
                Spacer()
                
                Button {
                    showSettingsSheet.toggle()
                } label: {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                        .padding()
                        .glassEffect()
                }
            }
            .padding(.horizontal)
            .safeAreaPadding(.top)
            
            Spacer()
            
            // Bottom Bar
            HStack(spacing: 20) {
                Button {
                    showChatSheet.toggle()
                } label: {
                    Label("Chat", systemImage: "message.fill")
                        .foregroundColor(.white)
                        .padding()
                        .glassEffect()
                }
                
                Spacer()
                
                Button {
                    showBookSheet.toggle()
                } label: {
                    Image(systemName: "book.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                        .padding()
                        .glassEffect()
                }
                
                Button {
                    showPhotoOptions.toggle()
                } label: {
                    Image(systemName: "photo")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                        .padding()
                        .glassEffect()
                }
            }
            .padding(.horizontal)
            .safeAreaPadding(.bottom)
        }
        .containerRelativeFrame(.horizontal)
        
        // MARK: - Main Sheets
        .sheet(isPresented: $showSettingsSheet) {
            SettingsViewWithSubscription()
        }
        .sheet(isPresented: $showChatSheet) {
            ChatView()
        }
        .sheet(isPresented: $showBookSheet) {
            BibleFeedView(modelContext: modelContext)
        }
        .sheet(isPresented: $showFavoritesSheet) {
            FavoritesView()
        }
        
        // MARK: - Photo Sheets
        .sheet(isPresented: $showPhotoOptions) {
            PhotoOptionsSheet(
                showCamera: $showCamera,
                showPhotoPicker: $showPhotoPicker,
                presetImages: presetImages,
                onImageSelected: saveBackgroundImage
            )
        }
        .sheet(isPresented: $showCamera) {
            CameraView(onCapture: saveBackgroundImage)
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $photoPickerItem, matching: .images)
        .onChange(of: photoPickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    saveBackgroundImage(image)
                }
                photoPickerItem = nil
            }
        }
    }
    
    // MARK: - Favorite Logic
    private func isFavorited() -> Bool {
        guard let current = currentScripture else { return false }
        
        let reference = current.reference
        let descriptor = FetchDescriptor<FavoriteScripture>(
            predicate: #Predicate { $0.reference == reference }
        )
        
        let results = try? modelContext.fetch(descriptor)
        return !(results?.isEmpty ?? true)
    }
    
    private func toggleFavorite() {
        guard let current = currentScripture else { return }
        
        let reference = current.reference
        let descriptor = FetchDescriptor<FavoriteScripture>(
            predicate: #Predicate { $0.reference == reference }
        )
        
        if let existing = try? modelContext.fetch(descriptor).first {
            // Remove from favorites
            modelContext.delete(existing)
        } else {
            // Add to favorites
            let favorite = FavoriteScripture(
                reference: current.reference,
                text: current.text
            )
            modelContext.insert(favorite)
        }
        
        try? modelContext.save()
        onFavoriteToggled?()
    }
    
    // MARK: - Save Background Image
    private func saveBackgroundImage(_ image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.9) {
            backgroundImageData = data
        }
    }
}

// MARK: - Favorites View
struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \FavoriteScripture.dateAdded, order: .reverse) private var favorites: [FavoriteScripture]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if favorites.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No Favorites Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Tap the heart icon on scriptures you love to save them here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(favorites) { favorite in
                                FavoriteCard(favorite: favorite)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Favorite Card
struct FavoriteCard: View {
    @Environment(\.modelContext) private var modelContext
    let favorite: FavoriteScripture
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(favorite.reference)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.system(size: 16))
                }
            }
            
            Text(favorite.text)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(nil)
            
            Text(favorite.dateAdded, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .confirmationDialog("Delete Favorite", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteFavorite()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to remove this scripture from your favorites?")
        }
    }
    
    private func deleteFavorite() {
        modelContext.delete(favorite)
        try? modelContext.save()
    }
}

struct PhotoOptionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var showCamera: Bool
    @Binding var showPhotoPicker: Bool
    
    let presetImages: [String]
    let onImageSelected: (UIImage) -> Void
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button("Take a Photo") {
                        showCamera = true
                        dismiss()
                    }
                    Button("Choose from Library") {
                        showPhotoPicker = true
                        dismiss()
                    }
                }
                
                Section("Preset Images") {
                    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(presetImages, id: \.self) { name in
                            if let uiImage = UIImage(named: name) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .onTapGesture {
                                        onImageSelected(uiImage)
                                        dismiss()
                                    }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Choose Background")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    var onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView
        
        init(parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
