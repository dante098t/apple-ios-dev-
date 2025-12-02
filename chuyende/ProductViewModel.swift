import Foundation
import FirebaseFirestore
import Supabase


class ProductViewModel: ObservableObject {
    @Published var products: [Product] = []
      @Published var isLoading: Bool = false
      @Published var errorMessage: String?
      
    private var db = Firestore.firestore()
    
    // 🔑 Supabase config
    private let client = SupabaseClient(
        supabaseURL: URL(string: "https://blunmcyxbapmsxxcfhlk.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJsdW5tY3l4YmFwbXN4eGNmaGxrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc1MTc5MjMsImV4cCI6MjA3MzA5MzkyM30.cuYIn1oDdkvKDn0KCJAOQtIycdNk8lcIBFgxvgOFNfE"
    )
    private let bucket = "product-images"
    
    init() {
        fetchProducts()
    }
    
    // MARK: - Firestore
    func fetchProducts() {
        isLoading = true
        errorMessage = nil

        db.collection("products").getDocuments { snapshot, error in
            DispatchQueue.main.async {
                self.isLoading = false   // 👈 đảm bảo tắt loading
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    print("❌ Firestore fetch error:", error.localizedDescription)
                    return
                }
                guard let docs = snapshot?.documents else {
                    self.errorMessage = "❌ No documents found"
                    print("❌ No documents found")
                    return
                }
                self.products = docs.compactMap { try? $0.data(as: Product.self) }
                print("✅ Products fetched:", self.products.count)
            }
        }
    }
    func addProduct(name: String, price: Double, description: String, imageData: Data, ownerId: String, completion: @escaping (Bool) -> Void, category: String, options: String) {
        uploadImageToSupabase(imageData: imageData) { result in
            switch result {
            case .success(let url):
                let product = Product(
                    name: name,
                    price: price,
                    description: description,
                    imageUrl: url.absoluteString,
                    ownerId: ownerId,
                    options: options,
                    category: category
                )
                do {
                    _ = try self.db.collection("products").addDocument(from: product)
                    completion(true)
                } catch {
                    print("❌ Firestore error: \(error)")
                    completion(false)
                }
            case .failure(let error):
                print("❌ Supabase upload failed: \(error)")
                completion(false)
            }
        }
    }
    
    func updateProduct(product: Product, newImage: Data?, completion: @escaping (Bool) -> Void) {
        var updatedProduct = product
        if let imageData = newImage {
            uploadImageToSupabase(imageData: imageData) { result in
                switch result {
                case .success(let url):
                    updatedProduct.imageUrl = url.absoluteString
                    self.saveProduct(updatedProduct, completion: completion)
                case .failure(let error):
                    print("❌ Supabase upload failed: \(error)")
                    completion(false)
                }
            }
        } else {
            saveProduct(updatedProduct, completion: completion)
        }
    }
    
    func deleteProduct(product: Product) {
        if let id = product.id {
            db.collection("products").document(id).delete()
        }
    }
    func fetchRecommendedProducts(for product: Product) async throws -> [Product] {
        let snapshot = try await db.collection("products").getDocuments()
        
        // Lấy toàn bộ sản phẩm từ Firestore
        var products = snapshot.documents.compactMap { doc in
            try? doc.data(as: Product.self)
        }
        
        // Loại bỏ chính sản phẩm hiện tại (tránh hiển thị lại)
        products.removeAll { $0.id == product.id }
        
        // Trộn ngẫu nhiên danh sách
        let shuffledProducts = products.shuffled()
        
        // Lấy tối đa 5 sản phẩm ngẫu nhiên
        return Array(shuffledProducts.prefix(5))
    }
    
    private func saveProduct(_ product: Product, completion: @escaping (Bool) -> Void) {
        if let id = product.id {
            do {
                try db.collection("products").document(id).setData(from: product)
                completion(true)
            } catch {
                print("❌ Firestore save failed: \(error)")
                completion(false)
            }
        }
    }
    
    // MARK: - Supabase
    private func uploadImageToSupabase(imageData: Data, completion: @escaping (Result<URL, Error>) -> Void) {
        let filename = "\(UUID().uuidString).jpg"
        Task {
            do {
                try await client.storage.from(bucket).upload(
                    path: filename,
                    file: imageData,
                    options: FileOptions(contentType: "image/jpeg", upsert: true)
                )
                let url = try client.storage.from(bucket).getPublicURL(path: filename)
                completion(.success(url))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
