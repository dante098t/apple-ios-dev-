import SwiftUI

struct CartView: View {
    @EnvironmentObject var cartVM: CartViewModel
    @State private var showCheckout = false
    
    var body: some View {
        VStack {
            if cartVM.items.isEmpty {
                Text(" Giỏ hàng trống")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List {
                    ForEach(cartVM.items) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.product.name)
                                    .font(.headline)
                                Text("Phiên bản: \(item.selectedOption)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("Số lượng: \(item.quantity)")
                                    .font(.subheadline)
                            }
                            Spacer()
                            Text("$\(item.product.price * Double(item.quantity), specifier: "%.2f")")
                                .bold()
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            cartVM.removeFromCart(item: cartVM.items[index])
                        }
                    }
                }
                
                VStack(spacing: 15) {
                    Text("Tổng: $\(cartVM.totalPrice, specifier: "%.2f")")
                        .font(.title2)
                        .bold()
                    
                    Button("Thanh toán") {
                        showCheckout = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding()
            }
        }
        .navigationTitle("Giỏ hàng")
        .sheet(isPresented: $showCheckout) {
            CheckoutView()
                .environmentObject(cartVM)
        }
    }
}
