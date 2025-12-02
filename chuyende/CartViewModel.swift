import SwiftUI

class CartViewModel: ObservableObject {
    @Published var items: [CartItem] = []
    

    func addToCart(product: Product, selectedOption: String) {
        if let index = items.firstIndex(where: {
            $0.product.id == product.id && $0.selectedOption == selectedOption
        }) {
            items[index].quantity += 1
        } else {
            let newItem = CartItem(product: product, selectedOption: selectedOption, quantity: 1)
            items.append(newItem)
        }
    }
    // Xóa sản phẩm khỏi giỏ
    func removeFromCart(item: CartItem) {
        items.removeAll { $0.id == item.id }
    }
    
    // Tính tổng tiền
    var totalPrice: Double {
        items.reduce(0) { $0 + ($1.product.price * Double($1.quantity)) }
    }
    
    // Xóa toàn bộ giỏ hàng
    func clearCart() {
        items.removeAll()
    }
}
