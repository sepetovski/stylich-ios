import Foundation
import Combine
import Supabase

class ProfileService: ObservableObject {
    @Published var profile: Profile? = nil
    @Published var isLoading = false
    @Published var errorMessage = ""

    func fetchProfile(userId: String) async {
        await MainActor.run { self.isLoading = true }

        do {
            let result: Profile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value

            await MainActor.run {
                self.profile = result
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
