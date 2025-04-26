import SwiftUI

struct UpNextLabelView: View {
    var body: some View {
        HStack(spacing: 2) {
            Text("Up Next")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color(.label))
            
            Image(systemName: "chevron.right")
                .font(.body)
                .fontWeight(.black)
                .foregroundStyle(Color(.secondaryLabel))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading)
    }
}
