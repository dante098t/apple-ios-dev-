import Foundation
import Supabase
class SupabaseService {
    static let shared = SupabaseService()
    
    private let client: SupabaseClient
    
    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://blunmcyxbapmsxxcfhlk.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJsdW5tY3l4YmFwbXN4eGNmaGxrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc1MTc5MjMsImV4cCI6MjA3MzA5MzkyM30.cuYIn1oDdkvKDn0KCJAOQtIycdNk8lcIBFgxvgOFNfE"
            
        )
    }
    
    func uploadImage(imageData: Data, fileName: String, bucket: String = "product-images", completion: @escaping (Result<String, Error>) -> Void) {
        let path = "products/\(fileName)"
        
        Task {
            do {
                try await client.storage
                    .from(bucket)
                    .upload(
                        path,
                        data: imageData,
                        options: FileOptions(contentType: "image/jpeg", upsert: true)
                    )
                
                let publicURL = try client.storage
                    .from(bucket)
                    .getPublicURL(path: path)
                
                completion(.success(publicURL.absoluteString))
            } catch {
                completion(.failure(error))
            }
        }
    }
    func uploadNewsImage(imageData: Data, fileName: String, bucket: String = "news-images", completion: @escaping (Result<String, Error>) -> Void) {
        let path = "news/\(fileName)"
        
        Task {
            do {
                try await client.storage
                    .from(bucket)
                    .upload(
                        path,
                        data: imageData,
                        options: FileOptions(contentType: "image/jpeg", upsert: true)
                    )
                
                let publicURL = try client.storage
                    .from(bucket)
                    .getPublicURL(path: path)
                
                completion(.success(publicURL.absoluteString))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Fetch news
    func fetchNews(completion: @escaping (Result<[News], Error>) -> Void) {
        Task {
            do {
                let response = try await client
                    .from("news")
                    .select()
                    .order("date", ascending: false)
                    .execute()
                
                let decoder = JSONDecoder()
                
                // 🔑 Custom strategy: ISO8601 + fractional seconds
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateStr = try container.decode(String.self)
                    if let date = formatter.date(from: dateStr) {
                        return date
                    }
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(dateStr)")
                }
                
                let news = try decoder.decode([News].self, from: response.data)
                completion(.success(news))
            } catch {
                print("❌ Fetch error: \(error)")
                completion(.failure(error))
            }
        }
    }
}
