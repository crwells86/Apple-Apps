import SwiftUI

import SwiftUI

struct TitleScreenView: View {
    let word = ["W","O","R","D"]
    let quest = ["Q","U","E","S","T"]
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                ForEach(word.indices, id: \.self) { index in
                    let word = word[index]
                    Text(word)
                        .font(.title)
                        .fontWeight(.semibold)
                        .padding()
                        .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            .padding(.horizontal)
            
            HStack(spacing: 4) {
                ForEach(quest.indices, id: \.self) { index in
                    let word = quest[index]
                    Text(word)
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .padding()
                        .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                
                VStack(spacing: 4) {
                    Text("D")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                        .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    
                    Text("X")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                        .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            .padding(.horizontal)
        }
    }
}


#Preview {
    TitleScreenView()
}
