import Foundation
import UIKit

/// Handles communication with the dart detection server
final class NetworkService {
    private let serverURL: URL

    init(serverURL: URL = URL(string: "http://192.168.178.119:5000/upload")!) {
        self.serverURL = serverURL
    }

    /// Uploads an image with optional keypoints to the server and returns the decoded response
    func uploadImage(_ image: UIImage, keypoints: BoardKeypoints?) async throws -> ServerResponse {
        guard let jpegData = image.jpegData(compressionQuality: 1.0) else {
            throw NetworkError.imageConversionFailed
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        var body = Data()

        // Keypoints field
        if let kp = keypoints {
            let kpDict = kp.toDictionary()
            if let kpData = try? JSONSerialization.data(withJSONObject: kpDict),
               let kpString = String(data: kpData, encoding: .utf8) {
                body.appendMultipart(name: "keypoints", value: kpString, boundary: boundary)
            }
        } else {
            body.appendMultipart(name: "keypoints", value: "{}", boundary: boundary)
        }

        // Image field
        body.appendMultipartFile(name: "file", filename: "dart.jpg",
                                 mimeType: "image/jpeg", data: jpegData, boundary: boundary)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        print("📤 Sende \(jpegData.count / 1024) KB an Server...")
        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            print("📥 Server Status: \(httpResponse.statusCode)")
            guard (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.serverError(httpResponse.statusCode)
            }
        }

        let decoded: ServerResponse
        do {
            decoded = try JSONDecoder().decode(ServerResponse.self, from: data)
        } catch {
            let raw = String(data: data, encoding: .utf8) ?? "nicht lesbar"
            print("⚠️ JSON-Decode-Fehler: \(error)")
            print("📄 Rohdaten: \(raw.prefix(500))")
            throw error
        }
        return decoded
    }
}

// MARK: - Errors

enum NetworkError: LocalizedError {
    case imageConversionFailed
    case serverError(Int)
    case noData

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed: return "JPEG-Konvertierung fehlgeschlagen"
        case .serverError(let code): return "Server-Fehler: \(code)"
        case .noData: return "Keine Daten vom Server erhalten"
        }
    }
}

// MARK: - Data Helpers

private extension Data {
    mutating func appendMultipart(name: String, value: String, boundary: String) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        append(value.data(using: .utf8)!)
        append("\r\n".data(using: .utf8)!)
    }

    mutating func appendMultipartFile(name: String, filename: String,
                                       mimeType: String, data: Data, boundary: String) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        append(data)
        append("\r\n".data(using: .utf8)!)
    }
}
