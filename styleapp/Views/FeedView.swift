import SwiftUI

struct FeedView: View {
    @StateObject private var feedService = FeedService()
    @State private var selectedOutfit: FeedItem? = nil
    @State private var selectedFrame: CGRect = .zero

    var body: some View {
        NavigationView {
            ZStack {
                Color("Background")
                    .ignoresSafeArea()

                if feedService.isLoading && feedService.items.isEmpty {
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
                            ForEach(feedService.items) { item in
                                OutfitCard(outfit: item)
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                            selectedOutfit = item
                                        }
                                    }
                                    .onAppear {
                                        if item.id == feedService.items.last?.id {
                                            Task { await feedService.fetchMore() }
                                        }
                                    }
                            }

                            if feedService.isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .gridCellColumns(2)
                            }
                        }
                        .padding(12)
                    }
                }

                // Detail overlay
                if let outfit = selectedOutfit {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                selectedOutfit = nil
                            }
                        }

                    OutfitDetailCard(outfit: outfit)
                        .padding(24)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.85).combined(with: .opacity),
                            removal: .scale(scale: 0.85).combined(with: .opacity)
                        ))
                        .zIndex(1)
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
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: URL(string: outfit.image)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: 240)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: geo.size.width, height: 240)
                        .overlay(ProgressView())
                }
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
        .frame(height: 240)
    }
}

struct OutfitDetailCard: View {
    let outfit: FeedItem


    func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return .green
        case 60...79: return Color("AccentColor")
        case 40...59: return .orange
        default: return .red
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Photo
            AsyncImage(url: URL(string: outfit.image)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(ProgressView())
            }
            .frame(maxWidth: .infinity)
            .frame(height: 300)
            .clipped()

            // Info
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(outfit.score)")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(scoreColor(outfit.score))
                        Text("StyleMogg score")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 5)
                        Circle()
                            .trim(from: 0, to: CGFloat(outfit.score) / 100)
                            .stroke(scoreColor(outfit.score), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: 52, height: 52)
                }

                Divider()

                Text(outfit.feedback.isEmpty ? "No feedback available" : outfit.feedback)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineSpacing(4)
            }
            .padding(16)
            .background(Color("Background"))
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}

#Preview {
    FeedView()
}
