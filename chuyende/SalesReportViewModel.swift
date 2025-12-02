import FirebaseFirestore

class SalesReportViewModel: ObservableObject {
    @Published var sales: [Sale] = []
    @Published var products: [Product] = []

    private let db = Firestore.firestore()

    func fetchProducts(completion: @escaping () -> Void = {}) {
        db.collection("products").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, error == nil else { completion(); return }
            self.products = documents.compactMap { try? $0.data(as: Product.self) }
            completion()
        }
    }

    func fetchSales(completion: @escaping () -> Void = {}) {
        db.collection("sales").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, error == nil else { completion(); return }
            self.sales = documents.compactMap { try? $0.data(as: Sale.self) }
            completion()
        }
    }
}
