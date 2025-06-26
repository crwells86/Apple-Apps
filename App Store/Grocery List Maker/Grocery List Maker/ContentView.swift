//import CoreData
//import CloudKit
//
//struct PersistenceController {
//    static let shared = PersistenceController()
//    
//    let container: NSPersistentCloudKitContainer
//    
//    init(inMemory: Bool = false) {
//        container = NSPersistentCloudKitContainer(name: "ShoppingDataModel")
//        container.viewContext.automaticallyMergesChangesFromParent = true
//
//        if let storeDescription = container.persistentStoreDescriptions.first {
//            storeDescription.cloudKitContainerOptions?.databaseScope = .private
//        }
//
//        if inMemory {
//            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
//        }
//        
//        let description = container.persistentStoreDescriptions.first!
//        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
//        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
//        
//        container.loadPersistentStores { (desc, error) in
//            if let error = error {
//                fatalError("🛑 Unresolved error \(error)")
//            }
//        }
//        
//        container.viewContext.automaticallyMergesChangesFromParent = true
//    }
//}
//
//
//import CoreData
//import CloudKit
//import UIKit
//
//func share(
//    _ object: NSManagedObject,
//    title: String? = nil,
//    completion: @escaping (UICloudSharingController?) -> Void
//) {
//    let container = PersistenceController.shared.container
//    let context = container.viewContext
//
//    // 1) Make sure the object has a permanent ID
//    if object.objectID.isTemporaryID {
//        do {
//            try context.obtainPermanentIDs(for: [object])
//            try context.save()
//        } catch {
//            print("Failed to save object before sharing: \(error)")
//            completion(nil)
//            return
//        }
//    }
//
//    // 2) Call the old API with a 4-arg closure
//    container.share(
//        [object],
//        to: nil,
//        completion: { savedObjectIDs, ckShare, ckContainer, error in
//            DispatchQueue.main.async {
//                if let error = error {
//                    print("🔴 Share failed: \(error.localizedDescription)")
//                    completion(nil)
//                    return
//                }
//                // Must unwrap both share record and container
//                guard let ckShare = ckShare, let ckContainer = ckContainer else {
//                    print("🔴 Share or container missing")
//                    completion(nil)
//                    return
//                }
//
//                // 3) Tweak the share record’s title
//                ckShare[CKShare.SystemFieldKey.title] = (title ?? "Shared Item") as CKRecordValue
//
//                // 4) Build and return the sharing controller
//                let controller = UICloudSharingController(share: ckShare, container: ckContainer)
//                controller.delegate = CloudSharingDelegate()
//                completion(controller)
//            }
//        }
//    )
//}
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//class CloudSharingDelegate: NSObject, UICloudSharingControllerDelegate {
//    func itemTitle(for csc: UICloudSharingController) -> String? {
//        "Shared Shopping List"
//    }
//
//    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
//        print("🔴 Failed to save share: \(error.localizedDescription)")
//    }
//
//    func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
//        print("✅ Share saved successfully.")
//    }
//
//    func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
//        print("ℹ️ Sharing stopped.")
//    }
//}
//
//
//
//
//
//import SwiftUI
//import UIKit
//
//extension Color {
//    init(hex: String) {
//        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
//        var int = UInt64(); Scanner(string: hex).scanHexInt64(&int)
//        let r = Double((int >> 16) & 0xFF)/255
//        let g = Double((int >> 8) & 0xFF)/255
//        let b = Double(int & 0xFF)/255
//        self.init(red: r, green: g, blue: b)
//    }
//    
//    func toHex() -> String {
//        let ui = UIColor(self)
//        var r: CGFloat=0, g: CGFloat=0, b: CGFloat=0, a: CGFloat=0
//        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
//        return String(format:"#%02X%02X%02X", Int(r*255), Int(g*255), Int(b*255))
//    }
//}
//
//import SwiftUI
//
//struct ContentView: View {
//    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \StoreCategory.name, ascending: true)])
//    private var stores: FetchedResults<StoreCategory>
//    
//    @State private var showNewStore = false
//    @State private var selectedStoreToEdit: StoreCategory?
//    
//    var body: some View {
//        NavigationStack {
//            DashboardView(stores: stores, showNewStore: $showNewStore, selectedStoreToEdit: $selectedStoreToEdit)
//                .navigationTitle("Stores")
//                .toolbar {
//                    ToolbarItem(placement: .bottomBar) {
//                        Button { showNewStore = true }
//                        label: { Label("New Store", systemImage: "plus.circle.fill") }
//                    }
//                }
//                .sheet(item: $selectedStoreToEdit) { store in
//                    NewStoreSheet(storeToEdit: store)
//                }
//                .sheet(isPresented: $showNewStore) {
//                    NewStoreSheet(storeToEdit: nil)
//                }
//        }
//    }
//}
//
//struct DashboardView: View {
//    let stores: FetchedResults<StoreCategory>
//    @Binding var showNewStore: Bool
//    @Binding var selectedStoreToEdit: StoreCategory?
//    
//    var body: some View {
//        ScrollView {
//            if stores.isEmpty {
//                ContentUnavailableView(label: {
//                    Label("No Stores", systemImage: "basket")
//                }, description: {
//                    Text("Tap the plus button below to add your first store.")
//                })
//                .padding()
//            } else {
//                LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 16) {
//                    ForEach(stores) { store in
//                        NavigationLink(destination: StoreDetailView(store: store)) {
//                            VStack(alignment: .leading) {
//                                Image(systemName: store.icon ?? "")
//                                    .font(.title)
//                                    .foregroundColor(Color(hex: store.colorHex ?? "#FFFFFF"))
//                                    .frame(maxWidth: .infinity, alignment: .leading)
//                                
//                                Text(store.name ?? "")
//                                    .font(.caption).foregroundColor(.gray)
//                                
//                                let count = (store.lists as? Set<ShoppingList>)?.reduce(0) { $0 + ($1.items?.count ?? 0) } ?? 0
//                                Text("\(count)").font(.headline)
//                            }
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(Color(.systemGray6)).cornerRadius(12)
//                            .contextMenu {
//                                Button("Edit") {
//                                    selectedStoreToEdit = store
//                                }
//                                Button("Delete", role: .destructive) {
//                                    let ctx = PersistenceController.shared.container.viewContext
//                                    ctx.delete(store)
//                                    try? ctx.save()
//                                }
//                            }
//                        }
//                    }
//                }
//                .padding()
//            }
//        }
//    }
//}
//
//struct StoreDetailView: View {
//    @ObservedObject var store: StoreCategory
//    @State private var showNewList = false
//    
//    private var sortedLists: [ShoppingList] {
//        (store.lists as? Set<ShoppingList> ?? []).sorted { $0.name ?? "" < $1.name ?? "" }
//    }
//    
//    var body: some View {
//        List {
//            ForEach(sortedLists, id: \.self) { list in
//                NavigationLink(destination: ShoppingListView(list: list)) {
//                    VStack(alignment: .leading) {
//                        Text(list.name ?? "").font(.headline)
//                        Text("\(list.items?.count ?? 0) items")
//                            .font(.caption).foregroundColor(.gray)
//                    }
//                }
//            }
//            .onDelete { indexSet in
//                let context = PersistenceController.shared.container.viewContext
//                indexSet.map { sortedLists[$0] }.forEach(context.delete)
//                try? context.save()
//            }
//        }
//        .navigationTitle(store.name ?? "")
//        .toolbar {
//            ToolbarItem {
//                Button { showNewList = true } label: {
//                    Label("New List", systemImage: "plus.circle")
//                }
//            }
//        }
//        .sheet(isPresented: $showNewList) {
//            NewListSheet(store: store)
//        }
//    }
//}
//
//struct ShoppingListView: View {
//    @ObservedObject var list: ShoppingList
//    @State private var newItem = ""
//    
//    private var sortedItems: [ShoppingItem] {
//        (list.items as? Set<ShoppingItem> ?? []).sorted { $0.id!.uuidString < $1.id!.uuidString }
//    }
//    
//    var body: some View {
//        VStack {
//            List {
//                ForEach(sortedItems, id: \.self) { item in
//                    ItemRowView(item: item, storeColorHex: list.store?.colorHex ?? "#00FF00")
//                }
//                .onDelete { indexSet in
//                    let context = PersistenceController.shared.container.viewContext
//                    indexSet.map { sortedItems[$0] }.forEach(context.delete)
//                    try? context.save()
//                }
//            }
//            
//            Divider()
//                .padding()
//            
//            HStack {
//                Image(systemName: "plus.circle.fill").foregroundColor(.green)
//                TextField("New Item", text: $newItem, onCommit: addItem)
//                    .submitLabel(.done)
//            }
//            .font(.headline).padding()
//        }
//        .navigationTitle(list.name ?? "")
//    }
//    
//    private func addItem() {
//        let trimmed = newItem.trimmingCharacters(in: .whitespacesAndNewlines)
//        guard !trimmed.isEmpty else { return }
//        let viewContext = PersistenceController.shared.container.viewContext
//        let item = ShoppingItem(context: viewContext)
//        item.id = UUID()
//        item.name = trimmed
//        item.isChecked = false
//        item.list = list
//        try? viewContext.save()
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.27) {
//            newItem = ""
//        }
//    }
//}
//
//struct ItemRowView: View {
//    @ObservedObject var item: ShoppingItem
//    var storeColorHex: String
//    
//    var body: some View {
//        HStack {
//            Circle()
//                .strokeBorder(.gray)
//                .background(Circle().fill(item.isChecked ? Color(hex: storeColorHex) : .clear))
//                .frame(width: 24, height: 24)
//                .onTapGesture {
//                    let ctx = PersistenceController.shared.container.viewContext
//                    item.isChecked.toggle()
//                    try? ctx.save()
//                }
//            Text(item.name ?? "").fontWeight(.medium)
//            Spacer()
//        }
//        .padding(.vertical, 4)
//    }
//}
//
//struct NewStoreSheet: View {
//    @Environment(\.dismiss) var dismiss
//    var storeToEdit: StoreCategory?
//    
//    @State private var name = ""
//    @State private var icon = "cart"
//    @State private var color: Color = .blue
//    
//    let storeIcons: [String] = [
//        "cart", "cart.fill", "basket", "basket.fill", "bag", "bag.fill",
//        "bag.circle", "bag.circle.fill", "cart.circle", "cart.circle.fill",
//        "house", "house.fill", "tshirt", "tshirt.fill", "hanger", "gift", "gift.fill"
//    ]
//    
//    var body: some View {
//        NavigationView {
//            Form {
//                TextField("Store Name", text: $name)
//                Picker("Icon", selection: $icon) {
//                    ForEach(storeIcons, id: \.self) { iconName in
//                        Image(systemName: iconName).tag(iconName)
//                    }
//                }
//                ColorPicker("Store Color", selection: $color)
//            }
//            .navigationTitle(storeToEdit == nil ? "New Store" : "Edit Store")
//            .toolbar {
//                ToolbarItem(placement: .confirmationAction) {
//                    Button(storeToEdit == nil ? "Add" : "Save") {
//                        let ctx = PersistenceController.shared.container.viewContext
//                        let store = storeToEdit ?? StoreCategory(context: ctx)
//                        if storeToEdit == nil {
//                            store.id = UUID()
//                        }
//                        store.name = name
//                        store.icon = icon
//                        store.colorHex = color.toHex()
//                        try? ctx.save()
//                        dismiss()
//                    }
//                    .disabled(name.isEmpty)
//                }
//                
//                ToolbarItem(placement: .cancellationAction) {
//                    Button("Cancel") { dismiss() }
//                }
//            }
//        }
//        .onAppear {
//            if let store = storeToEdit {
//                name = store.name ?? ""
//                icon = store.icon ?? "cart"
//                color = Color(hex: store.colorHex ?? "#0000FF")
//            }
//        }
//    }
//}
//
//
//struct NewListSheet: View {
//    @Environment(\.dismiss) var dismiss
//    @ObservedObject var store: StoreCategory
//    @State private var name = ""
//    
//    var body: some View {
//        NavigationView {
//            Form { TextField("List Name", text: $name) }
//                .navigationTitle("New List")
//                .toolbar {
//                    ToolbarItem {
//                        Button("Add") {
//                            let ctx = PersistenceController.shared.container.viewContext
//                            let l = ShoppingList(context: ctx)
//                            l.id = UUID(); l.name = name; l.store = store
//                            try? ctx.save()
//                            dismiss()
//                        }.disabled(name.isEmpty)
//                    }
//                    ToolbarItem {
//                        Button("Cancel") { dismiss() }
//                    }
//                }
//        }
//    }
//}





import SwiftUI
import CoreData
import CloudKit
import UIKit

// MARK: - Persistence

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentCloudKitContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "ShoppingDataModel")
        container.viewContext.automaticallyMergesChangesFromParent = true

