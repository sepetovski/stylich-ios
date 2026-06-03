import SwiftUI

struct FeedView: View {
    @StateObject private var feedService = FeedService()

    var body: some View {
        NavigationView {
            ZStack {
                Color("Background")
                    .ignoresSafeArea()

                if feedService.isLoading {
                    ProgressView()
                } else if feedService.items.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tshirt")
                            .font(.system(size: 48))
                            .foregroundColor(Color("AccentColor"))
                        Text("No outfits yet")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Be the first to drop a fit")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(feedService.items) { outfit in
                                OutfitCard(outfit: outfit)
                            }
                        }
                        .padding(12)
                    }
                }
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await feedService.fetchFeed()
            }
        }
    }
}

struct OutfitCard: View {
    let outfit: FeedItem

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: URL(string: outfit.image)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(ProgressView())
            }
            .frame(height: 220)
            .clipped()
            .cornerRadius(16)

            Text("\(outfit.score)")
                .font(.system(size: 13, weight: .bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color("AccentColor"))
                .foregroundColor(.black)
                .cornerRadius(8)
                .padding(8)
        }
    }
}
#Preview {
    FeedView()
}
