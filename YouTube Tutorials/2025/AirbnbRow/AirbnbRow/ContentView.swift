import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading) {
            TabView {
                ForEach(exampleListing.images, id: \.self) { image in
                    Image(image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
            .tabViewStyle(.page)
            .frame(height: 320)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(alignment: .topTrailing) {
                Button {
                    //
                } label: {
                    Image(systemName: "heart")
                        .font(.title.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding()
                }
            }
            
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(exampleListing.location)
                        .font(.headline)
                    
                    Text("\(exampleListing.distanceInMiles) miles away")
                        .foregroundStyle(.secondary)
                    
                    Text(exampleListing.dateRange)
                        .foregroundStyle(.secondary)
                    
                    Text("\(priceText) for \(exampleListing.numberOfNights) nights")
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Label("\(exampleListing.rating.formatted(.number))", systemImage: "star.fill")
            }
        }
        .padding()
    }
    
    var priceText = Text(exampleListing.price, format: .currency(code: "USD"))
        .foregroundStyle(.primary)
        .underline()
}

#Preview(traits: .sizeThatFitsLayout) {
    ContentView()
}


struct RentalListing {
    let location: String
    let distanceInMiles: Int
    let dateRange: String
    let price: Double
    let rating: Double
    let numberOfNights: Int
    let images: [ImageResource]
}

let exampleListing = RentalListing(
    location: "Index, Washington",
    distanceInMiles: 72,
    dateRange: "Jun 26 - Jul 3",
    price: 4487.0,
    rating: 4.93,
    numberOfNights: 5,
    images: [.image1, .image2, .image3, .image4]
)
