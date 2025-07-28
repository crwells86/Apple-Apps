import SwiftUI
import SwiftData

enum CategoryViewMode: String, CaseIterable {
    case select = "Select"
    case manage = "Manage"
}

struct AddCategorySheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var selectedIcon: String = ""
    @State private var categoryMode: CategoryViewMode = .select
    @Query(sort: \Category.name) private var categories: [Category]
    @State private var showingEmojiPicker = false
    
    @State private var limit: Decimal?
    @State private var enableReminders: Bool = false
    @FocusState var isInputActive: Bool
    
    var onAdd: (Category) -> Void
    
    private let iconOptions: [String] = [
        "house", "car", "bus", "airplane", "tram", "bicycle", "fuelpump", "ev.charger", "bag", "cart", "creditcard", "wallet.pass", "gift", "heart", "star", "person", "person.3", "figure.walk", "figure.run", "figure.stand", "figure.wave", "globe", "location", "map", "mappin", "flag", "calendar", "alarm", "envelope", "phone", "message", "camera", "video", "mic", "music.note", "headphones", "tv", "display", "laptopcomputer", "ipad", "iphone", "applewatch", "gamecontroller", "keyboard", "printer", "externaldrive", "folder", "doc.text", "doc.richtext", "book", "books.vertical", "newspaper", "highlighter", "scissors", "paintbrush", "hammer", "wrench", "screwdriver", "shippingbox", "building.2", "banknote", "dollarsign", "bitcoinsign.circle", "sterlingsign.circle", "eurosign.circle", "yensign.circle", "indianrupeesign.circle", "flame", "leaf", "moon", "cloud.sun", "cloud.rain", "bolt", "thermometer", "eyeglasses", "cross.case", "bandage", "pills", "cross", "lungs", "heart.text.square", "tree"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Picker("Mode", selection: $categoryMode) {
                    ForEach(CategoryViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                
                switch categoryMode {
                case .select:
                    addCategoryForm
                case .manage:
                    manageCategoriesList
                }
            }
            .padding(.top)
            .navigationTitle(categoryMode == .select ? "New Category" : "Manage Categories")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }
                if categoryMode == .select {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add", action: addCategory)
                            .disabled(name.isEmpty || selectedIcon.isEmpty)
                    }
                }
            }
        }
    }
    
    // MARK: - Add Mode View
    
    private var addCategoryForm: some View {
        Group {
            Section {
                TextField("Category Name", text: $name)
            }
            
            Section("Budget Limit") {
                TextField("Enter Limit", value: $limit, format: .number)
                    .keyboardType(.decimalPad)
                    .focused($isInputActive)
                    .toolbar {
                        ToolbarItem(placement: .keyboard) {
                            HStack {
                                Spacer()
                                
                                Button("Done") {
                                    isInputActive = false
                                }
                            }
                            .padding(.trailing)
                        }
                    }
                
                Toggle("Enable Reminders", isOn: $enableReminders)
            }
            
            Section("Icon") {
                HStack {
                    Text("Emoji Icon")
                    Spacer()
                    Button {
                        showingEmojiPicker = true
                    } label: {
                        if selectedIcon.isEmpty {
                            Text("Pick")
                                .foregroundStyle(.blue)
                        } else {
                            Text(selectedIcon)
                                .font(.title2)
                        }
                    }
                }
                .sheet(isPresented: $showingEmojiPicker) {
                    EmojiPickerView(selectedEmoji: $selectedIcon)
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6)) {
                    ForEach(iconOptions, id: \.self) { icon in
                        IconButton(icon: icon, isSelected: icon == selectedIcon) {
                            selectedIcon = icon
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Manage Mode View
    private func filterToSingleEmoji(_ input: String) -> String {
        let scalars = input.unicodeScalars
        if input.count <= 2, scalars.allSatisfy({ $0.properties.isEmoji }) {
            return input
        } else {
            return String(input.prefix(1).filter { $0.isEmoji })
        }
    }
    
    private var manageCategoriesList: some View {
        List {
            ForEach(categories) { category in
                HStack {
                    IconView(icon: category.icon)
                    VStack(alignment: .leading) {
                        Text(category.name)
                        if let limit = category.limit {
                            Text("Limit: \(limit.formatted(.currency(code: "USD")))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
            }
            .onDelete(perform: deleteCategory)
        }
    }
    
    // MARK: - Helpers
    private func addCategory() {
        let newCategory = Category(name: name, icon: selectedIcon, limit: limit)
        newCategory.isDefault = false
        newCategory.enableReminders = enableReminders
        modelContext.insert(newCategory)
        onAdd(newCategory)
    }
    
    private func deleteCategory(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(categories[index])
        }
    }
}

import UserNotifications

struct IconButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                }
                
                Group {
                    if icon.allSatisfy({ $0.isEmoji }) {
                        Text(icon)
                            .font(.title)
                    } else {
                        Image(systemName: icon)
                            .font(.title2)
                    }
                }
            }
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
    }
}


struct EmojiPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedEmoji: String
    
    private let allEmojis: [String] = {
        let ranges: [ClosedRange<Int>] = [
            0x1F680...0x1F6FF, // 🚀 Transport & map symbols (planes, cars, trains, traffic lights, etc.)
            0x1F3E0...0x1F3FF, // 🏠 Buildings & places (houses, hotels, schools, etc.)
            0x1F6D0...0x1F6D2, // 🛒 Cart, etc. (shopping)
            0x1F955...0x1F96C, // 🥕 Food & vegetables subset (carrot, broccoli, etc.)
            0x1F300...0x1F5FF, // 🌀 Miscellaneous symbols & pictographs (weather, tools, animals, etc.)
            0x2600...0x26FF,   // ☀️ Miscellaneous symbols (weather, zodiac, tools, etc.)
            0x2700...0x27BF    // ✂️ Dingbats (arrows, symbols, etc.)
        ]
        
        return ranges.flatMap { range in
            range.compactMap {
                guard let scalar = UnicodeScalar($0), scalar.properties.isEmoji else { return nil }
                return String(scalar)
            }
        }
    }()
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 6)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(allEmojis, id: \.self) { emoji in
                        Button {
                            selectedEmoji = emoji
                            dismiss()
                        } label: {
                            Text(emoji)
                                .font(.largeTitle)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Pick an Emoji")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
