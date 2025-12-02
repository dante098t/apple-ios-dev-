import Foundation

struct CartItem: Identifiable {
    let id = UUID()
    let product: Product
    let selectedOption: String
    var quantity: Int
}
