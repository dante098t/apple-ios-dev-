import SwiftUI
import Supabase

struct ProductDetailView: View {
    var product: Product
    @EnvironmentObject var cartViewModel: CartViewModel
    @EnvironmentObject var productViewModel: ProductViewModel // Add ProductViewModel
    @State private var showAddedAlert = false
    @State private var selectedOption: String
    @State private var recommendedProducts: [Product] = []
    @State private var isLoadingRecommendations = false
    @State private var recommendationError: String?

    // Các option dựa theo category
    var options: [String] {
        switch product.category {
        case "iPhone":
            return ["64GB / 8GB RAM", "128GB / 8GB RAM", "256GB", "512GB", "1TB"]
        case "MacBook":
            return ["256GB / 8GB RAM", "512GB / 16GB RAM", "1TB / 16GB RAM", "2TB / 32GB RAM"]
        default:
            return ["Standard", "Pro", "Max"]
        }
    }

    // Khởi tạo selectedOption mặc định
    init(product: Product) {
        self.product = product
        _selectedOption = State(initialValue: {
            switch product.category {
            case "iPhone":
                return "64GB / 8GB RAM"
            case "MacBook":
                return "256GB / 8GB RAM"
            default:
                return "Standard"
            }
        }())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Ảnh sản phẩm
                if let urlStr = product.imageUrl, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView().frame(height: 200)
                        case .success(let image):
                            image.resizable()
                                .scaledToFit()
                                .frame(height: 250)
                                .cornerRadius(12)
                        case .failure(_):
                            Image(systemName: "xmark.octagon")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .foregroundColor(.red)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .foregroundColor(.gray)
                }

                // Thông tin sản phẩm
                VStack(alignment: .leading, spacing: 10) {
                    Text(product.name)
                        .font(.title)
                        .bold()
                    
                    Text("Giá: \(product.price, specifier: "%.2f") $")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Text(product.description)
                        .font(.body)
                        .padding(.top, 5)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                // Picker chọn option
                VStack(alignment: .leading, spacing: 5) {
                    Text("Chọn phiên bản:")
                        .font(.subheadline)
                    
                    Picker("Chọn thông số kỹ thuật", selection: $selectedOption) {
                        ForEach(options, id: \.self) { option in
                            Text(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .padding(.horizontal)

                // Nút thêm vào giỏ hàng
                Button(action: {
                    cartViewModel.addToCart(product: product, selectedOption: selectedOption)
                    showAddedAlert = true
                }) {
                    Text("Thêm vào giỏ hàng")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .alert("Đã thêm vào giỏ hàng!", isPresented: $showAddedAlert) {
                    Button("OK", role: .cancel) {}
                }

                // Recommendation Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Sản phẩm gợi ý")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                    
                    if isLoadingRecommendations {
                        ProgressView("Đang tải gợi ý...")
                            .padding(.horizontal)
                    } else if let error = recommendationError {
                        Text("Lỗi: \(error)")
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    } else if recommendedProducts.isEmpty {
                        Text("Không có sản phẩm gợi ý")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(recommendedProducts) { recommendedProduct in
                                    NavigationLink(destination: ProductDetailView(product: recommendedProduct)) {
                                        ProductCard(product: recommendedProduct)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("Vị trí cửa hàng")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                    
                    MapView() // ✅ Gọi file mới
                    
                    Text("2 Trường Sa, Phường 17, Bình Thạnh, Thành phố Hồ Chí Minh 70000")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                }
                .padding(.bottom, 20)
                .padding(.vertical)
            }
            .padding(.vertical)
        }
        .navigationTitle("Chi tiết sản phẩm")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await fetchRecommendations()
            }
        }
    }
    private func fetchRecommendations() async {
        isLoadingRecommendations = true
        defer { isLoadingRecommendations = false }

        do {
            // 🔹 Gọi Firestore qua ViewModel
            let recommendations = try await productViewModel.fetchRecommendedProducts(for: product)
            
            await MainActor.run {
                // 🔹 Lọc bỏ chính sản phẩm hiện tại
                self.recommendedProducts = recommendations.filter { $0.id != product.id }
                self.recommendationError = nil
            }
            
        } catch {
            await MainActor.run {
                self.recommendationError = "Không thể tải gợi ý: \(error.localizedDescription)"
            }
        }
    }
}

