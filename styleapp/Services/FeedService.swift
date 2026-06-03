import Foundation
import Combine
import Supabase

class FeedService: ObservableObject {
    @Published var items: [FeedItem] = []
    @Published var isLoading = false
    @Published var errorMessage = ""

    func fetchFeed() async {
        await MainActor.run { self.isLoading = true }

        do {
            let p1: [[String: AnyJSON]] = try await supabase
                .from("battles")
                .select("id, p1_user, p1_image, p1_score, p1_feedback")
                .in("status", values: ["voting", "judged"])
                .not("p1_score", operator: .is, value: AnyJSON.null)
                .order("judged_at", ascending: false)
                .limit(20)
                .execute()
                .value

            let p2: [[String: AnyJSON]] = try await supabase
                .from("battles")
                .select("id, p2_user, p2_image, p2_score, p2_feedback")
                .in("status", values: ["voting", "judged"])
                .not("p2_score", operator: .is, value: AnyJSON.null)
                .order("judged_at", ascending: false)
                .limit(20)
                .execute()
                .value

            var results: [FeedItem] = []

            for b in p1 {
                if let id = b["id"]?.stringValue,
                   let user = b["p1_user"]?.stringValue,
                   let image = b["p1_image"]?.stringValue,
                   let score = b["p1_score"]?.intValue {
                    results.append(FeedItem(
                        id: "\(id)-p1",
                        battleId: id,
                        userId: user,
                        image: image,
                        score: score,
                        feedback: b["p1_feedback"]?.stringValue ?? "",
                        username: "anon"
                    ))
                }
            }

            for b in p2 {
                if let id = b["id"]?.stringValue,
                   let user = b["p2_user"]?.stringValue,
                   let image = b["p2_image"]?.stringValue,
                   let score = b["p2_score"]?.intValue {
                    results.append(FeedItem(
                        id: "\(id)-p2",
                        battleId: id,
                        userId: user,
                        image: image,
                        score: score,
                        feedback: b["p2_feedback"]?.stringValue ?? "",
                        username: "anon"
                    ))
                }
            }

            results.sort { $0.score > $1.score }

            await MainActor.run {
                self.items = results
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}
