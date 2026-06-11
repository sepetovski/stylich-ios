import Foundation

struct Battle: Identifiable, Codable {
    let id: String
    let status: String
    let p1User: String
    let p1Image: String
    let p1Score: Int?
    let p1Feedback: String?
    let p2User: String?
    let p2Image: String?
    let p2Score: Int?
    let p2Feedback: String?
    let winner: String?
    let category: String?
    let judgedAt: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case status
        case p1User = "p1_user"
        case p1Image = "p1_image"
        case p1Score = "p1_score"
        case p1Feedback = "p1_feedback"
        case p2User = "p2_user"
        case p2Image = "p2_image"
        case p2Score = "p2_score"
        case p2Feedback = "p2_feedback"
        case winner
        case category
        case judgedAt = "judged_at"
        case createdAt = "created_at"
    }
}