//        if let storeDescription = container.persistentStoreDescriptions.first {
//            storeDescription.cloudKitContainerOptions?.databaseScope = .private
//        }
        let storeDescription = container.persistentStoreDescriptions.first!

        // 1) Create the cloud-kit options with your container identifier:
        let options = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.calebrwells.grocerylist")

        // 2) Tell it to use the private database:
        options.databaseScope = .private

        // 3) Attach them to the description *before* loading the store:
        storeDescription.cloudKitContainerOptions = options

        // (then your history-tracking, merge options, etc.)
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)


        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        let description = container.persistentStoreDescriptions.first!
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { (desc, error) in
            if let error = error {
                fatalError("🛑 Unresolved error \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

// MARK: - Share Helpers

extension StoreCategory {
    /// Returns [StoreCategory, all its lists, and all items in those lists]
    func shareableObjects() -> [NSManagedObject] {
        let lists = (self.lists as? Set<ShoppingList>) ?? []
        let items = lists.flatMap { list in
            (list.items as? Set<ShoppingItem>) ?? []
        }
        return [self] + lists.map { $0 } + items.map { $0 }
    }
}

extension ShoppingList {
    /// Returns [ShoppingList, all its items]
    func shareableObjects() -> [NSManagedObject] {
        let items = (self.items as? Set<ShoppingItem>) ?? []
        return [self] + items.map { $0 }
    }
}

func ensurePermanentIDs(_ objects: [NSManagedObject], in context: NSManagedObjectContext) throws {
    let temp = objects.filter(\.objectID.isTemporaryID)
    if !temp.isEmpty {
        try context.obtainPermanentIDs(for: temp)
        try context.save()
    }
}

func shareStore(
    _ store: StoreCategory,
    title: String? = nil,
    completion: @escaping (UICloudSharingController?) -> Void
) {
    let container = PersistenceController.shared.container
    let ctx = container.viewContext

    let objects = store.shareableObjects()
    do {
        try ensurePermanentIDs(objects, in: ctx)
    } catch {
        print("🔴 Failed to get permanent IDs: \(error)")
        completion(nil); return
    }

    container.share(objects, to: nil) { _, ckShare, ckContainer, error in
        DispatchQueue.main.async {
            if let error = error {
                print("🔴 Share failed: \(error)")
                completion(nil); return
            }
            guard let ckShare = ckShare, let ckContainer = ckContainer else {
                print("🔴 Missing share or container")
                completion(nil); return
            }

            ckShare[CKShare.SystemFieldKey.title] = (title ?? store.name ?? "Shared Store") as CKRecordValue
            let csc = UICloudSharingController(share: ckShare, container: ckContainer)
            csc.delegate = CloudSharingDelegate()
            completion(csc)
        }
    }
}

func shareList(
    _ list: ShoppingList,
    title: String? = nil,
    completion: @escaping (UICloudSharingController?) -> Void
) {
    let container = PersistenceController.shared.container
    let ctx = container.viewContext

    let objects = list.shareableObjects()
    do {
        try ensurePermanentIDs(objects, in: ctx)
    } catch {
        print("🔴 Failed to get permanent IDs: \(error)")
        completion(nil); return
    }

    container.share(objects, to: nil) { _, ckShare, ckContainer, error in
        DispatchQueue.main.async {
            if let error = error {
                print("🔴 Share failed: \(error)")
                completion(nil); return
            }
            guard let ckShare = ckShare, let ckContainer = ckContainer else {
                print("🔴 Missing share or container")
                completion(nil); return
            }

            ckShare[CKShare.SystemFieldKey.title] = (title ?? list.name ?? "Shared List") as CKRecordValue
            let csc = UICloudSharingController(share: ckShare, container: ckContainer)
            csc.delegate = CloudSharingDelegate()
            completion(csc)
        }
    }
}

// MARK: - CloudSharingDelegate

class CloudSharingDelegate: NSObject, UICloudSharingControllerDelegate {
    func itemTitle(for csc: UICloudSharingController) -> String? {
        "Shared Shopping Data"
    }

    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        print("🔴 Failed to save share: \(error.localizedDescription)")
    }

    func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
        print("✅ Share saved successfully.")
    }

    func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
        print("ℹ️ Sharing stopped.")
    }
}

