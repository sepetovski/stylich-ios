import SwiftUI
import Combine
import Supabase
import Storage

class BattleManager: ObservableObject {
    @Published var isUploading = false
    @Published var progress: Double = 0.0
    @Published var statusMessage = ""
    @Published var selectedTab = 0
    @Published var battleResult: BattleResult? = nil
    @Published var pendingBattleId: String? = nil

    let workerURL = "https://stylich-api.sepetovskidamjan.workers.dev"
    private var pollTask: Task<Void, Never>? = nil

    func submitFit(image: UIImage, category: String) async {
        await MainActor.run {
            self.isUploading = true
            self.progress = 0.0
            self.statusMessage = "Uploading your fit..."
            self.selectedTab = 0 // switch to Feed
        }

        do {
            // Step 1 — resize
            let resized = resizeImage(image: image, maxSize: 800)
            guard let imageData = resized.jpegData(compressionQuality: 0.5) else {
                throw NSError(domain: "Stylich", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to process image"])
            }

            await MainActor.run { self.progress = 0.2 }

            // Step 2 — upload to Supabase Storage
            let fileName = "\(UUID().uuidString).jpg"
            try await supabase.storage
                .from("outfits")
                .upload(fileName, data: imageData, options: FileOptions(contentType: "image/jpeg"))

            let publicURL = try supabase.storage
                .from("outfits")
                .getPublicURL(path: fileName)

            await MainActor.run {
                self.progress = 0.5
                self.statusMessage = "Judging your fit..."
            }

            // Step 3 — call worker
            let session = try await supabase.auth.session
            let token = session.accessToken

            guard let url = URL(string: "\(workerURL)/submit-fit") else { return }
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            urlRequest.httpBody = try JSONEncoder().encode([
                "imageUrl": publicURL.absoluteString,
                "category": category
            ])

            await MainActor.run { self.progress = 0.75 }

            let (data, _) = try await URLSession.shared.data(for: urlRequest)
            let result = try JSONDecoder().decode(BattleResponse.self, from: data)

            await MainActor.run {
                self.progress = 1.0
                self.statusMessage = ""
            }

            // Small delay so progress bar hits 100% visibly
            try await Task.sleep(nanoseconds: 400_000_000)

            await MainActor.run {
                self.isUploading = false
                self.progress = 0.0
            }

            let status = result.status ?? "waiting"
            let score = result.score ?? 0

            // Handle result
            switch status {
            case "judged":
                await MainActor.run {
                    self.battleResult = BattleResult(
                        status: status,
                        battleId: result.battleId ?? "",
                        score: result.score,
                        feedback: result.feedback,
                        opponentScore: result.opponentScore,
                        opponentFeedback: result.opponentFeedback,
                        isWinner: result.isWinner
                    )
                }
                if result.isWinner == true {
                    NotificationManager.shared.show(
                        title: "You won! 👑",
                        message: "Your fit scored \(score) and crushed the opponent!",
                        icon: "crown.fill",
                        color: .green
                    )
                } else if result.isWinner == false {
                    NotificationManager.shared.show(
                        title: "Battle lost",
                        message: "Your fit scored \(score) — keep grinding!",
                        icon: "bolt.fill",
                        color: .red
                    )
                } else {
                    NotificationManager.shared.show(
                        title: "It's a draw!",
                        message: "Both fits scored \(score) — too close to call!",
                        icon: "equal.circle.fill",
                        color: Color("AccentColor")
                    )
                }

            case "waiting":
                NotificationManager.shared.show(
                    title: "Fit dropped! 🔥",
                    message: "Scored \(score) — waiting for an opponent...",
                    icon: "hourglass.fill",
                    color: Color("AccentColor")
                )
                // Start polling for opponent
                if let battleId = result.battleId {
                    startPolling(battleId: battleId, token: token)
                }

            case "queued":
                NotificationManager.shared.show(
                    title: "You're in the queue ⏳",
                    message: "AI is busy — we'll judge your fit shortly!",
                    icon: "clock.fill",
                    color: .orange
                )
                // Poll queue until processed then poll battle
                if let battleId = result.battleId {
                    startPolling(battleId: battleId, token: token)
                }

            default:
                break
            }

        } catch {
            await MainActor.run {
                self.isUploading = false
                self.progress = 0.0
                self.statusMessage = ""
            }
            NotificationManager.shared.show(
                title: "Something went wrong",
                message: error.localizedDescription,
                icon: "exclamationmark.circle.fill",
                color: .red
            )
        }
    }

    // MARK: - Polling

    func startPolling(battleId: String, token: String) {
        pollTask?.cancel()
        pollTask = Task {
            var attempts = 0
            let maxAttempts = 40 // poll for up to ~3 mins

            while attempts < maxAttempts {
                try? await Task.sleep(nanoseconds: 5_000_000_000) // every 5 seconds

                if Task.isCancelled { return }

                guard let url = URL(string: "\(workerURL)/get-battle?battleId=\(battleId)") else { return }
                var urlRequest = URLRequest(url: url)
                urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

                guard let (data, _) = try? await URLSession.shared.data(for: urlRequest) else {
                    attempts += 1
                    continue
                }

                guard let result = try? JSONDecoder().decode(BattleResponse.self, from: data) else {
                    attempts += 1
                    continue
                }

                if result.status == "judged" {
                    let score = result.score ?? 0
                    await MainActor.run {
                        self.battleResult = BattleResult(
                            status: "judged",
                            battleId: battleId,
                            score: result.score,
                            feedback: result.feedback,
                            opponentScore: result.opponentScore,
                            opponentFeedback: result.opponentFeedback,
                            isWinner: result.isWinner
                        )
                    }

                    if result.isWinner == true {
                        NotificationManager.shared.show(
                            title: "You won! 👑",
                            message: "Your fit scored \(score) and crushed the opponent!",
                            icon: "crown.fill",
                            color: .green
                        )
                    } else if result.isWinner == false {
                        NotificationManager.shared.show(
                            title: "Battle lost",
                            message: "Your fit scored \(score) — keep grinding!",
                            icon: "bolt.fill",
                            color: .red
                        )
                    } else {
                        NotificationManager.shared.show(
                            title: "It's a draw!",
                            message: "Both fits scored \(score) — too close to call!",
                            icon: "equal.circle.fill",
                            color: Color("AccentColor")
                        )
                    }

                    pollTask?.cancel()
                    return
                }

                attempts += 1
            }
        }
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    // MARK: - Helpers

    func resizeImage(image: UIImage, maxSize: CGFloat) -> UIImage {
        let ratio = min(maxSize / image.size.width, maxSize / image.size.height)
        if ratio >= 1 { return image }
        let newSize = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        return resized
    }
}
