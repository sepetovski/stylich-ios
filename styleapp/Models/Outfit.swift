import Foundation

struct FeedItem: Identifiable, Codable {
    let id: String
    let battleId: String
    let userId: String
    let image: String
    let score: Int
    let feedback: String
    let username: String
}