// MARK: - SwiftUI Wrapper

struct CloudSharingControllerWrapper: UIViewControllerRepresentable {
    let controller: UICloudSharingController

    func makeUIViewController(context: Context) -> UICloudSharingController {
        controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int = UInt64(); Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF)/255
        let g = Double((int >> 8) & 0xFF)/255
        let b = Double(int & 0xFF)/255
        self.init(red: r, green: g, blue: b)
    }
    
    func toHex() -> String {
        let ui = UIColor(self)
        var r: CGFloat=0, g: CGFloat=0, b: CGFloat=0, a: CGFloat=0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format:"#%02X%02X%02X", Int(r*255), Int(g*255), Int(b*255))
    }
}

// MARK: - Views

struct ContentView: View {
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \StoreCategory.name, ascending: true)])
    private var stores: FetchedResults<StoreCategory>
    
    @State private var showNewStore = false
    @State private var selectedStoreToEdit: StoreCategory?
    @State private var sharingController: UICloudSharingController?
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationStack {
            DashboardView(stores: stores,
                          showNewStore: $showNewStore,
                          selectedStoreToEdit: $selectedStoreToEdit,
                          onShareStore: { store in
                shareStore(store) { csc in
                    if let csc = csc {
                        sharingController = csc
                        showShareSheet = true
                    }
                }
            })
            .navigationTitle("Stores")
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button { showNewStore = true }
                    label: { Label("New Store", systemImage: "plus.circle.fill") }
                }
            }
            .sheet(item: $selectedStoreToEdit) { store in
                NewStoreSheet(storeToEdit: store)
            }
            .sheet(isPresented: $showNewStore) {
                NewStoreSheet(storeToEdit: nil)
            }
            .sheet(isPresented: $showShareSheet) {
                if let csc = sharingController {
                    CloudSharingControllerWrapper(controller: csc)
                }
            }
        }
    }
}

