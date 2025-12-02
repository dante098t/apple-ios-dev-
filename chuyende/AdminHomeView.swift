import SwiftUI
import FirebaseAuth

struct AdminHomeView: View {
    @StateObject var viewModel = ProductViewModel()
    @ObservedObject var salesManager = AdminSalesManager.shared
    @State private var searchText = ""
    @State private var showingAdd = false
    @State private var editingProduct: Product?
    @State private var csvURL: URL?
    @State private var showShareSheet = false
    
    
    let categories = ["MacBook", "iPhone", "Ốp lưng", "Apple Watch", "Airpod", "Khác"]

    var filteredProducts: [Product] {
        if searchText.isEmpty {
            return viewModel.products
        } else {
            return viewModel.products.filter {
                $0.name.lowercased().contains(searchText.lowercased()) ||
                $0.description.lowercased().contains(searchText.lowercased())
            }
        }
    }

    func bestSeller(for category: String) -> Product? {
        filteredProducts.first { $0.category.lowercased() == category.lowercased() }
    }

    var body: some View {
        TabView {
            // Tab 1: Sản phẩm
            NavigationView {
                ZStack {
                    if viewModel.isLoading {
                        ProgressView("Đang tải sản phẩm...")
                            .progressViewStyle(.circular)
                    } else if let errorMessage = viewModel.errorMessage {
                        VStack {
                            Text("Lỗi: \(errorMessage)")
                                .foregroundColor(.red)
                            Button("Thử lại") {
                                viewModel.fetchProducts()
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 20) {
                                // Banner
                                Image("companyBanner")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 150)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .padding(.horizontal)
                                
                                // Dashboard
                                dashboardSection
                                
                                Divider()
                                
                                // Best Seller Section
                                
                                // Danh sách sản phẩm
                                productListSection
                            }
                            .padding(.vertical)
                        }
                    }
                }
                .navigationTitle("Sản phẩm")
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        TextField("Tìm kiếm sản phẩm...", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 200)
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { showingAdd = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingAdd) {
                    AddProductView(viewModel: viewModel) // Assuming AddProductView exists
                }
                .sheet(item: $editingProduct) { product in
                    EditProductView(viewModel: viewModel, product: product)
                }
                .onAppear {
                    viewModel.fetchProducts()
                }
            }
            .tabItem {
                Label("Sản phẩm", systemImage: "list.bullet")
            }
            
            // Tab 2: Cài đặt
            NavigationView {
                SettingsView()
            }
            .tabItem {
                Label("Cài đặt", systemImage: "gearshape")
            }
        }
    }

    // MARK: - Dashboard
    var dashboardSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Thống kê")
                .font(.title2).bold()
            
            HStack(spacing: 16) {
                dashboardCard(title: "Tổng sản phẩm", value: "\(viewModel.products.count)", color: .blue)
                dashboardCard(title: "Danh mục", value: "\(Set(viewModel.products.map { $0.category }).count)", color: .purple)
            }
            
            HStack(spacing: 16) {
                let totalSold = viewModel.products.reduce(0) { sum, product in
                    sum + salesManager.totalSales(for: product)
                }
                
                dashboardCard(title: "Tổng số lượng bán", value: "\(totalSold)", color: .orange)
                
                let revenue = salesManager.totalRevenue(products: viewModel.products)
                dashboardCard(title: "Tổng doanh thu", value: String(format: "VND%.2f", revenue), color: .green)
            }
            
            Button(action: {
                // 2a. Ghi CSV vào Documents
                if let url = AdminSalesManager.shared.exportSalesCSVToDocuments(products: viewModel.products) {
                    csvURL = url
                    
                    // 2b. Đảm bảo file đã ghi xong trước khi mở Share Sheet
                    showShareSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showShareSheet = true
                    }
                } else {
                    print("❌ Không thể xuất CSV")
                }
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Xuất CSV").bold()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            // 3️⃣ Share Sheet
            .sheet(isPresented: $showShareSheet) {
                if let url = csvURL {
                    ActivityView(activityItems: [url])
                } else {
                    Text("Không có file để share")
                }
            }
        }
        .padding(.horizontal)
    }
    // MARK: - Product List
    var productListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(" Danh sách sản phẩm")
                .font(.title2).bold()
                .padding(.horizontal)
            
            ForEach(categories, id: \.self) { category in
                let categoryProducts = filteredProducts.filter {
                    $0.category.lowercased() == category.lowercased()
                }
                
                if !categoryProducts.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(category)
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(categoryProducts) { product in
                                    AdminProductCard(product: product) { selected in
                                        editingProduct = selected   // 👈 mở EditProductView
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Card UI
    func dashboardCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(title).font(.subheadline).foregroundColor(.secondary)
            Text(value).font(.headline).bold().foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    }

