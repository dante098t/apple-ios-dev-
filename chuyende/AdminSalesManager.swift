import SwiftUI

class AdminSalesManager: ObservableObject {
    static let shared = AdminSalesManager()
    
    @Published private(set) var sales: [String: Int] = [:] // productId -> số lượng bán
    
    private init() {}
    
    func recordSale(for product: Product, quantity: Int = 1) {
        if let id = product.id {
            sales[id, default: 0] += quantity
        }
    }
    
    func totalSales(for product: Product) -> Int {
        if let id = product.id {
            return sales[id, default: 0]
        }
        return 0
    }
    
    func totalRevenue(products: [Product]) -> Double {
        products.reduce(0) { total, product in
            if let id = product.id {
                let count = sales[id, default: 0]
                return total + Double(count) * product.price
            }
            return total
            
        }
    }
    func exportSalesCSVToDocuments(products: [Product]) -> URL? {
        let fileName = "doanhthu.csv"
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
        
        var csvText = "Tên,Số lượng,Giá,Tổng\n"
        for product in products {
            let quantity = totalSales(for: product)
            let total = Double(quantity) * product.price
            csvText += "\(product.name),\(quantity),\(product.price),\(total)\n"
        }
        
        do {
            try csvText.write(to: path, atomically: true, encoding: .utf8)
            print("✅ CSV lưu thành công: \(path)")
            return path
        } catch {
            print("❌ Lỗi ghi CSV: \(error)")
            return nil
        }
    }
}

