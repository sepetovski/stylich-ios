import Foundation
import Combine
import Supabase

class BattlesHistoryService: ObservableObject {
    @Published var battles: [Battle] = []
    @Published var isLoading = false
    @Published var errorMessage = ""

    func fetchBattles(userId: String) async {
        await MainActor.run { self.isLoading = true }

        let lowerId = userId.lowercased()

        do {
            let response = try await supabase
                .from("battles")
                .select()
                .or("p1_user.eq.\(lowerId),p2_user.eq.\(lowerId)")
                .order("created_at", ascending: false)
                .limit(50)
                .execute()

            if let raw = String(data: response.data, encoding: .utf8) {
                print("🔍 Battles raw: \(raw)")
            }

            var result = try JSONDecoder().decode([Battle].self, from: response.data)

            let userIds = Set(result.flatMap { battle -> [String] in
                var ids: [String] = []
                if battle.p1User.lowercased() != lowerId { ids.append(battle.p1User) }
                if let p2 = battle.p2User, p2.lowercased() != lowerId { ids.append(p2) }
                return ids
            })

            if !userIds.isEmpty {
                let profilesResponse = try await supabase
                    .from("profiles")
                    .select("id, username")
                    .in("id", values: Array(userIds))
                    .execute()

                if let raw = String(data: profilesResponse.data, encoding: .utf8) {
                    print("🔍 Profiles raw: \(raw)")
                }

                let profiles = try JSONDecoder().decode([ProfileLookup].self, from: profilesResponse.data)
                let profileMap = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id.lowercased(), $0.username) })

                result = result.map { battle in
                    var b = battle
                    let opponentId = battle.p1User.lowercased() == lowerId ? battle.p2User : battle.p1User
                    b.opponentUsername = opponentId.flatMap { profileMap[$0.lowercased()] } ?? "Opponent"
                    return b
                }
            }

            await MainActor.run {
                self.battles = result
                self.isLoading = false
            }
        } catch {
            print("❌ Battles fetch error: \(error)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

struct ProfileLookup: Codable {
    let id: String
    let username: String
}
