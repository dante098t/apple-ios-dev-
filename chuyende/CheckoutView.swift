import SwiftUI

struct CheckoutView: View {
    @EnvironmentObject var cartVM: CartViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var showSuccess = false
    @State private var selectedMethod: String? = nil
    @State private var voucherCode = ""
    @State private var studentID = ""
    
    // Trả góp
    @State private var selectedInstallmentIndex = 0
    let installmentOptions = [3, 6, 12]       // số tháng
    let interestRates = [0.02, 0.03, 0.05]   // lãi suất/tháng tương ứng
    
    // Danh sách phương thức thanh toán
    let paymentMethods = [
        "Chuyển khoản",
        "Trả góp",
        "Apple Pay"
    ]
    
    // Giảm giá
    var discountFromVoucher: Double {
        switch voucherCode.lowercased() {
        case "giam10": return cartVM.totalPrice * 0.10
        case "sale50": return cartVM.totalPrice * 0.50
        default: return 0
        }
    }
    
    var discountFromStudent: Double {
        if studentID.hasPrefix("SV") || studentID.hasPrefix("VNEDU") {
            return cartVM.totalPrice * 0.05
        }
        return 0
    }
    
    var finalPrice: Double {
        max(cartVM.totalPrice - discountFromVoucher - discountFromStudent, 0)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("Xác nhận thanh toán")
                    .font(.title2)
                    .bold()
                
                // Danh sách sản phẩm
                List {
                    ForEach(cartVM.items) { item in
                        HStack {
                            Text("\(item.product.name) - \(item.selectedOption)")
                            Spacer()
                            Text("x\(item.quantity)")
                        }
                    }
                }
                .frame(height: CGFloat(cartVM.items.count * 44))
                
                // Voucher
                VStack(alignment: .leading) {
                    Text("Mã Voucher:")
                    TextField("GIAM10, SALE50...", text: $voucherCode)
                        .textFieldStyle(.roundedBorder)
                }.padding(.horizontal)
                
                // Mã sinh viên
                VStack(alignment: .leading) {
                    Text("Mã sinh viên / VNEDU:")
                    TextField("Nhập mã...", text: $studentID)
                        .textFieldStyle(.roundedBorder)
                }.padding(.horizontal)
                
                // Chọn phương thức thanh toán
                Text("Chọn hình thức thanh toán")
                    .font(.headline)
                
                HStack(spacing: 15) {
                    ForEach(paymentMethods, id: \.self) { method in
                        VStack {
                            Image("thanhtoan")  // Dùng chung hình
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedMethod == method ? .green : .clear, lineWidth: 3)
                                )
                                .onTapGesture {
                                    selectedMethod = method
                                }
                            
                            Text(method)
                                .font(.footnote)
                                .bold(selectedMethod == method)
                                .foregroundColor(selectedMethod == method ? .green : .primary)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Nếu là trả góp
                if selectedMethod == "Trả góp" {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Trả góp")
                            .font(.headline)
                        
                        Picker("Thời gian trả góp", selection: $selectedInstallmentIndex) {
                            ForEach(0..<installmentOptions.count, id: \.self) { index in
                                Text("\(installmentOptions[index]) tháng").tag(index)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        let months = installmentOptions[selectedInstallmentIndex]
                        let rate = interestRates[selectedInstallmentIndex]
                        let totalWithInterest = finalPrice * pow(1 + rate, Double(months))
                        let monthlyPayment = totalWithInterest / Double(months)
                        
                        Text("Lãi suất: \(Int(rate * 100))% / tháng")
                        Text("Tổng phải trả: $\(totalWithInterest, specifier: "%.2f")")
                        Text("Mỗi tháng: $\(monthlyPayment, specifier: "%.2f")")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                // Hiển thị giá
                VStack {
                    Text("Tổng: $\(cartVM.totalPrice, specifier: "%.2f")")
                    
                    if discountFromVoucher > 0 {
                        Text("Giảm voucher: -$\(discountFromVoucher, specifier: "%.2f")")
                            .foregroundColor(.green)
                    }
                    if discountFromStudent > 0 {
                        Text("Giảm SV/VNEDU: -$\(discountFromStudent, specifier: "%.2f")")
                            .foregroundColor(.green)
                    }
                    
                    if selectedMethod != "Trả góp" {
                        Text("Thành tiền: $\(finalPrice, specifier: "%.2f")")
                            .bold()
                            .font(.title3)
                    }
                }
                
                // Nút thanh toán
                Button("Xác nhận thanh toán") {
                    if let method = selectedMethod {
                        for item in cartVM.items {
                            AdminSalesManager.shared.recordSale(for: item.product, quantity: item.quantity)
                        }
                        cartVM.clearCart()
                        showSuccess = true
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedMethod == nil ? Color.gray : Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal)
                .disabled(selectedMethod == nil)
                
                Spacer()
            }
        }
        .alert("Thanh toán bằng \(selectedMethod ?? "") thành công!", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        }
    }
}
