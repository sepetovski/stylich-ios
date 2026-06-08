import Foundation
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
                self.battleResult = BattleResult(
                    status: result.status ?? "waiting",
                    battleId: result.battleId ?? "",
                    score: result.score,
                    feedback: result.feedback ?? result.message,
                    opponentScore: result.opponentScore,
                    opponentFeedback: result.opponentFeedback,
                    isWinner: result.isWinner
                )
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