struct DashboardView: View {
    let stores: FetchedResults<StoreCategory>
    @Binding var showNewStore: Bool
    @Binding var selectedStoreToEdit: StoreCategory?
    let onShareStore: (StoreCategory) -> Void
    
    var body: some View {
        ScrollView {
            if stores.isEmpty {
                ContentUnavailableView(label: {
                    Label("No Stores", systemImage: "basket")
                }, description: {
                    Text("Tap the plus button below to add your first store.")
                })
                .padding()
            } else {
                LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 16) {
                    ForEach(stores) { store in
                        NavigationLink(destination: StoreDetailView(store: store, onShareList: { _ in })) {
                            VStack(alignment: .leading) {
                                Image(systemName: store.icon ?? "")
                                    .font(.title)
                                    .foregroundColor(Color(hex: store.colorHex ?? "#FFFFFF"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text(store.name ?? "")
                                    .font(.caption).foregroundColor(.gray)
                                
                                let count = (store.lists as? Set<ShoppingList>)?.reduce(0) { $0 + ($1.items?.count ?? 0) } ?? 0
                                Text("\(count)").font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6)).cornerRadius(12)
                            .contextMenu {
                                Button("Share") { onShareStore(store) }
                                Button("Edit") { selectedStoreToEdit = store }
                                Button("Delete", role: .destructive) {
                                    let ctx = PersistenceController.shared.container.viewContext
                                    ctx.delete(store)
                                    try? ctx.save()
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
}

struct StoreDetailView: View {
    @ObservedObject var store: StoreCategory
    @State private var showNewList = false
    @State private var selectedListToEdit: ShoppingList?
    @State private var sharingController: UICloudSharingController?
    @State private var showShareSheet = false
    let onShareList: (ShoppingList) -> Void

    private var sortedLists: [ShoppingList] {
        (store.lists as? Set<ShoppingList> ?? []).sorted { $0.name ?? "" < $1.name ?? "" }
    }
    
    var body: some View {
        List {
            ForEach(sortedLists, id: \.self) { list in
                NavigationLink(destination: ShoppingListView(list: list)) {
                    VStack(alignment: .leading) {
                        Text(list.name ?? "").font(.headline)
                        Text("\(list.items?.count ?? 0) items")
                            .font(.caption).foregroundColor(.gray)
                    }
                }
                .contextMenu {
                    Button("Share") {
                        shareList(list) { csc in
                            if let csc = csc {
                                sharingController = csc
                                showShareSheet = true
                            }
                        }
                    }
                }
            }
            .onDelete { indexSet in
                let context = PersistenceController.shared.container.viewContext
                indexSet.map { sortedLists[$0] }.forEach(context.delete)
                try? context.save()
            }
        }
        .navigationTitle(store.name ?? "")
        .toolbar {
            ToolbarItem {
                Button { showNewList = true } label: {
                    Label("New List", systemImage: "plus.circle")
                }
            }
        }
        .sheet(isPresented: $showNewList) {
            NewListSheet(store: store)
        }
        .sheet(isPresented: $showShareSheet) {
            if let csc = sharingController {
                CloudSharingControllerWrapper(controller: csc)
            }
        }
    }
}

struct ShoppingListView: View {
    @ObservedObject var list: ShoppingList
    @State private var newItem = ""
    
    private var sortedItems: [ShoppingItem] {
        (list.items as? Set<ShoppingItem> ?? []).sorted { $0.id!.uuidString < $1.id!.uuidString }
    }
    
    var body: some View {
        VStack {
            List {
                ForEach(sortedItems, id: \.self) { item in
                    ItemRowView(item: item, storeColorHex: list.store?.colorHex ?? "#00FF00")
                }
                .onDelete { indexSet in
                    let context = PersistenceController.shared.container.viewContext
                    indexSet.map { sortedItems[$0] }.forEach(context.delete)
                    try? context.save()
                }
            }
            
            Divider().padding()
            
            HStack {
                Image(systemName: "plus.circle.fill").foregroundColor(.green)
                TextField("New Item", text: $newItem, onCommit: addItem)
                    .submitLabel(.done)
            }
            .font(.headline).padding()
        }
        .navigationTitle(list.name ?? "")
    }
    
    private func addItem() {
        let trimmed = newItem.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let viewContext = PersistenceController.shared.container.viewContext
        let item = ShoppingItem(context: viewContext)
        item.id = UUID()
        item.name = trimmed
        item.isChecked = false
        item.list = list
        try? viewContext.save()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.27) {
            newItem = ""
        }
    }
}

struct ItemRowView: View {
    @ObservedObject var item: ShoppingItem
    var storeColorHex: String
    
    var body: some View {
        HStack {
            Circle()
                .strokeBorder(.gray)
                .background(Circle().fill(item.isChecked ? Color(hex: storeColorHex) : .clear))
                .frame(width: 24, height: 24)
                .onTapGesture {
                    let ctx = PersistenceController.shared.container.viewContext
                    item.isChecked.toggle()
                    try? ctx.save()
                }
            Text(item.name ?? "").fontWeight(.medium)
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct NewStoreSheet: View {
    @Environment(\.dismiss) var dismiss
    var storeToEdit: StoreCategory?
    
    @State private var name = ""
    @State private var icon = "cart"
    @State private var color: Color = .blue
    
    let storeIcons: [String] = [
        "cart", "cart.fill", "basket", "basket.fill", "bag", "bag.fill",
        "bag.circle", "bag.circle.fill", "cart.circle", "cart.circle.fill",
        "house", "house.fill", "tshirt", "tshirt.fill", "hanger", "gift", "gift.fill"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Store Name", text: $name)
                Picker("Icon", selection: $icon) {
                    ForEach(storeIcons, id: \.self) { iconName in
                        Image(systemName: iconName).tag(iconName)
                    }
                }
                ColorPicker("Store Color", selection: $color)
            }
            .navigationTitle(storeToEdit == nil ? "New Store" : "Edit Store")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(storeToEdit == nil ? "Add" : "Save") {
                        let ctx = PersistenceController.shared.container.viewContext
                        let store = storeToEdit ?? StoreCategory(context: ctx)
                        if storeToEdit == nil {
                            store.id = UUID()
                        }
                        store.name = name
                        store.icon = icon
                        store.colorHex = color.toHex()
                        try? ctx.save()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            if let store = storeToEdit {
                name = store.name ?? ""
                icon = store.icon ?? "cart"
                color = Color(hex: store.colorHex ?? "#0000FF")
            }
        }
    }
}

struct NewListSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var store: StoreCategory
    @State private var name = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("List Name", text: $name)
            }
            .navigationTitle("New List")
            .toolbar {
                ToolbarItem {
                    Button("Add") {
                        let ctx = PersistenceController.shared.container.viewContext
                        let l = ShoppingList(context: ctx)
                        l.id = UUID()
                        l.name = name
                        l.store = store
                        try? ctx.save()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
                ToolbarItem {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
