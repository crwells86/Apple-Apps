import SwiftUI

struct UpNextNavigationLink: View {
    var body: some View {
        NavigationLink {
            Text("Coming soon...")
        } label: {
            UpNextLabelView()
        }
    }
}
