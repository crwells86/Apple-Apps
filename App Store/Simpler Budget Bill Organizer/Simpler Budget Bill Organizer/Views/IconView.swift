import SwiftUI

struct IconView: View {
    let icon: String
    
    var body: some View {
        if UIImage(systemName: icon) != nil {
            Image(systemName: icon)
                .foregroundStyle(.accent)
        } else {
            Text(icon)
                .font(.title3)
        }
    }
}
