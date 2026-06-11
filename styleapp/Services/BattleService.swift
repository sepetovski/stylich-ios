import Foundation
import SwiftUI
import Combine
import Supabase
import UIKit

class BattleService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var battleResult: BattleResult? = nil

    // Your Cloudflare Worker URL
    let workerURL = "https://stylich-api.sepetovskidamjan.workers.dev"

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
    
    func submitFit(image: UIImage, category: String) async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = ""
        }

        do {
            // 1. Upload image to Supabase Storage
            // Resize image first
            let resized = resizeImage(image: image, maxSize: 800)
            
            guard let imageData = resized.jpegData(compressionQuality: 0.5) else {
                throw NSError(domain: "Stylich", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to process image"])
            }

            let fileName = "\(UUID().uuidString).jpg"
            let filePath = "\(fileName)"

            try await supabase.storage
                .from("outfits")
                .upload(filePath, data: imageData, options: FileOptions(contentType: "image/jpeg"))

            let publicURL = try supabase.storage
                .from("outfits")
                .getPublicURL(path: filePath)

            // 2. Get the user's auth token
            let session = try await supabase.auth.session
            let token = session.accessToken

            // 3. Call our Cloudflare Worker
            guard let url = URL(string: "\(workerURL)/submit-fit") else {
                throw NSError(domain: "Stylich", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            }
            print("Calling URL: \(url.absoluteString)")

            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            urlRequest.httpBody = try JSONEncoder().encode([
                "imageUrl": publicURL.absoluteString,
                "category": category
            ])

            let (data, _) = try await URLSession.shared.data(for: urlRequest)

            if let rawString = String(data: data, encoding: .utf8) {
                print("Worker response: \(rawString)")
            }

            // Handle error responses
            if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
               let errorMsg = errorResponse["error"] {
                throw NSError(domain: "Stylich", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMsg])
            }
            let result = try JSONDecoder().decode(BattleResponse.self, from: data)

            await MainActor.run {
                let status = result.status ?? "waiting"
                let score = result.score ?? 0

                self.battleResult = BattleResult(
                    status: status,
                    battleId: result.battleId ?? "",
                    score: result.score,
                    feedback: result.feedback ?? result.message,
                    opponentScore: result.opponentScore,
                    opponentFeedback: result.opponentFeedback,
                    isWinner: result.isWinner
                )
                self.isLoading = false

                // Show notification
                switch status {
                case "judged":
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
                case "queued":
                    NotificationManager.shared.show(
                        title: "You're in the queue ⏳",
                        message: "AI is busy — we'll judge your fit shortly!",
                        icon: "clock.fill",
                        color: .orange
                    )
                default:
                    break
                }
            }

        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }

    }
}

// What the worker sends back
struct BattleResponse: Codable {
    let status: String?
    let battleId: String?
    let score: Int?
    let feedback: String?
    let message: String?
    let opponentScore: Int?
    let opponentFeedback: String?
    let isWinner: Bool?
}

struct BattleResult {
    let status: String
    let battleId: String
    let score: Int?
    let feedback: String?
    let opponentScore: Int?
    let opponentFeedback: String?
    let isWinner: Bool?
}
