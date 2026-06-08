import Foundation

struct Profile: Codable {
    let id: String
    let username: String
    let totalScore: Int
    let wins: Int
    let battles: Int
    let currentStreak: Int
    let bestStreak: Int
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case totalScore = "total_score"
        case wins
        case battles
        case currentStreak = "current_streak"
        case bestStreak = "best_streak"
        case createdAt = "created_at"
    }
}
