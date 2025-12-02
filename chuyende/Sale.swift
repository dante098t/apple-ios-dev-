import Foundation
import FirebaseFirestore

struct Sale: Identifiable, Codable {
    @DocumentID var id: String?
    var productId: String
    var quantity: Int
    var price: Double   // giá bán lúc bán
    var date: Date
    var ownerId: String
}
