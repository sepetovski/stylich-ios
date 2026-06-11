import Foundation
import Combine
import Supabase

class BattlesHistoryService: ObservableObject {
    @Published var battles: [Battle] = []
    @Published var isLoading = false
    @Published var errorMessage = ""

    func fetchBattles(userId: String) async {
        await MainActor.run { self.isLoading = true }

        do {
            let result: [Battle] = try await supabase
                .from("battles")
                .select()
                .or("p1_user.eq.\(userId),p2_user.eq.\(userId)")
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value

            await MainActor.run {
                self.battles = result
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
