import SwiftUI
import PhotosUI

struct EditProductView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ProductViewModel
    @State var product: Product
    @State private var newImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    // 📌 Danh mục sản phẩm
    @State private var selectedCategory = "Khác"
    let categories = ["MacBook", "iPhone", "Ốp lưng", "Apple Watch", "Airpod", "Khác"]

    // 📌 Các tuỳ chọn (ví dụ dung lượng iPhone)
    @State private var options: [String] = ["64GB/8GB RAM", "128GB/8GB RAM", "256GB", "512GB"]
    @State private var selectedOption = "64GB/8GB RAM"

    var body: some View {
        Form {
            // Tên
            TextField("Tên sản phẩm", text: $product.name)
            
            // Giá
            TextField("Giá", value: $product.price, format: .number)
            
            // Mô tả
            TextField("Mô tả", text: $product.description)
            
            // Danh mục
            Picker("Danh mục", selection: $selectedCategory) {
                ForEach(categories, id: \.self) { category in
                    Text(category)
                }
            }
            
            // Option (ví dụ dung lượng bộ nhớ)
            Picker("Tuỳ chọn", selection: $selectedOption) {
                ForEach(options, id: \.self) { option in
                    Text(option)
                }
            }
            
            // Ảnh
            PhotosPicker("Chọn ảnh mới", selection: $selectedItem, matching: .images)
            
            if let newImage {
                Image(uiImage: newImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
            } else if let urlStr = product.imageUrl,
                      let url = URL(string: urlStr) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    ProgressView()
                }
                .frame(height: 150)
            }
            
            // Nút lưu
            Button("Lưu thay đổi") {
                let imageData = newImage?.jpegData(compressionQuality: 0.8)
                
                // Cập nhật lại category + option trước khi lưu
                product.category = selectedCategory
                product.options = selectedOption
                
                viewModel.updateProduct(product: product, newImage: imageData) { success in
                    if success { dismiss() }
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            
            // Nút xóa
            Button(" Xóa sản phẩm") {
                viewModel.deleteProduct(product: product)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .onAppear {
            // Gán dữ liệu ban đầu khi mở form
            selectedCategory = product.category
            selectedOption = product.options
        }
        .onChange(of: selectedItem) { newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    newImage = uiImage
                }
            }
        }
        .navigationTitle("Sửa sản phẩm")
    }

    }
