import SwiftUI

struct HomeScrollView: View {
    var body: some View {
        ScrollView {
            UpNextNavigationLink()
            PodcastListView()
        }
    }
}
