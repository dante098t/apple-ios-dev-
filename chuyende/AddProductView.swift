import SwiftUI
import PhotosUI

struct AddProductView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ProductViewModel
    @State private var name = ""
    @State private var price = ""
    @State private var description = ""
    @State private var image: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var selectedCategory = "Khác"
    let categories = ["MacBook", "iPhone", "Ốp lưng", "Apple Watch", "Airpod", "Khác"]
    @State private var options: [String] = ["64GB/8GB RAM", "128GB/8GB RAM", "256GB", "512GB"]
    @State private var selectedOption = "64GB/8GB RAM"

    var body: some View {
        NavigationView {
            Form {
                // Section for text inputs
                Section(header: Text("Thông tin sản phẩm")) {
                    ProductInputFields(name: $name, price: $price, description: $description)
                }

                // Section for category picker
                Section(header: Text("Danh mục")) {
                    Picker("Danh mục", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category)
                        }
                    }
                }

                if selectedCategory != "Ốp lưng" && selectedCategory != "Airpod" {
                    Section(header: Text("Thông số")) {
                        Picker("Thông số", selection: $selectedOption) {
                            ForEach(options, id: \.self) { option in
                                Text(option)
                            }
                        }
                    }
                }
                // Section for image picker
                Section(header: Text("Hình ảnh")) {
                    PhotosPicker("Chọn hình ảnh", selection: $selectedItem, matching: .images)
                    if let image = image {
                        ZStack(alignment: .bottomLeading) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            LinearGradient(
                                gradient: Gradient(colors: [.black.opacity(0.3), .clear]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(name.isEmpty ? "Tên sản phẩm" : name)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                Text(price.isEmpty ? "Giá" : price)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(10)
                        }
                        .frame(height: 150)
                        .shadow(radius: 3)
                        .padding(.vertical, 5)
                    }
                }
            }
            .navigationTitle("Thêm sản phẩm")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: addProduct) {
                        Text("Thêm sản phẩm")
                            .font(.headline)
                            .foregroundColor(name.isEmpty || price.isEmpty || image == nil ? .gray : .blue)
                    }
                    .disabled(name.isEmpty || price.isEmpty || image == nil)
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Lỗi"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onChange(of: selectedItem) { newItem in
                if let newItem {
                    Task {
                        do {
                            if let data = try await newItem.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                image = uiImage
                            } else {
                                alertMessage = "Không thể tải hình ảnh."
                                showAlert = true
                            }
                        } catch {
                            alertMessage = "Lỗi khi tải hình ảnh: \(error.localizedDescription)"
                            showAlert = true
                        }
                    }
                }
            }
            .onChange(of: selectedCategory) { newCategory in
                switch newCategory {
                case "iPhone":
                    options = ["64GB", "128GB", "256GB", "512GB"]
                case "MacBook":
                    options = ["8GB RAM/256GB", "16GB RAM/512GB", "32GB RAM/1TB"]
                default:
                    options = ["64GB/8GB RAM", "128GB/8GB RAM", "256GB", "512GB"]
                }
                selectedOption = options.first ?? "64GB/8GB RAM"
            }
            .onChange(of: price) { newPrice in
                if !newPrice.isEmpty, Double(newPrice) == nil {
                    alertMessage = "Giá phải là số hợp lệ."
                    showAlert = true
                }
            }
        }
    }

    // Function to handle product addition
    private func addProduct() {
        if name.isEmpty || price.isEmpty || image == nil {
            alertMessage = "Vui lòng điền đầy đủ thông tin và chọn hình ảnh."
            showAlert = true
        } else if let uiImage = image,
                  let data = uiImage.jpegData(compressionQuality: 0.8),
                  let priceVal = Double(price) {
            viewModel.addProduct(
                name: name,
                price: priceVal,
                description: description,
                imageData: data,
                ownerId: "admin",
                completion: { success in
                    if success {
                        name = ""
                        price = ""
                        description = ""
                        image = nil
                        selectedItem = nil
                        selectedCategory = "Khác"
                        selectedOption = options.first ?? "64GB/8GB RAM"
                        dismiss()
                    }
                },
                category: selectedCategory,
                options: selectedOption // Fixed parameter name
            )
        } else {
            alertMessage = "Giá không hợp lệ hoặc có lỗi với hình ảnh."
            showAlert = true
        }
    }
}

// Reusable view for input fields
struct ProductInputFields: View {
    @Binding var name: String
    @Binding var price: String
    @Binding var description: String

    var body: some View {
        TextField("Tên sản phẩm", text: $name)
        TextField("Giá", text: $price)
            .keyboardType(.decimalPad)
        TextField("Mô tả", text: $description)
    }
}
