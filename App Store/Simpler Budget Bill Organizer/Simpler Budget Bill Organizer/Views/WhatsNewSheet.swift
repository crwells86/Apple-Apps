import SwiftUI

struct WhatsNewSheet: ViewModifier {
    @AppStorage("lastSeenVersion") private var lastSeenVersion: String = ""
    @State private var isPresented: Bool = false
    
    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if lastSeenVersion != currentVersion {
                    isPresented = true
                }
            }
            .sheet(isPresented: $isPresented, onDismiss: {
                lastSeenVersion = currentVersion
            }) {
                WhatsNewView(version: currentVersion)
            }
    }
}

extension View {
    func whatsNewSheet() -> some View {
        self.modifier(WhatsNewSheet())
    }
}

struct WhatsNewItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
}

struct WhatsNewView: View {
    let version: String
    
    private let features: [WhatsNewItem] = [
        .init(icon: "bell.badge.fill",
              title: "Category Limits",
              subtitle: "Set spending caps and get notified when you go over."),
        .init(icon: "slider.horizontal.3",
              title: "Custom Categories",
              subtitle: "Create your own categories to track expenses your way.")
//        .init(icon: "checklist",
//              title: "Bulk Assign Categories",
//              subtitle: "Swiftly select and categorize multiple expenses or bills at once.")
    ]
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Text("What's New in \nversion \(version)")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.vertical)
            
            VStack(alignment: .leading, spacing: 20) {
                ForEach(features) { item in
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: item.icon)
                            .foregroundColor(.accentColor)
                            .font(.title3)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.headline)
                            Text(item.subtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.horizontal)
            }
            
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
    }
}

#Preview {
    WhatsNewView(version: "0.2")
}
