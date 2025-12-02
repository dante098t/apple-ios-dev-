//
//  AdminProductCard\.swift
//  chuyende
//
//  Created by macbook on 19/9/25.
//
import SwiftUI
import Foundation

struct AdminProductCard: View {
    let product: Product
    var onEdit: (Product) -> Void
    
    var body: some View {
        VStack {
            ProductImage(url: product.imageUrl)
            Text(product.name)
                .font(.caption)
                .lineLimit(1)
            Text("\(product.price, specifier: "%.2f") VND")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(width: 150)
        .onTapGesture {
            onEdit(product)   // 👉 gọi callback mở EditProductView
        }
    }
}
