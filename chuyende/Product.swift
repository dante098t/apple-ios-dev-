import Foundation
import FirebaseFirestore

struct Product: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var price: Double
    var description: String
    var imageUrl: String?
    var ownerId: String
    var options: String
    var category: String
}
 
