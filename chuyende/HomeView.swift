import SwiftUI
import Supabase
import FirebaseAuth
struct BestSellerCard: View {
    let category: String
    let product: Product
    @EnvironmentObject var cartViewModel: CartViewModel
    
    var body: some View {
        NavigationLink(destination: ProductDetailView(product: product)
            .environmentObject(cartViewModel)) {
            VStack {
                ProductImage(url: product.imageUrl)
                Text(category)
                    .font(.caption).bold()
                Text(product.name)
                    .font(.caption)
                    .lineLimit(1)
            }
            .frame(width: 150)
        }
    }
}

struct ProductCard: View {
    let product: Product
    @EnvironmentObject var cartViewModel: CartViewModel
    
    var body: some View {
        NavigationLink(destination: ProductDetailView(product: product)
            .environmentObject(cartViewModel)) {
            VStack {
                ProductImage(url: product.imageUrl)
                Text(product.name)
                    .font(.caption)
                    .lineLimit(1)
                Text("\(product.price, specifier: "%.0f") VND")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(width: 150)
        }
    }
}

struct ProductImage: View {
    let url: String?
    
    var body: some View {
        if let urlStr = url, let url = URL(string: urlStr) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .empty:
                    ProgressView()
                case .failure:
                    Image(systemName: "photo").resizable().scaledToFit()
                        .foregroundColor(.gray)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 150, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 100)
                .foregroundColor(.gray)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
// MARK: - SearchBar
struct SearchBar: UIViewControllerRepresentable {
    @Binding var text: String
    
    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String
        init(text: Binding<String>) { _text = text }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.delegate = context.coordinator
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Tìm kiếm sản phẩm..."
        
        let viewController = UIViewController()
        viewController.view = UIView()
        viewController.navigationItem.searchController = searchController
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}



struct HomeView: View {
    @StateObject var productViewModel = ProductViewModel()
    @StateObject var cartViewModel = CartViewModel()
    @State private var searchText = ""
    
    // Danh mục sản phẩm
    let categories = ["MacBook", "iPhone", "Ốp lưng", "Apple Watch", "Airpod", "Khác"]
    
    // Lọc sản phẩm theo tìm kiếm
    var filteredProducts: [Product] {
        if searchText.isEmpty {
            return productViewModel.products
        } else {
            return productViewModel.products.filter {
                $0.name.lowercased().contains(searchText.lowercased()) ||
                $0.description.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    // Lấy sản phẩm best-seller (giả lập: sản phẩm đầu tiên trong danh mục)
    func bestSeller(for category: String) -> Product? {
        return filteredProducts.first { $0.category.lowercased() == category.lowercased() }
    }
    
    var body: some View {
        TabView {
            // Tab 1: Sản phẩm
            NavigationView {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        
                        // Banner
                        Image("companyBanner")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                        
                        // Thanh tìm kiếm
                        SearchBar(text: $searchText)
                            .padding(.horizontal)
                        
                        // Best seller section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Sản phẩm bán chạy")
                                .font(.title2)
                                .bold()
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(categories, id: \.self) { category in
                                        if let bestSeller = bestSeller(for: category) {
                                            BestSellerCard(category: category, product: bestSeller)
                                                .environmentObject(cartViewModel)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Danh sách sản phẩm theo danh mục
                        ForEach(categories, id: \.self) { category in
                            let categoryProducts = filteredProducts.filter { $0.category.lowercased() == category.lowercased() }
                            if !categoryProducts.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(category)
                                        .font(.title2)
                                        .bold()
                                        .padding(.horizontal)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 10) {
                                            ForEach(categoryProducts) { product in
                                                ProductCard(product: product)
                                                    .environmentObject(cartViewModel)
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical)
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
                }
                .navigationTitle("appléstore")
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        // Custom Search Bar in Toolbar
                        TextField("Tìm kiếm sản phẩm...", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 200)
                            .padding(.vertical, 4)
                    }
                
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination: CartView().environmentObject(cartViewModel)) {
                            ZStack {
                                Image(systemName: "cart")
                                if !cartViewModel.items.isEmpty {
                                    Text("\(cartViewModel.items.count)")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                        .padding(6)
                                        .background(Color.red)
                                        .clipShape(Circle())
                                        .offset(x: 8, y: -8)
                                }
                            }
                        }
                    }
                }
                .onAppear {
                    if productViewModel.products.isEmpty {
                        productViewModel.fetchProducts()
                    }
                }
            }
            .tabItem {
                Label("Sản phẩm", systemImage: "list.bullet")
            }
            
            // Tab 2: Tin tức
            NewsView()
                .tabItem {
                    Label("Tin tức", systemImage: "newspaper")
                }
            
            // Tab 3: Cài đặt
            NavigationView {
                SettingsView()
            }
            .tabItem {
                Label("Cài đặt", systemImage: "gearshape")
            }
        }
        .environmentObject(cartViewModel)
    }
}
